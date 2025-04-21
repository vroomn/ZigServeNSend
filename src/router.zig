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

pub fn Router() type {
    return struct {
        const Self = @This();

        // Expects an arena allocator
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        // Intended for static content served to the client, overrides the default hander attached to content
        pub fn attachHandler(_: Self, method: HTTPMethod, path: []const u8, callback: fn () void) void {
            _ = method;
            _ = path;
            _ = callback;
            return;
        }

        // Intended for API endpoints, the path will be prepended with /api/
        // Example URL: http://localhost:8080/api/foo_bar
        pub fn addEndpoint(_: Self, method: HTTPMethod, path: []const u8, callback: fn () void) void {
            _ = method;
            _ = path;
            _ = callback;
            return;
        }

        pub fn composeTree(_: Self) void {
            return;
        }
    };
}
