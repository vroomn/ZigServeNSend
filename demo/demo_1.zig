const std = @import("std");
const zigserver = @import("ZigServer");

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = zigserver.log.override,
};

fn callback() void {
    std.log.info("Debug", .{});
}

pub fn main() !void {
    var server = zigserver.Server().init();

    try server.router.addEndpoint(zigserver.HTTPMethods.GET, "/", callback);

    server.listen() catch |err| return err;
    return;
}
