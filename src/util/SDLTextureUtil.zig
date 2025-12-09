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

pub fn createTextureFromText(renderer: *sdl.SDL_Renderer, color: sdl.SDL_Color, text: [*c]const u8, font: *sdl.TTF_Font) ?*sdl.SDL_Texture {
    const textSurface = sdl.TTF_RenderText_Blended(font, text, color);
    defer sdl.SDL_FreeSurface(textSurface);

    if (textSurface == null) {
        std.debug.print("Erro ao criar surface de fonte: {s}\n", .{sdl.TTF_GetError()});
        return null;
    }

    const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);

    return textTexture.?;
}
