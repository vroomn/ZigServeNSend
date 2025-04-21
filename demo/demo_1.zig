const std = @import("std");
const zigserver = @import("ZigServer");

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = zigserver.log.override,
};

pub fn main() !void {
    const server = zigserver.Server().init();

    server.listen() catch |err| return err;
    return;
}
