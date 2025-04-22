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

    // Put all the methods into one datatype represented by one bit
    // Implemented in case there's ever a future need for multiple methods on one handler
    pub fn join(opts: anytype) u16 {
        var output: u16 = 0;
        inline for (opts) |value| {
            output |= @intFromEnum(value);
        }
        return output;
    }
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

        //_pageEndpoints: std.ArrayList(Handler),
        _apiEndpoints: std.ArrayList(Handler),

        // Allocator is expected to be a page allocator
        pub fn init(allocator: std.mem.Allocator) Self {
            var arena = std.heap.ArenaAllocator.init(allocator);
            //var list = std.ArrayList(Handler).init(allocator);

            return .{
                ._arena = arena,
                ._arenaAllocator = arena.allocator(),
                ._apiEndpoints = std.ArrayList(Handler).init(allocator),
            };
        }

        // Use to properly discard of allocated resources
        pub fn deinit(self: Self) void {
            self._arena.deinit();
        }

        // Intended for static content served to the client, overrides the default hander attached to content
        pub fn attachHandler(_: Self, method: HTTPMethod, comptime path: []const u8, callback: fn () void) void {
            _ = method;
            _ = path;
            _ = callback;
            return;
        }

        // Intended for API endpoints, the path will be prepended with /api/
        // Example URL: http://localhost:8080/api/foo_bar
        pub fn addEndpoint(self: *Self, method: HTTPMethod, comptime path: []const u8, callback: fn () void) !void {
            // First check for already existing entry and update that
            for (self._apiEndpoints.items, 0..) |item, i| {
                if (std.mem.eql(u8, path, item.path)) {
                    self._apiEndpoints.items[i].methods[@ctz(@intFromEnum(method))].callback = @constCast(&callback);
                    return;
                }
            }

            // If not, create new entry
            try self._apiEndpoints.append(.{
                .path = path,
                .methods = Handler.ContainerGen(method, @constCast(&callback)),
            });
            return;
        }

        pub fn composeTree(self: *Self) void {
            self._apiEndpoints.deinit();
            // At some point after data is sorted and put into the hashmap, reset it all

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

    for (router._apiEndpoints.items) |value| {
        for (0..9) |i| {
            std.debug.print("{any}\n", .{value.methods[i]});
        }
        @call(.auto, value.methods[0].callback.?, .{});
    }
}
