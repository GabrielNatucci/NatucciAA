const std = @import("std");
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;
const ArrayList = std.array_list.Managed;

pub const Text = struct {
    allocator: std.mem.Allocator,
    texture: *sdl.SDL_Texture,
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
    renderer: *sdl.SDL_Renderer,

    pub fn init(
        text: [:0]const u8,
        renderer: *sdl.SDL_Renderer,
        allocator: std.mem.Allocator,
        fontSize: c_int,
        color: sdl.SDL_Color,
        x: c_int,
        y: c_int,
    ) !Text {
        if (text.len == 0) return error.TextoNaoPodeSerVazio;

        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", fontSize);
        if (fonte == null) return error.FonteNaoFoiCarregada;
        defer sdl.TTF_CloseFont(fonte);

        const textSurface = sdl.TTF_RenderText_Blended(fonte, text, color);
        if (textSurface == null) {
            std.debug.print("Erro ao criar surface de texto: {s}", .{sdl.SDL_GetError()});
            return error.surfaceNaoCriada;
        }
        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) {
            std.debug.print("Erro ao criar surface de texto: {s}", .{sdl.SDL_GetError()});
            return error.texturaNaoCriada;
        }
        if (textTexture == null) return error.TexturaDoTextoNaoFoiCriada;

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;
        const xtext: c_int = x - @divTrunc(width, 2); // para deixar o texto ajustado no centro
        const ytext: c_int = y - @divTrunc(height, 2); // para deixar o texto ajustado no centro

        return Text{
            .allocator = allocator,
            .width = width,
            .height = height,
            .renderer = renderer,
            .texture = textTexture.?,
            .x = xtext,
            .y = ytext,
        };
    }

    pub fn deinit(self: Text) void {
        sdl.SDL_DestroyTexture(self.texture);
    }

    pub fn hasBeenClicked(self: Text, mouseX: sdl.Sint32, mouseY: sdl.Sint32) bool {
        const rect = sdl.SDL_Rect{
            .x = self.x,
            .y = self.y,
            .w = self.width,
            .h = self.height,
        };

        return isClickInsideRect(mouseX, mouseY, rect);
    }

    fn isClickInsideRect(mouseX: c_int, mouseY: c_int, rect: sdl.SDL_Rect) bool {
        return mouseX >= rect.x and mouseX <= rect.x + rect.w and
            mouseY >= rect.y and mouseY <= rect.y + rect.h;
    }

    pub fn render(self: Text) void {
        var dest: sdl.SDL_Rect = .{ .x = self.x, .y = self.y, .w = self.width, .h = self.height };
        _ = sdl.SDL_RenderCopy(self.renderer, self.texture, null, &dest);
    }
};
