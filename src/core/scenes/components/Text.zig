const std = @import("std");
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;
const ArrayList = std.array_list.Managed;

pub const Text = struct {
    allocator: std.mem.Allocator,
    texture: *sdl.SDL_Texture,
    text: ArrayList(u8),
    width: c_int,
    height: c_int,
    renderer: *sdl.SDL_Renderer,

    pub fn init(
        text: [*c]const u8,
        renderer: *sdl.SDL_Renderer,
        allocator: std.mem.Allocator,
        fontSize: c_int,
        color: sdl.SDL_Color,
    ) !Text {
        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", fontSize);
        if (fonte == null) return error.FonteNaoFoiCarregada;
        defer sdl.TTF_CloseFont(fonte);

        var textTemp = ArrayList(u8).init(allocator);
        errdefer textTemp.deinit();

        const slice = std.mem.span(text);
        try textTemp.appendSlice(slice);
        try textTemp.append(0);

        const textSurface = sdl.TTF_RenderText_Blended(fonte, textTemp.items.ptr, color);
        if (textSurface == null) return error.SurfaceDoTextoNaoFoiCriada;
        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) return error.TexturaDoTextoNaoFoiCriada;

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;

        return Text{
            .allocator = allocator,
            .width = width,
            .height = height,
            .text = textTemp,
            .renderer = renderer,
            .texture = textTexture.?,
        };
    }

    pub fn deinit(self: Text) void {
        self.text.deinit();
        sdl.SDL_DestroyTexture(self.texture);
    }

    pub fn render(self: Text, color: sdl.SDL_Color, x: c_int, y: c_int) void {
        _ = color;

        var dest: sdl.SDL_Rect = .{ .x = x, .y = y, .w = self.width, .h = self.height };
        _ = sdl.SDL_RenderCopy(self.renderer, self.texture, null, &dest);
    }
};
