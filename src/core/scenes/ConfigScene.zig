const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const timeUtil = @import("../../util/TimeUtil.zig");
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const SceneUtil = @import("./sceneUtil/SceneUtil.zig");

pub const ConfigScene = struct {
    fonteConfig: ?*sdl.TTF_Font,
    goBackTexture: *sdl.SDL_Texture,

    pub fn create(renderer: *sdl.SDL_Renderer) !ConfigScene {
        std.debug.print("\nInicializando configScene...\n", .{});

        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", 32);

        if (fonte == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
            return error.FonteNaoCarregada;
        } else {
            std.debug.print("Fonte da config carregada\n", .{});
            sdl.TTF_SetFontStyle(fonte, sdl.TTF_STYLE_NORMAL);
        }

        const backTexture = try textureUtil.loadSDLTexture(renderer, "res/images/backButton.png");

        return .{
            .fonteConfig = fonte,
            .goBackTexture = backTexture,
        };
    }

    pub fn init(self: *ConfigScene) !void {
        _ = self;
        std.debug.print("Inicializando configScene... (init)\n", .{});
    }

    pub fn deinit(self: *ConfigScene) void {
        std.debug.print("Desligando configScene\n", .{});

        if (self.fonteConfig != null) {
            sdl.TTF_CloseFont(self.fonteConfig);
        }

        sdl.SDL_DestroyTexture(self.goBackTexture);
    }

    pub fn update(self: *ConfigScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = delta_time;
        _ = self;
        _ = renderer;
        _ = active;
    }

    pub fn render(self: *ConfigScene, renderer: *sdl.SDL_Renderer) void {
        const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

        const textSurface = sdl.TTF_RenderText_Blended(self.fonteConfig, "CONFIG", color);
        if (textSurface == null) return;
        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) return;
        defer sdl.SDL_DestroyTexture(textTexture);

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;

        var configDest: sdl.SDL_Rect = .{ .x = 565, .y = 10, .w = width, .h = height };

        _ = sdl.SDL_RenderCopy(renderer, textTexture, null, &configDest);

        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &SceneUtil.backButtonDest);
    }

    pub fn handleEvent(self: *ConfigScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        _ = self;

        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                if (SceneUtil.isBackButton(mouseY, mouseX)) {
                    sManager.setScene(sManager.homeScene) catch |err| {
                        std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                        return;
                    };
                }
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *ConfigScene) void {
        _ = self;
    }

    pub fn inOfFocus(self: *ConfigScene) void {
        _ = self;
    }
};
