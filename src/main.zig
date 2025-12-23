const std = @import("std");
const NatucciAA = @import("NatucciAA");
const sdl = @import("sdlImport/Sdl.zig").sdl;

const timeUtil = @import("util/TimeUtil.zig");
const sdlUtil = @import("util/SdlInternalUtils.zig");
const HomeScene = @import("core/scenes/HomeScene.zig").HomeScene;
const ConfigScene = @import("core/scenes/ConfigScene.zig").ConfigScene;
const SceneManager = @import("core/SceneManager.zig").SceneManager;
const BluetoothScene = @import("core/scenes/BluetoothScene.zig").BluetoothScene;

const Scene = @import("core/scenes/Scene.zig").Scene;
const bt = @import("core/bluetooth/BluetoothManager.zig");
const dbus = @import("core/dbus/dbus.zig");

var renderer: ?*sdl.SDL_Renderer = null;
var window: ?*sdl.SDL_Window = null;
var allocator = std.heap.GeneralPurposeAllocator(.{}){};

const alloc = std.heap.c_allocator;

pub const HEIGHT: c_int = 720;
pub const WIDTH: c_int = 1280;

var sceneManager: ?SceneManager = null;
var dbusImpl: ?dbus.DBus = null;
var btManager: ?bt.BluetoothManager = null;

pub fn main() !void {
    const initReusult = sdlUtil.initEmAll();
    const componentReusult = initSomeStuff();
    if (initReusult > 0 or componentReusult > 0) {
        return;
    }

    defer {
        quitEmAll();
        sdlUtil.quitEmAll();
    }

    try loop();
}

pub fn initSomeStuff() u2 {
    window = sdl.SDL_CreateWindow("NatucciAA", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, WIDTH, HEIGHT, sdl.SDL_WINDOW_SHOWN);
    if (window == null) {
        std.debug.print("Erro ao criar Janela -> {s}", .{sdl.SDL_GetError()});
        return 1;
    }

    renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC);
    if (renderer == null) {
        std.debug.print("Erro ao criar renderer -> {s}", .{sdl.SDL_GetError()});
        return 1;
    }

    dbusImpl = dbus.DBus.init() catch |err| {
        std.debug.print("Erro ao iniciar dbus: {}\n", .{err});
        return 1;
    };

    btManager = bt.BluetoothManager.init(&dbusImpl.?, allocator.allocator());

    sceneManager = SceneManager.init(renderer.?, &btManager.?, allocator.allocator()) catch |err| {
        std.debug.print("Erro ao iniciar o SceneManager: {}", .{err});
        return 1;
    };

    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_SCALE_QUALITY, "2");
    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_VSYNC, "1");

    return 0;
}

pub fn quitEmAll() void {
    if (btManager) |*btmn| btmn.deinit();
    if (sceneManager) |*sm| sm.deinit();

    if (renderer) |r| sdl.SDL_DestroyRenderer(r);
    if (window) |w| sdl.SDL_DestroyWindow(w);

    _ = allocator.deinit();
}

pub fn loop() !void {
    const sManager = &sceneManager.?;
    try sManager.setScene(sManager.homeScene);

    var running = true;
    var last_time: u64 = sdl.SDL_GetTicks64();
    var delta_time: f32 = 0;

    var oldMili = std.time.milliTimestamp();
    var framesCounted: u64 = 0;

    var event: sdl.SDL_Event = undefined;

    while (running) {
        const current_time = sdl.SDL_GetTicks64();
        const delta_ms = current_time - last_time;
        last_time = current_time;

        delta_time = @as(f32, @floatFromInt(delta_ms)) / 1000.0;

        sManager.update(delta_time, renderer.?, &event, &running);
        sManager.render();

        framesCounted += 1;

        const current = std.time.milliTimestamp();
        const timeDiff = current - oldMili;

        if (timeDiff >= 1000) {
            const fps = (@as(f64, @floatFromInt(framesCounted)) * 1000.0) / @as(f64, @floatFromInt(timeDiff));
            std.debug.print("FPS: {d:.0}\n", .{fps});

            oldMili = current;
            framesCounted = 0;
        }
    }
}
