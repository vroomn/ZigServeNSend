// An override option of the zig log underlying functionality, gives a time of the event for the sake of debugging later

const std = @import("std");
const syscalls = @import("syscalls.zig");

const Timeval = struct {
    seconds: c_long,
    microseconds: c_long,
};

pub fn override(comptime level: std.log.Level, comptime scope: @Type(.enum_literal), comptime format: []const u8, args: anytype) void {
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    const stderr = std.io.getStdErr().writer();

    // Run through gettimeofday to eventually print out time in logical way, prob some way to improve it but idc
    var time: Timeval = undefined;
    if (syscalls.syscallTwo(96, @intFromPtr(&time), @intFromPtr(@as(?*const u8, null))) > -1) {
        const daySeconds = @mod(time.seconds, 86400);
        nosuspend stderr.print("[{d}:{d}:{d} | {d}ms] ", .{
            @divTrunc(daySeconds, 3600),
            @divTrunc(@mod(daySeconds, 3600), 60),
            @mod(time.seconds, 60),
            @mod(@divTrunc(time.microseconds, 1000), 10000),
        }) catch {};
    } else {
        nosuspend stderr.print("[ ERR ] ", .{}) catch {};
    }

    const colorization = switch (level) {
        .err => "\x1b[38;5;196m",
        .warn => "\x1b[38;5;214m",
        .info => "\x1b[38;5;39m",
        .debug => "\x1b[38;5;8m",
    };

    nosuspend stderr.print(colorization ++ "<" ++ @tagName(scope) ++ "/" ++ @tagName(level) ++ ">\x1b[0m " ++ format ++ "\n", args) catch return;
    return;
}
