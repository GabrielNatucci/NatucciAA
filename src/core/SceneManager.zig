const std = @import("std");
const Scene = @import("scenes/Scene.zig").Scene;
const sdl = @import("../sdlImport/Sdl.zig").sdl;

pub const SceneManager = struct {
    current_scene: ?Scene,
    old_scene: ?Scene,
    renderer: *sdl.SDL_Renderer,

    pub fn init(renderer : *sdl.SDL_Renderer) SceneManager {
        return .{ .current_scene = null, .old_scene = null, .renderer = renderer};
    }

    pub fn setScene(self: *SceneManager, scene: Scene) !void {
        if (self.current_scene) |*current| {
            current.deinit();
        }

        self.current_scene = scene;
        try self.current_scene.?.initScene();
    }

    pub fn update(self: *SceneManager, delta_time: f32) void {
        if (self.current_scene) |scene| {
            scene.update(delta_time);
        }
    }

    pub fn render(self: *SceneManager) void {
        _ = sdl.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255);
        _ = sdl.SDL_RenderClear(self.renderer);

        if (self.current_scene) |scene| {
            scene.render(self.renderer);
        }

        _ = sdl.SDL_RenderPresent(self.renderer);
    }

    pub fn getCurrentSceneName(self: SceneManager) ?[]const u8 {
        if (self.current_scene) |scene| {
            return scene.name;
        }
        return null;
    }

    pub fn pauseCurrentScene(self: *SceneManager) void {
        if (self.current_scene) |*scene| {
            scene.setActive(false);
        }
    }

    pub fn resumeCurrentScene(self: *SceneManager) void {
        if (self.current_scene) |*scene| {
            scene.setActive(true);
        }
    }

    pub fn deinit(self: *SceneManager) void {
        if (self.current_scene) |*scene| {
            scene.deinit();
        }
    }
};
