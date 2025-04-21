const std = @import("std");

pub fn build(b: *std.Build) void {
    // Build the module which is the primary thing
    const zigserver = b.addModule("ZigServer", .{
        .root_source_file = b.path("src/zigserver.zig"),
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ZigServer_Demo",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("demo/demo_1.zig"),
    });
    exe.root_module.addImport("ZigServer", zigserver);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
