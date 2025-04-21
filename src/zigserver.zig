const std = @import("std");

pub fn Server() type {
    return struct {
        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn listen(_: Self) !void {
            return;
        }
    };
}
