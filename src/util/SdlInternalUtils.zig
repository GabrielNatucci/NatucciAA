const std = @import("std");
const sdl = @import("./../sdlImport/Sdl.zig").sdl;

pub fn initEmAll() u2 {
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


    return 0;
}

pub fn quitEmAll() void {
    sdl.Mix_Quit();
    sdl.SDL_Quit();
    sdl.TTF_Quit();
}
