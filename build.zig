const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Compilar o código Zig para um objeto
    const zig_obj = b.addObject(.{
        .name = "natucciaa_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    zig_obj.linkLibC();
    zig_obj.addIncludePath(.{ .cwd_relative = "/usr/include/dbus-1.0" });
    zig_obj.addIncludePath(.{ .cwd_relative = "/usr/lib/dbus-1.0/include" });
    zig_obj.addIncludePath(.{ .cwd_relative = "/usr/include/SDL2" });

    // 2. Compilar os arquivos C++ com g++ e preparar a linkagem
    const cpp_sources = [_][]const u8{
        "src/core/aasdk/aasdk_wrapper.cpp",
        "src/core/aasdk/context/bluetooth/bluetooth_context.cpp",
        "src/core/aasdk/context/usb/usb_context.cpp",
        "src/core/aasdk/context/AndroidAutoFactory.cpp",
        "src/core/aasdk/context/ControlChannelHandler.cpp",
        "src/core/aasdk/context/CarConfiguration.cpp",
    };

    // 3. Linkar tudo com g++
    // Usamos g++ para a linkagem final por dois motivos principais:
    // 1. Evitar o erro "unhandled relocation type R_X86_64_PC64" do linker do Zig em sistemas muito recentes.
    // 2. Garantir que a libstdc++ seja usada em vez da libc++, mantendo compatibilidade com as libs do sistema (aasdk, protobuf).
    const linker = b.addSystemCommand(&[_][]const u8{ "g++" });
    linker.addFileArg(zig_obj.getEmittedBin());

    for (cpp_sources) |src| {
        const gpp = b.addSystemCommand(&[_][]const u8{ "g++", "-std=c++17", "-fPIC", "-O2" });
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
        linker.addFileArg(gpp.addOutputFileArg(b.fmt("{s}.o", .{std.fs.path.basename(src)})));
    }
    
    // 3. Linkar tudo com g++
    linker.addArgs(&[_][]const u8{
        "-lSDL2", "-lSDL2_image", "-lSDL2_mixer", "-lSDL2_ttf",
        "-ldbus-1", "-lusb-1.0", "-lprotobuf", "-laasdk", "-laap_protobuf",
        "-labsl_log_internal_check_op", "-labsl_log_internal_message", "-labsl_log_internal_conditions",
        "-labsl_die_if_null", "-labsl_log_internal_format", "-labsl_log_internal_nullguard",
        "-labsl_statusor", "-labsl_status", "-labsl_cord", "-labsl_strings", "-labsl_base", "-labsl_spinlock_wait", "-labsl_throw_delegate", "-labsl_raw_logging_internal", "-labsl_log_severity", "-labsl_time", "-labsl_int128",
        "-L/usr/local/lib", "-Wl,-rpath,/usr/local/lib",
        "-lpthread", "-lm", "-ldl",
    });

    linker.addArg("-o");
    const exe_file = linker.addOutputFileArg("NatucciAA");

    // Instalar o executável
    const install_exe = b.addInstallFile(exe_file, "bin/NatucciAA");
    b.getInstallStep().dependOn(&install_exe.step);

    // Passo de execução
    const run_step = b.step("run", "Run the app");
    const run_bin = b.addSystemCommand(&[_][]const u8{ b.getInstallPath(.bin, "NatucciAA") });
    run_bin.step.dependOn(&install_exe.step);
    run_step.dependOn(&run_bin.step);
}
