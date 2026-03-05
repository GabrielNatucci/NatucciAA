const std = @import("std");

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const LARGURA_TELA = @import("../../main.zig").WIDTH;
const ALTURA_TELA = @import("../../main.zig").HEIGHT;
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const Image = @import("./components/Image.zig").Image;
const Text = @import("./components/Text.zig").Text;
const TrackInfo = @import("./../bluetooth/Music/TrackInfo.zig").TrackInfo;
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
    resumeMusicImg: Image,
    lastTimeSeconds: f32,
    musicText: ?Text = null,
    progress: ?Text = null,
    trackInfo: ?TrackInfo = null,
    allocator: std.mem.Allocator,

    pub fn create(renderer: *sdl.SDL_Renderer, allocator: std.mem.Allocator, bluetooth: *bt.BluetoothManager) !MusicScene {
        std.debug.print("\nInicializando musicScene...\n", .{});

        const backTexture = try Image.init("res/images/backButton.png", renderer, allocator, X_BOTAO_VOLTAR, Y_BOTAO_VOLTAR, 0.3);
        const nextImage = try Image.init("res/images/nextmusic.png", renderer, allocator, PROXIMA_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.3);
        const prevImage = try Image.init("res/images/previousmusic.png", renderer, allocator, ANTERIOR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.3);
        const pauseImage = try Image.init("res/images/pausemusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.4);
        const resumeImage = try Image.init("res/images/playmusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA, 0.3);

        return .{
            .goBackImg = backTexture,
            .btManager = bluetooth,
            .nextMusicImg = nextImage,
            .prevMusicImg = prevImage,
            .pauseMusicImg = pauseImage,
            .lastTimeSeconds = 0.0,
            .allocator = allocator,
            .resumeMusicImg = resumeImage,
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
        self.resumeMusicImg.deinit();

        self.deinitMusicInfo();
    }

    pub fn deinitMusicInfo(self: *MusicScene) void {
        if (self.musicText) |*t| {
            t.deinit();
            self.musicText = null;
        }
        if (self.progress) |*p| {
            p.deinit();
            self.progress = null;
        }
    }

    pub fn update(self: *MusicScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = active;

        self.lastTimeSeconds += delta_time;
        if (self.lastTimeSeconds >= 0.5) {
            self.lastTimeSeconds = 0;

            self.trackInfo = .{};
            self.btManager.getTrackInfo(&self.trackInfo.?) catch |err| {
                std.debug.print("Erro ao obter informações da música: {}\n", .{err});
                return;
            };

            if (self.trackInfo) |trackInfo| {
                var title_buf: [256]u8 = undefined;
                var progress_buf: [32]u8 = undefined;

                const progress_z = trackInfo.getPositionFormatted(&progress_buf);
                const title_z = std.fmt.bufPrintZ(&title_buf, "{s}", .{trackInfo.getTitle()}) catch return;

                self.deinitMusicInfo();

                self.musicText = Text.init(title_z.ptr, renderer, self.allocator, TAMANHO_FONTE_TITULO, BRANCO, LARGURA_TELA / 2, ALTURA_TELA / 2 - 50) catch |err| {
                    std.debug.print("Erro: {}\n", .{err});
                    return;
                };
                self.progress = Text.init(progress_z.ptr, renderer, self.allocator, TAMANHO_FONTE_TITULO, BRANCO, LARGURA_TELA / 2, ALTURA_TELA / 2 + 50) catch |err| {
                    std.debug.print("Erro: {}\n", .{err});
                    self.musicText.?.deinit();
                    self.musicText = null;
                    return;
                };

                std.debug.print("\nTítulo: {s}\n", .{trackInfo.getTitle()});
                std.debug.print("Artista: {s}\n", .{trackInfo.getArtist()});
                std.debug.print("Duração: {}ms\n", .{trackInfo.duration});
                std.debug.print("ta tocando?: {}\n", .{trackInfo.playing});
                std.debug.print("Progresso: {s}\n", .{
                    trackInfo.getPositionFormatted(&progress_buf),
                });
                std.debug.print("Progresso: {}%\n", .{trackInfo.getProgressPercent()});
            }
        }
    }

    pub fn render(self: *MusicScene, renderer: *sdl.SDL_Renderer) void {
        _ = renderer;

        self.pageName.render();
        self.goBackImg.render();

        if (self.trackInfo) |trackInfo| {
            self.nextMusicImg.render();
            self.prevMusicImg.render();

            if (self.musicText) |musicText| {
                musicText.render();
            }

            if (trackInfo.isPlaying() == true) {
                self.pauseMusicImg.render();
            } else {
                self.resumeMusicImg.render();
            }

            if (self.progress) |progressText| {
                progressText.render();
            }
        }
    }

    pub fn handleEvent(self: *MusicScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const x = event.button.x;
                const y = event.button.y;

                if (self.goBackImg.hasBeenClicked(x, y)) {
                    sManager.setScene(sManager.homeScene) catch |err| std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                }

                if (self.trackInfo) |trackInfo| {
                    if (self.pauseMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.pauseMusic() catch |err| std.debug.print("Erro ao pausar música: {}\n", .{err});
                    } else if (self.nextMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.nextMusic() catch |err| std.debug.print("Erro ao passar a música: {}\n", .{err});
                    } else if (self.prevMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.previousMusic() catch |err| std.debug.print("Erro ao voltar na música anterior: {}\n", .{err});
                    }

                    if (trackInfo.isPlaying() == true and self.pauseMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.pauseMusic() catch |err| std.debug.print("Erro ao pausar música: {}\n", .{err});
                    } else if (self.resumeMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.unpauseMusic() catch |err| std.debug.print("Erro ao despausar a música: {}\n", .{err});
                    }
                }
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *MusicScene) void {
        _ = self;
    }

    pub fn inOfFocus(self: *MusicScene) void {
        self.lastTimeSeconds = 5.0;
        self.btManager.getMusicPlayer() catch |err| {
            std.debug.print("Erro ao pausar música: {}\n", .{err});
            return;
        };
    }
};
