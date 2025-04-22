const std = @import("std");
pub const log = @import("log_override.zig");
const router = @import("router.zig");

pub fn Server() type {
    return struct {
        const Self = @This();

        router: router.Router(),

        pub fn init() Self {
            return .{
                .router = router.Router().init(std.heap.page_allocator),
            };
        }

        pub fn listen(_: Self) !void {
            return;
        }
    };
}
