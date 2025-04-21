const std = @import("std");
const zigserver = @import("ZigServer");

pub fn main() !void {
    const server = zigserver.Server().init();

    try server.listen();
    return;
}
