const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");

pub const HomeScene = struct {
    pub fn create() HomeScene {
        return .{};
    }

    pub fn init(self: *HomeScene) void {
        _ = self;
        std.debug.print("Inicializando scene...\n", .{});
    }

    pub fn deinit(self: *HomeScene) void {
        _ = self;
        std.debug.print("Limpando recursos\n", .{});
    }

    pub fn update(self: *HomeScene, delta_time: f32) void {
        _ = self;
        _ = delta_time;
    }

    pub fn render(self: *HomeScene, renderer: *sdl.SDL_Renderer) void {
        _ = self;

        var destination: sdl.SDL_Rect = .{ .x = 20, .y = 20, .w = 100, .h = 100};

        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = sdl.SDL_RenderDrawRect(renderer, &destination);
    }

    pub fn handleEvent(self: *HomeScene, event: sdl.SDL_Event) void {
        switch (event.type) {
            .key_press => {
                if (event.key) |k| {
                    std.debug.print("[{s}] Tecla pressionada: {c}\n", .{ self.name, k });
                }
            },
            .mouse_click => {
                std.debug.print("[{s}] Clique detectado\n", .{self.name});
            },
            else => {},
        }
    }
};
