const std = @import("std");
const ArrayList = std.array_list.Managed;
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;

pub const Text = struct {
    texture: *sdl.SDL_Texture,
    sizeX: c_int,
    sizeY: c_int,

    pub fn init(
        renderer: *sdl.SDL_Renderer,
    ) Text {
        _ = renderer;
        return Text{
        };
    }

    pub fn deinit(self: Text) void {
        _ = self;
        // self.name.deinit();
        // self.address.deinit();
    }
};
