const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "upsie",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const aarch64_exe = b.addExecutable(.{
        .name = "upsie-aarch64",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .aarch64,
                .os_tag = .linux,
            }),
            .optimize = optimize,
        }),
    });
    aarch64_exe.linkLibC();

    const aarch64_install = b.addInstallArtifact(aarch64_exe, .{});
    const aarch64_step = b.step("aarch64", "Build for aarch64-linux");
    aarch64_step.dependOn(&aarch64_install.step);
}
