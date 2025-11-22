const std = @import("std");
const NatucciAA = @import("NatucciAA");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

var renderer: ?*sdl.SDL_Renderer = null;
var window: ?*sdl.SDL_Window = null;

const HEIGHT: c_int = 720;
const WIDTH: c_int = 1280;

pub fn main() !void {
    if (init() > 0) {
        return;
    }
    defer {
        sdl.SDL_Quit();
        sdl.SDL_DestroyWindow(window);
    }

    try loop();
}

pub fn init() u4 {
    const initSdl: c_int = sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING);

    if (initSdl < 0) {
        std.debug.print("Erro ao inicalizar SDL -> {s}\n", .{sdl.SDL_GetError()});

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
        _ = sdl.SDL_RenderPresent(renderer);
    }
}
