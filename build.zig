const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "texteditor",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    const raylib = b.dependency("raylib", .{});
    const raygui = b.dependency("raygui", .{});

    exe.linkLibrary(raylib.artifact("raylib"));
    exe.addIncludePath(raygui.path("src"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const gpTest = b.addTest(.{
        .root_source_file = b.path("src/gapBuffer.zig"),
        .error_tracing = true,
        .target = target,
        .optimize = optimize,
    });

    const r_gptest = b.addRunArtifact(gpTest);
    const test_step = b.step("test", "test all things");

    test_step.dependOn(&r_gptest.step);
}
