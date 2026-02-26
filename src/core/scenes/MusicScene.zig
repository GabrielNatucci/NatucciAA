const std = @import("std");

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const LARGURA_TELA = @import("../../main.zig").WIDTH;
const ALTURA_TELA = @import("../../main.zig").HEIGHT;
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const Text = @import("./components/Text.zig").Text;
const SceneUtil = @import("./sceneUtil/SceneUtil.zig");
const Scene = @import("Scene.zig");

const BRANCO: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };
const TAMANHO_FONTE_TITULO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.045); // Aprox. 32 para 720p
const POSICAO_TITULO_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.04); // Aprox. 30 para 720p
const POSICAO_TITULO_X: c_int = @divTrunc(LARGURA_TELA, 2); // Aprox. 30 para 720p

pub const MusicScene = struct {
    btManager: *bt.BluetoothManager,
    goBackTexture: *sdl.SDL_Texture,
    pageName: Text,

    pub fn create(renderer: *sdl.SDL_Renderer, allocator: std.mem.Allocator, bluetooth: *bt.BluetoothManager) !MusicScene {
        std.debug.print("\nInicializando musicScene...\n", .{});

        const backTexture = try textureUtil.loadSDLTexture(renderer, "res/images/backButton.png");

        return .{
            .goBackTexture = backTexture,
            .btManager = bluetooth,
            .pageName = try Text.init(
                "Music",
                renderer,
                allocator,
                TAMANHO_FONTE_TITULO,
                BRANCO,
                POSICAO_TITULO_X,
                POSICAO_TITULO_Y,
            ),
        };
    }

    pub fn init(self: *MusicScene) !void {
        _ = self;
        std.debug.print("Finalizando musicScene... (init)\n", .{});
    }

    pub fn deinit(self: *MusicScene) void {
        std.debug.print("Desligando musicScene\n", .{});

        sdl.SDL_DestroyTexture(self.goBackTexture);
        self.pageName.deinit();
    }

    pub fn update(self: *MusicScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = delta_time;
        _ = renderer;
        _ = active;
        _ = self;
    }

    pub fn render(self: *MusicScene, renderer: *sdl.SDL_Renderer) void {
        self.pageName.render();

        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &SceneUtil.backButtonDest);
    }

    pub fn handleEvent(self: *MusicScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                self.btManager.pauseMusic() catch |err| {
                    std.debug.print("Erro ao pausar música: {}\n", .{err});
                    return;
                };

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

    pub fn outOfFocus(self: *MusicScene) void {
        _ = self;
    }

    pub fn inOfFocus(self: *MusicScene) void {
        _ = self;
    }
};
