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

    // AASDK Integration - Compilando com g++ para evitar conflito de ABI do libc++ do Zig
    const cpp_sources = [_][]const u8{
        "src/core/aasdk/aasdk_wrapper.cpp",
        "src/core/aasdk/context/bluetooth/bluetooth_context.cpp",
        "src/core/aasdk/context/usb/usb_context.cpp",
        "src/core/aasdk/context/AndroidAutoFactory.cpp",
    };

    for (cpp_sources) |src| {
        const gpp = b.addSystemCommand(&[_][]const u8{ "g++", "-std=c++17", "-fPIC" });
        gpp.addArg("-c");
        gpp.addFileArg(b.path(src));
        gpp.addArgs(&[_][]const u8{
            "-I/usr/local/include",
            "-I/usr/include/dbus-1.0",
            "-I/usr/lib/dbus-1.0/include",
            "-I/usr/include/libusb-1.0",
            "-I/usr/include/SDL2",
            "-Isrc/core/aasdk",
            "-Isrc/core/aasdk/context/usb",
            "-Isrc/core/aasdk/context/bluetooth",
        });
        gpp.addArg("-o");
        const obj = gpp.addOutputFileArg(b.fmt("{s}.o", .{std.fs.path.basename(src)}));
        exe.addObjectFile(obj);
    }

    exe.linkSystemLibrary("aasdk");
    exe.linkSystemLibrary("aap_protobuf");
    exe.addObjectFile(.{ .cwd_relative = "/usr/lib/libstdc++.so" });
    exe.addObjectFile(.{ .cwd_relative = "/usr/lib/libgcc_s.so.1" });

    // Ensure it can find the library at runtime
    exe.addRPath(.{ .cwd_relative = "/usr/local/lib" });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
