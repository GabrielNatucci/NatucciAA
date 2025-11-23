const std = @import("std");
const NatucciAA = @import("NatucciAA");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_mixer.h");
    @cInclude("SDL2/SDL_ttf.h");
});

var renderer: ?*sdl.SDL_Renderer = null;
var window: ?*sdl.SDL_Window = null;

const HEIGHT: c_int = 720;
const WIDTH: c_int = 1280;

pub fn main() !void {
    if (init() > 0) {
        return;
    }
    defer quitEmAll();

    try loop();
}

pub fn init() u4 {
    if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING) < 0) {
        std.debug.print("Erro ao inicalizar SDL -> {s}\n", .{sdl.SDL_GetError()});
        return 1;
    }

    if (sdl.Mix_OpenAudio(44100, sdl.MIX_DEFAULT_FORMAT, 2, 1024) < 0) {
        std.debug.print("Erro ao inicalizar SDL_mixer -> {s}\n", .{sdl.Mix_GetError()});
        return 1;
    }

    if (sdl.IMG_Init(sdl.IMG_INIT_JPG | sdl.IMG_INIT_PNG) < 0) {
        std.debug.print("Erro ao inicalizar SDL_Img -> {s}\n", .{sdl.IMG_GetError()});
        return 1;
    }

    if (sdl.TTF_Init() < 0) {
        std.debug.print("Erro ao inicalizar SDL_ttf -> {s}\n", .{sdl.TTF_GetError()});
        return 1;
    }

    window = sdl.SDL_CreateWindow("NatucciAA", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, 1280, HEIGHT, sdl.SDL_WINDOW_SHOWN);
    if (window == null) {
        std.debug.print("Erro ao criar Janela -> {s}", .{sdl.SDL_GetError()});
        return 1;
    }

    renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
    if (renderer == null) {
        std.debug.print("Erro ao criar renderer -> {s}", .{sdl.SDL_GetError()});
        return 1;
    }

    std.debug.print("FOI\n", .{});
    return 0;
}

pub fn quitEmAll() void {
    sdl.Mix_Quit();
    sdl.SDL_Quit();
    sdl.SDL_DestroyWindow(window);
    sdl.TTF_Quit();
}

pub fn loop() !void {
    var event: sdl.SDL_Event = undefined;
    var running = true;

    while (running) {
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => running = false,
                else => {},
            }
        }
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = sdl.SDL_RenderClear(renderer);

        var rect: sdl.SDL_Rect = .{ .x = 20, .y = 20, .w = 100, .h = 100 };

        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = sdl.SDL_RenderDrawRect(renderer, &rect);

        _ = sdl.SDL_RenderPresent(renderer);
    }
}
