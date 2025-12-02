const std = @import("std");
const sdl = @import("./../sdlImport/Sdl.zig").sdl;

pub fn loadSDLTexture(renderer: *sdl.SDL_Renderer, path: [:0]const u8) !*sdl.SDL_Texture {
    const tmpSurface: ?*sdl.SDL_Surface = sdl.IMG_Load(path);

    if (tmpSurface == null) {
        std.debug.print("Erro ao carregar imagem: {s}", .{sdl.IMG_GetError()});
        return error.TexturaNaoCarregada;
    }

    defer sdl.SDL_FreeSurface(tmpSurface);

    return sdl.SDL_CreateTextureFromSurface(renderer, tmpSurface).?;
}
