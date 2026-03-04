const std = @import("std");

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const LARGURA_TELA = @import("../../main.zig").WIDTH;
const ALTURA_TELA = @import("../../main.zig").HEIGHT;
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const Text = @import("./components/Text.zig").Text;
const Image = @import("./components/Image.zig").Image;
const SceneUtil = @import("./sceneUtil/SceneUtil.zig");
const Scene = @import("Scene.zig");

const BRANCO: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };
const TAMANHO_FONTE_TITULO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.045); // Aprox. 32 para 720p
const POSICAO_TITULO_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.04); // Aprox. 30 para 720p
const POSICAO_TITULO_X: c_int = @divTrunc(LARGURA_TELA, 2); // Aprox. 30 para 720p

const X_BOTAO_VOLTAR: c_int = @intFromFloat(@as(f32, LARGURA_TELA) * 0.04);
const Y_BOTAO_VOLTAR: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.05);

const ANTERIOR_MUSICA_BOTAO: c_int = 300;
const DISTANCIA_BOTOES_MUSICA: c_int = @divTrunc(LARGURA_TELA - (ANTERIOR_MUSICA_BOTAO * 2), 2);
const ALTURA_BOTOES_MUSICA: c_int = 600;
const PAUSAR_MUSICA_BOTAO: c_int = ANTERIOR_MUSICA_BOTAO + DISTANCIA_BOTOES_MUSICA;
const PROXIMA_MUSICA_BOTAO: c_int = PAUSAR_MUSICA_BOTAO + DISTANCIA_BOTOES_MUSICA;

pub const MusicScene = struct {
    btManager: *bt.BluetoothManager,
    pageName: Text,
    goBackImg: Image,
    nextMusicImg: Image,
    prevMusicImg: Image,
    pauseMusicImg: Image,

    pub fn create(renderer: *sdl.SDL_Renderer, allocator: std.mem.Allocator, bluetooth: *bt.BluetoothManager) !MusicScene {
        std.debug.print("\nInicializando musicScene...\n", .{});

        const backTexture = try Image.init("res/images/backButton.png", renderer, allocator, X_BOTAO_VOLTAR, Y_BOTAO_VOLTAR, 0.3);
        const nextImage = try Image.init("res/images/nextmusic.png", renderer, allocator, PROXIMA_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.3);
        const prevImage = try Image.init("res/images/previousmusic.png", renderer, allocator, ANTERIOR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.3);
        const pauseImage = try Image.init("res/images/pausemusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.4);
        // const resumeImage = try Image.init("res/images/pausemusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.4);

        return .{
            .goBackImg = backTexture,
            .btManager = bluetooth,
            .nextMusicImg = nextImage,
            .prevMusicImg = prevImage,
            .pauseMusicImg = pauseImage,
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
        self.pageName.deinit();
        self.nextMusicImg.deinit();
        self.prevMusicImg.deinit();
        self.pauseMusicImg.deinit();
        self.goBackImg.deinit();
    }

    pub fn update(self: *MusicScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = delta_time;
        _ = renderer;
        _ = active;
        _ = self;
    }

    pub fn render(self: *MusicScene, renderer: *sdl.SDL_Renderer) void {
        _ = renderer;

        self.pageName.render();
        self.goBackImg.render();
        self.nextMusicImg.render();
        self.prevMusicImg.render();
        self.pauseMusicImg.render();
    }

    pub fn handleEvent(self: *MusicScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const x = event.button.x;
                const y = event.button.y;

                if (self.goBackImg.hasBeenClicked(x, y)) {
                    sManager.setScene(sManager.homeScene) catch |err| std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                } else if (self.pauseMusicImg.hasBeenClicked(x, y)) {
                    self.btManager.pauseMusic() catch |err| std.debug.print("Erro ao pausar música: {}\n", .{err});
                } else if (self.nextMusicImg.hasBeenClicked(x, y)) {
                    self.btManager.nextMusic() catch |err| std.debug.print("Erro ao passar a música: {}\n", .{err});
                } else if (self.prevMusicImg.hasBeenClicked(x, y)) {
                    self.btManager.previousMusic() catch |err| std.debug.print("Erro ao voltar na música anterior: {}\n", .{err});
                }
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *MusicScene) void {
        _ = self;
    }

    pub fn inOfFocus(self: *MusicScene) void {
        self.btManager.getMusicPlayer() catch |err| {
            std.debug.print("Erro ao pausar música: {}\n", .{err});
            return;
        };
    }
};
