const std = @import("std");
const sdl = @import("../../../sdlImport/Sdl.zig").sdl;

pub const backButtonDest: sdl.SDL_Rect = .{ .x = 10, .y = 0, .w = 70, .h = 70 };

pub fn isBackButton(mouseY: i32, mouseX: i32) bool {
    const isBackbuttonHeight: bool = mouseY > backButtonDest.y and mouseY < backButtonDest.y + backButtonDest.h;
    const isBackbuttonWidth: bool = mouseX > backButtonDest.x and mouseX < backButtonDest.x + backButtonDest.w;

    return isBackbuttonWidth and isBackbuttonHeight;
}
