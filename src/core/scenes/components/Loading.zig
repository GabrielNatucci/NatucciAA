const std = @import("std");
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;
const ArrayList = std.array_list.Managed;

pub const Loading = struct {
    const ROTATION_SPEED: f64 = 1.5; // Ajuste este valor para mudar a velocidade

    texture: *sdl.SDL_Texture,
    x: c_int,
    y: c_int,
    rotationAngle: f64,
    width: c_int,
    height: c_int,
    renderer: *sdl.SDL_Renderer,

    pub fn init(renderer: *sdl.SDL_Renderer, rect: sdl.SDL_Rect) !Loading {
        const surface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/loading.png");
        if (surface == null) return error.surfaceNaoCriada;
        defer sdl.SDL_FreeSurface(surface.?);

        const texture: ?*sdl.SDL_Texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
        if (texture == null) return error.texturaNaoCriada;

        return Loading{
            .width = rect.w,
            .height = rect.h,
            .renderer = renderer,
            .texture = texture.?,
            .x = rect.x,
            .y = rect.y,
            .rotationAngle = 0,
        };
    }

    pub fn deinit(self: Loading) void {
        sdl.SDL_DestroyTexture(self.texture);
    }

    pub fn renderLoading(self: *Loading) void {
        var dest: sdl.SDL_Rect = .{ .x = self.x, .y = self.y, .w = self.width, .h = self.height };
        var center: sdl.SDL_Point = .{ .x = @divTrunc(self.width, 2), .y = @divTrunc(self.height, 2) };
        const flip: sdl.SDL_RendererFlip = sdl.SDL_FLIP_NONE;

        _ = sdl.SDL_RenderCopyEx(self.renderer, self.texture, null, &dest, self.rotationAngle, &center, flip);

        self.rotationAngle += ROTATION_SPEED;
        if (self.rotationAngle > 360) self.rotationAngle = 0.0;
    }
};
