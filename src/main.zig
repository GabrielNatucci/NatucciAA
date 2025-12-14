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
var fenixFont: ?*sdl.TTF_Font = null;

const alloc = std.heap.c_allocator;

const HEIGHT: c_int = 720;
const WIDTH: c_int = 1280;

var homeScene: ?Scene = null;
var configScene: ?Scene = null;
var btScene: ?Scene = null;

var sceneManager: ?SceneManager = null;

var homeTemplate: ?HomeScene = null;
var configTemplate: ?ConfigScene = null;
var btTemplate: ?BluetoothScene = null;

var dbusImpl: ?dbus.DBus = null;
var btManager: ?bt.BluetoothManager = null;

const iconsSize: c_int = 120;
const buttonsHeight: c_int = 500;
const aaXPos: c_int = 70;
const btXPos: c_int = 310;
const radXPos: c_int = 550;
const fileXPos: c_int = 790;
const cfgXPos: c_int = 1030;

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
    fenixFont = sdl.TTF_OpenFont("./res/font/Fenix-Regular.ttf", 32);
    if (fenixFont == null) {
        std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
        return 1;
    }

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

    sceneManager = SceneManager.init(renderer.?) catch |err| {
        std.debug.print("Erro ao iniciar o SceneManager: {}", .{err});
        return 1;
    };

    homeTemplate = HomeScene.create(iconsSize, aaXPos, btXPos, fileXPos, cfgXPos, radXPos, buttonsHeight, renderer.?) catch |err| {
        std.debug.print("Ocorreu um erro ao criar a HomeScene: {}\n", .{err});
        return 1;
    };

    configTemplate = ConfigScene.create(renderer.?) catch |err| {
        std.debug.print("Ocorreu um erro ao criar a ConfigScene: {}\n", .{err});
        return 1;
    };

    dbusImpl = dbus.DBus.init() catch |err| {
        std.debug.print("Erro ao iniciar dbus: {}\n", .{err});
        return 1;
    };

    btManager = bt.BluetoothManager.init(&dbusImpl.?);
    btTemplate = BluetoothScene.create(renderer.?, &btManager.?) catch |err| {
        std.debug.print("Ocorreu um erro ao criar a BluetoothScene: {}\n", .{err});
        return 1;
    };

    homeScene = Scene.init("Home", &homeTemplate.?);
    configScene = Scene.init("Config", &configTemplate.?);
    btScene = Scene.init("Config", &btTemplate.?);

    sceneManager.?.setScene(homeScene.?) catch |err| {
        std.debug.print("Erro ao trocar scene: {}\n", .{err});
        return 1;
    };

    return 0;
}

pub fn quitEmAll() void {
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_DestroyRenderer(renderer);
    sdl.TTF_CloseFont(fenixFont);

    homeScene.?.deinit();
    configScene.?.deinit();
    sceneManager.?.deinit();
    // dbusImpl.?.deinit();
    // bt.BluetoothManager.deinit();
}

pub fn loop() !void {
    var rManager: SceneManager = sceneManager.?;
    var event: sdl.SDL_Event = undefined;
    var running = true;

    var last_time: u64 = sdl.SDL_GetTicks64();
    var delta_time: f32 = 0;

    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_SCALE_QUALITY, "2");
    _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_VSYNC, "1");

    var oldMili = std.time.milliTimestamp();
    var framesCounted: u64 = 0;

    btScene.?.active = false;
    configScene.?.active = false;

    while (running) {
        const current_time = sdl.SDL_GetTicks64();
        const delta_ms = current_time - last_time;
        last_time = current_time;
        delta_time = @as(f32, @floatFromInt(delta_ms)) / 1000.0;
        rManager.update(delta_time, renderer.?);

        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_KEYUP => {
                    switch (event.key.keysym.sym) {
                        sdl.SDLK_ESCAPE => {
                            rManager.setScene(homeScene.?) catch |err| {
                                std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                                return;
                            };
                        },
                        else => {},
                    }
                },
                sdl.SDL_MOUSEBUTTONUP => {
                    const mouseX = event.button.x;
                    const mouseY = event.button.y;

                    const isButtonHeight: bool = mouseY > buttonsHeight and mouseY < buttonsHeight + iconsSize;
                    var scene: ?Scene = null;

                    if (mouseX > cfgXPos and mouseX < (cfgXPos + iconsSize) and isButtonHeight == true) {
                        scene = configScene;
                    } else if (mouseX > btXPos and mouseX < (btXPos + iconsSize) and isButtonHeight == true){
                        scene = btScene;
                    }

                    if (scene != null) {
                        rManager.setScene(scene.?) catch |err| {
                            std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                            return;
                        };
                    }

                    std.debug.print("Mouse pos X: {}, Y: {}\n", .{ mouseX, mouseY });
                },
                sdl.SDL_QUIT => running = false,

                else => {},
            }
        }
        rManager.render();

        framesCounted += 1;

        const current = std.time.milliTimestamp();
        const timeDiff = current - oldMili;

        if (timeDiff >= 1000) {
            const fps = (@as(f64, @floatFromInt(framesCounted)) * 1000.0) / @as(f64, @floatFromInt(timeDiff));

            std.debug.print("FPS: {d:.0}\n", .{fps}); // sem casas decimais

            oldMili = current;
            framesCounted = 0;
        }
    }
}
