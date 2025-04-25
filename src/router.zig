const std = @import("std");

const HTTPMethod = enum(u16) {
    GET = 0x001,
    POST = 0x002,
    HEAD = 0x004,
    PUT = 0x008,
    DELETE = 0x010,
    CONNECT = 0x020,
    OPTIONS = 0x040,
    TRACE = 0x080,
    PATCH = 0x100,
};

const MethodContainer = struct {
    method: HTTPMethod,
    callback: ?*fn () void,
};

const Handler = struct {
    path: []const u8,
    methods: [@typeInfo(HTTPMethod).@"enum".fields.len]MethodContainer,

    // Generate @ compile time or realtime a MethodContainer with an optional custom callback on one opt
    pub fn ContainerGen(modification: ?HTTPMethod, callback: ?*fn () void) [@typeInfo(HTTPMethod).@"enum".fields.len]MethodContainer {
        var container: [@typeInfo(HTTPMethod).@"enum".fields.len]MethodContainer = undefined;
        if (modification == null) {
            inline for (std.meta.fields(HTTPMethod), 0..) |value, i| {
                container[i] = MethodContainer{ .method = @enumFromInt(value.value), .callback = null };
            }
            return container;
        } else {
            const targetIdx = @ctz(@intFromEnum(modification.?));
            inline for (std.meta.fields(HTTPMethod), 0..) |value, i| {
                if (i == targetIdx) {
                    container[i] = MethodContainer{ .method = @enumFromInt(value.value), .callback = callback };
                } else {
                    container[i] = MethodContainer{ .method = @enumFromInt(value.value), .callback = null };
                }
            }
            return container;
        }
    }
};

pub fn Router() type {
    return struct {
        const Self = @This();

        _arena: std.heap.ArenaAllocator,
        _arenaAllocator: std.mem.Allocator,

        _apiEndpoints: std.ArrayList(Handler),
        _pages: std.ArrayList(Handler),

        // Allocator is expected to be a page allocator
        pub fn init(allocator: std.mem.Allocator) Self {
            var arena = std.heap.ArenaAllocator.init(allocator);

            return .{
                ._arena = arena,
                ._arenaAllocator = arena.allocator(),
                ._apiEndpoints = std.ArrayList(Handler).init(allocator),
                ._pages = std.ArrayList(Handler).init(allocator),
            };
        }

        // Use to properly discard of allocated resources
        pub fn deinit(self: Self) void {
            self._arena.deinit();
        }

        fn appendHandler(target: *std.ArrayList(Handler), method: HTTPMethod, comptime path: []const u8, callback: fn () void) !void {
            // First check for already existing entry and update that
            for (target.items, 0..) |item, i| {
                if (std.mem.eql(u8, path, item.path)) {
                    target.items[i].methods[@ctz(@intFromEnum(method))].callback = @constCast(&callback);
                    return;
                }
            }

            // If not, create new entry
            target.append(.{
                .path = path,
                .methods = Handler.ContainerGen(method, @constCast(&callback)),
            }) catch return error.EndpointAppend;
            return;
        }

        // Intended for static content served to the client, overrides the default hander attached to content
        pub fn attachToPage(self: *Self, method: HTTPMethod, comptime path: []const u8, callback: fn () void) void {
            return appendHandler(&self._pages, method, path, callback);
        }

        // Intended for API endpoints, the path will be prepended with /api/
        // Example URL: http://localhost:8080/api/foo_bar
        pub fn addEndpoint(self: *Self, method: HTTPMethod, comptime path: []const u8, callback: fn () void) !void {
            return appendHandler(&self._apiEndpoints, method, path, callback);
        }

        pub fn composeTree(self: *Self) void {

            // Free out all the ArrayList entries because it has no use now
            self._apiEndpoints.deinit();
            self._pages.deinit();

            return;
        }
    };
}

fn tmp() void {
    std.debug.print("Hello callback!\n", .{});
}

test "Full Router Test" {
    var router = Router().init(std.heap.page_allocator);
    try router.addEndpoint(HTTPMethod.GET, "/", tmp);
    try router.addEndpoint(HTTPMethod.POST, "/", tmp);

    try router.attachToPage(HTTPMethod.GET, "/", tmp);

    router.composeTree();
}
