const std = @import("std");
const NatucciAA = @import("NatucciAA");

const timeUtil = @import("util/TimeUtil.zig");
const sdlUtil = @import("util/SdlInternalUtils.zig");
const sdl = @import("sdlImport/Sdl.zig").sdl;
const HomeScene = @import("core/scenes/Home.zig").HomeScene;
const SceneManager = @import("core/SceneManager.zig").SceneManager;
const Scene = @import("core/scenes/Scene.zig").Scene;

var renderer: ?*sdl.SDL_Renderer = null;
var window: ?*sdl.SDL_Window = null;
var fenixFont: ?*sdl.TTF_Font = null;

const alloc = std.heap.c_allocator;

const HEIGHT: c_int = 720;
const WIDTH: c_int = 1280;

var home: ?HomeScene = null;
var manager: ?SceneManager = null;

pub fn main() !void {
    const initReusult = sdlUtil.initEmAll();
    const componentReusult = initSomeStuff();
    if (initReusult > 0 and componentReusult > 0) {
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

    renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
    if (renderer == null) {
        std.debug.print("Erro ao criar renderer -> {s}", .{sdl.SDL_GetError()});
        return 1;
    }

    home = HomeScene.create();
    manager = SceneManager.init(renderer.?);

    manager.?.setScene(Scene.init("Home", &home.?)) catch |err| {
        std.debug.print("Erro ao trocar scene: {}\n", .{err});
        return 1;
    };

    return 0;
}

pub fn quitEmAll() void {
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_DestroyRenderer(renderer);
    sdl.TTF_CloseFont(fenixFont);
}

pub fn loop() !void {
    var rManager: SceneManager = manager.?;

    var event: sdl.SDL_Event = undefined;
    var running = true;

    const textColor: sdl.SDL_Color = .{ .r = 255, .g = 0, .b = 0, .a = 0 };
    var text: ?*sdl.SDL_Surface = null;

    while (running) {
        var buffer: [6]u8 = undefined;
        const time_str = try timeUtil.getCurrentTime(&buffer);
        text = sdl.TTF_RenderText_Blended(fenixFont, time_str.ptr, textColor);

        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => running = false,
                else => {},
            }
        }

        rManager.render();
    }

    sdl.SDL_FreeSurface(text);
}
