const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "NatucciAA",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("dbus-1");
    exe.linkSystemLibrary("usb-1.0");
    exe.linkLibC();

    // AASDK Integration
    exe.addCSourceFile(.{
        .file = b.path("src/core/aasdk/aasdk_wrapper.cpp"),
        .flags = &[_][]const u8{"-std=c++17", "-stdlib=libstdc++"},
    });

    exe.addCSourceFile(.{
        .file = b.path("src/core/aasdk/context/bluetooth/bluetooth_context.cpp"),
        .flags = &[_][]const u8{"-std=c++17", "-stdlib=libstdc++"},
    });

    exe.addCSourceFile(.{
        .file = b.path("src/core/aasdk/context/usb/usb_context.cpp"),
        .flags = &[_][]const u8{"-std=c++17", "-stdlib=libstdc++"},
    });

    exe.linkSystemLibrary("aasdk");
    exe.linkSystemLibrary("aap_protobuf");
    exe.linkSystemLibrary("stdc++");

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
