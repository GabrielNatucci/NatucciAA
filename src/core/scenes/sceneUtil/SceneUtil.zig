const std = @import("std");

const sdl = @import("../../../sdlImport/Sdl.zig").sdl;
const Text = @import("../shared_components//Text.zig").Text;

pub const backButtonDest: sdl.SDL_Rect = .{ .x = 10, .y = 0, .w = 70, .h = 70 };

pub fn isBackButton(mouseY: i32, mouseX: i32) bool {
    const isBackbuttonHeight: bool = mouseY > backButtonDest.y and mouseY < backButtonDest.y + backButtonDest.h;
    const isBackbuttonWidth: bool = mouseX > backButtonDest.x and mouseX < backButtonDest.x + backButtonDest.w;

    return isBackbuttonWidth and isBackbuttonHeight;
}

pub fn createText(
    text: [:0]const u8,
    renderer: *sdl.SDL_Renderer,
    allocator: std.mem.Allocator,
    fontSize: c_int,
    color: sdl.SDL_Color,
    x: c_int,
    y: c_int,
) ?Text {
    const result = Text.init(text, renderer, allocator, fontSize, color, x, y) catch {
        return null;
    };

    return result;
}
