const std = @import("std");
const Scene = @import("scenes/Scene.zig").Scene;
const sdl = @import("../sdlImport/Sdl.zig").sdl;

pub const SceneManager = struct {
    current_scene: ?Scene,
    old_scene: ?Scene,
    renderer: *sdl.SDL_Renderer,
    background: *sdl.SDL_Texture,

    pub fn init(renderer: *sdl.SDL_Renderer) !SceneManager {
        const backgroundSurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/fundo.png");

        if (backgroundSurface == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.IMG_GetError()});
            return error.FotoNaoCarregada;
        }

        const backgroundTexture: ?*sdl.SDL_Texture = sdl.SDL_CreateTextureFromSurface(renderer, backgroundSurface);
        if (backgroundTexture == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.IMG_GetError()});
            return error.ErroAoCarregarTextura;
        }

        defer sdl.SDL_FreeSurface(backgroundSurface);

        return .{ .current_scene = null, .old_scene = null, .renderer = renderer, .background = backgroundTexture.? };
    }

    pub fn setScene(self: *SceneManager, scene: Scene) !void {
        std.debug.print("\nTrocando de Scene: {s}\n", .{scene.name});

        self.current_scene = scene;
    }

    pub fn update(self: *SceneManager, delta_time: f32, renderer: *sdl.SDL_Renderer) void {
        if (self.current_scene) |scene| {
            scene.update(delta_time, renderer);
        }
    }

    pub fn render(self: *SceneManager) void {
        var dir: sdl.SDL_Rect = .{ .h = 720, .w = 1280, .x = 0, .y = 0 };
        _ = sdl.SDL_RenderCopy(self.renderer, self.background, null, &dir);

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
        sdl.SDL_DestroyTexture(self.background);
    }
};
