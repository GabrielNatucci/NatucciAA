
const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");

pub const ConfigScene = struct {
    horario: ?[6]u8,

    pub fn create() !ConfigScene {
        std.debug.print("Inicializando configScene...\n", .{});
        return .{
            .horario = null,
        };
    }

    pub fn init(self: *ConfigScene) !void {
        _ = self;
        std.debug.print("Inicializando configScene... (init)\n", .{});
    }

    pub fn deinit(self: *ConfigScene) void {
        _ = self;
        std.debug.print("Desligando configScene\n", .{});
    }

    pub fn update(self: *ConfigScene, delta_time: f32) void {
        _ = delta_time;
        self.horario = timeUtil.getCurrentTime();
    }

    pub fn render(self: *ConfigScene, renderer: *sdl.SDL_Renderer) void {
        _ = self;
        _ = renderer;
    }

    pub fn handleEvent(self: *ConfigScene, event: sdl.SDL_Event) void {
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
