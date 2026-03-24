const std = @import("std");
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;
const ArrayList = std.array_list.Managed;

pub const Image = struct {
    allocator: std.mem.Allocator,
    texture: *sdl.SDL_Texture,
    x: c_int,
    y: c_int,
    width: c_int,
    height: c_int,
    renderer: *sdl.SDL_Renderer,

    pub fn init(path: [*c]const u8, renderer: *sdl.SDL_Renderer, allocator: std.mem.Allocator, x: c_int, y: c_int, scale: f32) !Image {
        const tmpSurface: ?*sdl.SDL_Surface = sdl.IMG_Load(path);

        if (tmpSurface == null) {
            std.debug.print("Erro ao carregar imagem: {s}\n", .{sdl.IMG_GetError()});
            return error.TexturaNaoCarregada;
        }

        const height: c_int = @intFromFloat(@as(f32, @floatFromInt(tmpSurface.?.h)) * scale);
        const width: c_int = @intFromFloat(@as(f32, @floatFromInt(tmpSurface.?.w)) * scale);

        std.debug.print("height: {d}\n", .{tmpSurface.?.h});
        std.debug.print("height calculated: {d}\n", .{height});
        defer sdl.SDL_FreeSurface(tmpSurface);
        const texture: ?*sdl.SDL_Texture = sdl.SDL_CreateTextureFromSurface(renderer, tmpSurface);

        const xPos = x - @divTrunc(width, 2);
        const yPost = y - @divTrunc(height, 2);

        return Image{
            .allocator = allocator,
            .width = width,
            .height = height,
            .renderer = renderer,
            .texture = texture.?,
            .x = xPos,
            .y = yPost,
        };
    }

    pub fn deinit(self: Image) void {
        sdl.SDL_DestroyTexture(self.texture);
    }

    pub fn hasBeenClicked(self: Image, mouseX: sdl.Sint32, mouseY: sdl.Sint32) bool {
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

    pub fn render(self: Image) void {
        var dest: sdl.SDL_Rect = .{
            .x = self.x,
            .y = self.y,
            .w = self.width,
            .h = self.height,
        };

        _ = sdl.SDL_RenderCopy(self.renderer, self.texture, null, &dest);
    }
};
