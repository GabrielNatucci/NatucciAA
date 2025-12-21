const std = @import("std");
const Scene = @import("scenes/Scene.zig").Scene;
const sdl = @import("../sdlImport/Sdl.zig").sdl;
const HomeScene = @import("./scenes/HomeScene.zig").HomeScene;
const ConfigScene = @import("./scenes/ConfigScene.zig").ConfigScene;
const BluetoothScene = @import("./scenes/BluetoothScene.zig").BluetoothScene;
const bt = @import("bluetooth/BluetoothManager.zig");

const iconsSize: c_int = 120;
const buttonsHeight: c_int = 500;
const aaXPos: c_int = 70;
const btXPos: c_int = 310;
const radXPos: c_int = 550;
const fileXPos: c_int = 790;
const cfgXPos: c_int = 1030;

pub const SceneManager = struct {
    allocator: std.mem.Allocator,
    current_scene: ?*Scene = null,
    old_scene: ?Scene,
    renderer: *sdl.SDL_Renderer,
    background: *sdl.SDL_Texture,

    homeTemplate: *HomeScene,
    configTemplate: *ConfigScene,
    btTemplate: *BluetoothScene,

    homeScene: *Scene,
    configScene: *Scene,
    btScene: *Scene,

    pub fn init(renderer: *sdl.SDL_Renderer, btManager: *bt.BluetoothManager, allocator: std.mem.Allocator) !SceneManager {
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

        const homeTemplate = try allocator.create(HomeScene);
        homeTemplate.* = try HomeScene.create(iconsSize, aaXPos, btXPos, fileXPos, cfgXPos, radXPos, buttonsHeight, renderer);
        var homeScene = try allocator.create(Scene);
        homeScene.* = Scene.init("Home", homeTemplate);

        const configTemplate = try allocator.create(ConfigScene);
        configTemplate.* = try ConfigScene.create(renderer);
        var configScene = try allocator.create(Scene);
        configScene.* = Scene.init("Config", configTemplate);

        const btTemplate = try allocator.create(BluetoothScene);
        btTemplate.* = try BluetoothScene.create(renderer, btManager, allocator);
        var btScene = try allocator.create(Scene);
        btScene.* = Scene.init("BT", btTemplate);

        configScene.active = false;
        btScene.active = false;
        homeScene.active = true;

        return .{
            .allocator = allocator,
            .current_scene = null,
            .old_scene = null,
            .renderer = renderer,
            .background = backgroundTexture.?,
            .homeTemplate = homeTemplate,
            .configTemplate = configTemplate,
            .btTemplate = btTemplate,
            .homeScene = homeScene,
            .configScene = configScene,
            .btScene = btScene,
        };
    }

    pub fn setScene(self: *SceneManager, scene: *Scene) !void {
        std.debug.print("\nTrocando de Scene: {s}\n", .{scene.name});

        if (self.current_scene != null) {
            self.current_scene.?.active = false;
            self.current_scene.?.outOfFocus();
        }

        self.current_scene = scene;
        self.current_scene.?.active = true;
        self.current_scene.?.inOfFocus();
    }

    pub fn update(self: *SceneManager, delta_time: f32, renderer: *sdl.SDL_Renderer, event: *sdl.SDL_Event, running: *bool) void {
        while (sdl.SDL_PollEvent(event) != 0) {
            switch (event.type) {
                sdl.SDL_KEYUP => {
                    switch (event.key.keysym.sym) {
                        sdl.SDLK_ESCAPE => {
                            self.setScene(self.homeScene) catch |err| {
                                std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                                return;
                            };
                        },
                        else => {},
                    }
                },
                sdl.SDL_MOUSEBUTTONUP => {
                    const mouseX = event.button.x;
                    const mouseY = event.button.y;

                    const isButtonHeight: bool = mouseY > buttonsHeight and mouseY < buttonsHeight + iconsSize;
                    var scene: ?*Scene = null;

                    if (mouseX > cfgXPos and mouseX < (cfgXPos + iconsSize) and isButtonHeight == true) {
                        scene = self.configScene; 
                    } else if (mouseX > btXPos and mouseX < (btXPos + iconsSize) and isButtonHeight == true) {
                        scene = self.btScene; 
                    }

                    if (scene != null) {
                        self.setScene(scene.?) catch |err| {
                            std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                            return;
                        };
                    }

                    std.debug.print("Mouse pos X: {}, Y: {}\n", .{ mouseX, mouseY });
                },
                sdl.SDL_QUIT => running.* = false,

                else => {},
            }
        }

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
        self.homeTemplate.deinit();
        self.configTemplate.deinit();
        self.btTemplate.deinit();

        self.allocator.destroy(self.homeScene);
        self.allocator.destroy(self.configScene);
        self.allocator.destroy(self.btScene);
        self.allocator.destroy(self.homeTemplate);
        self.allocator.destroy(self.configTemplate);
        self.allocator.destroy(self.btTemplate);

        sdl.SDL_DestroyTexture(self.background);
    }
};
