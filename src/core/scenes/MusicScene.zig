const std = @import("std");

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const LARGURA_TELA = @import("../../main.zig").WIDTH;
const ALTURA_TELA = @import("../../main.zig").HEIGHT;
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const TrackInfo = @import("./../bluetooth/Music/TrackInfo.zig").TrackInfo;
const Image = @import("./components/Image.zig").Image;
const Text = @import("./components/Text.zig").Text;
const SceneUtil = @import("./sceneUtil/SceneUtil.zig");
const Scene = @import("Scene.zig");

const BRANCO: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };
const CINZINHA: sdl.SDL_Color = .{ .a = 255, .r = 215, .g = 215, .b = 225 };
const CINZA: sdl.SDL_Color = .{ .a = 0, .r = 150, .g = 150, .b = 150 };
const TAMANHO_FONTE_TITULO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.045); // Aprox. 32 para 720p
const TAMANHO_FONTE_MUSICA: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.065); // Aprox. 32 para 720p
const TAMANHO_FONTE_ALBUM: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.030); // Aprox. 32 para 720p
const POSICAO_TITULO_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.04); // Aprox. 30 para 720p
const POSICAO_TITULO_X: c_int = @divTrunc(LARGURA_TELA, 2); // Aprox. 30 para 720p

const X_BOTAO_VOLTAR: c_int = @intFromFloat(@as(f32, LARGURA_TELA) * 0.04);
const Y_BOTAO_VOLTAR: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.05);

const ANTERIOR_MUSICA_BOTAO: c_int = 300;
const DISTANCIA_BOTOES_MUSICA: c_int = @divTrunc(LARGURA_TELA - (ANTERIOR_MUSICA_BOTAO * 2), 2);
const ALTURA_BOTOES_MUSICA_Y: c_int = 600;
const PAUSAR_MUSICA_BOTAO_X: c_int = ANTERIOR_MUSICA_BOTAO + DISTANCIA_BOTOES_MUSICA;
const PROXIMA_MUSICA_BOTAO: c_int = PAUSAR_MUSICA_BOTAO_X + DISTANCIA_BOTOES_MUSICA;

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
    artistText: ?Text = null,
    albumText: ?Text = null,
    progress: ?Text = null,
    trackInfo: ?TrackInfo = null,
    allocator: std.mem.Allocator,

    // Cava Visualizer
    cavaProcess: ?*std.process.Child = null,
    cavaThread: ?std.Thread = null,
    cavaBars: [64]u8 = [_]u8{0} ** 64,
    cavaMutex: std.Thread.Mutex = .{},
    cavaRunning: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    pub fn create(renderer: *sdl.SDL_Renderer, allocator: std.mem.Allocator, bluetooth: *bt.BluetoothManager) !MusicScene {
        std.debug.print("\nInicializando musicScene...\n", .{});

        const backTexture = try Image.init("res/images/backButton.png", renderer, allocator, X_BOTAO_VOLTAR, Y_BOTAO_VOLTAR, 0.3);
        const nextImage = try Image.init("res/images/nextmusic.png", renderer, allocator, PROXIMA_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA_Y, 0.3);
        const prevImage = try Image.init("res/images/previousmusic.png", renderer, allocator, ANTERIOR_MUSICA_BOTAO, ALTURA_BOTOES_MUSICA_Y, 0.3);
        const pauseImage = try Image.init("res/images/pausemusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO_X, ALTURA_BOTOES_MUSICA_Y, 0.4);
        const resumeImage = try Image.init("res/images/playmusic.png", renderer, allocator, PAUSAR_MUSICA_BOTAO_X, ALTURA_BOTOES_MUSICA_Y, 0.4);

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
                "Musicas",
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
        self.stopCava();

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

        if (self.artistText) |*p| {
            p.deinit();
            self.artistText = null;
        }

        if (self.albumText) |*p| {
            p.deinit();
            self.albumText = null;
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
                const title_z = self.allocator.dupeZ(u8, trackInfo.getTitle()) catch |err| {
                    std.debug.print("Erro ao converter título: {}", .{err});
                    return;
                };
                defer self.allocator.free(title_z);

                const artist_z = self.allocator.dupeZ(u8, trackInfo.getArtist()) catch |err| {
                    std.debug.print("Erro ao converter artista: {}", .{err});
                    return;
                };
                defer self.allocator.free(artist_z);

                const album_z = self.allocator.dupeZ(u8, trackInfo.getAlbum()) catch |err| {
                    std.debug.print("Erro ao converter álbum: {}", .{err});
                    return;
                };
                defer self.allocator.free(album_z);

                var progress_buf: [32]u8 = undefined;
                const progress_z = trackInfo.getPositionFormatted(&progress_buf);

                self.deinitMusicInfo();

                self.musicText = SceneUtil.createText(title_z, renderer, self.allocator, TAMANHO_FONTE_MUSICA, BRANCO, LARGURA_TELA / 2, ALTURA_TELA / 2 - 160);
                self.artistText = SceneUtil.createText(artist_z, renderer, self.allocator, TAMANHO_FONTE_TITULO, BRANCO, LARGURA_TELA / 2, ALTURA_TELA / 2 - 100);
                self.albumText = SceneUtil.createText(album_z, renderer, self.allocator, TAMANHO_FONTE_ALBUM, CINZINHA, LARGURA_TELA / 2, ALTURA_TELA / 2 - 50);

                self.progress = Text.init(progress_z, renderer, self.allocator, TAMANHO_FONTE_TITULO, BRANCO, LARGURA_TELA / 2, ALTURA_BOTOES_MUSICA_Y - 160) catch |err| {
                    std.debug.print("Erro: {}\n", .{err});
                    return;
                };
            }
        }
    }

    pub fn render(self: *MusicScene, renderer: *sdl.SDL_Renderer) void {
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

            if (self.artistText) |artistText| {
                artistText.render();
            }

            if (self.albumText) |albumText| {
                albumText.render();
            }

            const total_width = @divTrunc(@as(f32, LARGURA_TELA), 1.2);
            const start_x: c_int = @divTrunc(LARGURA_TELA - @as(c_int, @intFromFloat(total_width)), 2);
            const base_y: c_int = ALTURA_BOTOES_MUSICA_Y - 120;
            const progress_h: c_int = @divTrunc(ALTURA_TELA, 55);

            self.cavaMutex.lock();
            const bars = self.cavaBars;
            self.cavaMutex.unlock();

            const num_bars = 64;
            const bar_width_f: f32 = total_width / @as(f32, @floatFromInt(num_bars));

            _ = sdl.SDL_SetRenderDrawBlendMode(renderer, sdl.SDL_BLENDMODE_BLEND);

            for (bars, 0..) |val, i| {
                if (val == 0) continue;

                // A altura máxima que o visualizador pode crescer (ex: 80 pixels para cima)
                const height_f = (@as(f32, @floatFromInt(val)) / 100.0) * 80.0;
                const height = @as(c_int, @intFromFloat(height_f));

                const bar_x = start_x + @as(c_int, @intFromFloat(@as(f32, @floatFromInt(i)) * bar_width_f));
                const bar_w = @as(c_int, @intFromFloat(bar_width_f)) - 1; // -1 para um leve espaçamento

                const bar_rect = sdl.SDL_Rect{
                    .x = bar_x,
                    // Adicionamos a altura da barra base para que as barrinhas fiquem "coladas" na linha
                    .y = base_y - height + progress_h,
                    .w = if (bar_w > 0) bar_w else 1,
                    .h = height,
                };

                // Cor branca com opacidade reduzida
                _ = sdl.SDL_SetRenderDrawColor(renderer, BRANCO.r, BRANCO.g, BRANCO.b, 60);
                _ = sdl.SDL_RenderFillRect(renderer, &bar_rect);
            }

            _ = sdl.SDL_SetRenderDrawBlendMode(renderer, sdl.SDL_BLENDMODE_NONE);

            // --- Barra de Progresso Background ---
            _ = sdl.SDL_SetRenderDrawColor(renderer, CINZA.r, CINZA.g, CINZA.b, CINZA.a);
            var linhaDuracaoRect: sdl.SDL_Rect = .{
                .x = start_x,
                .y = base_y,
                .w = @as(c_int, @intFromFloat(total_width)),
                .h = progress_h,
            };
            _ = sdl.SDL_RenderDrawRect(renderer, &linhaDuracaoRect);
            _ = sdl.SDL_RenderFillRect(renderer, &linhaDuracaoRect);

            // --- Barra de Progresso Atual ---
            _ = sdl.SDL_SetRenderDrawColor(renderer, BRANCO.r, BRANCO.g, BRANCO.b, BRANCO.a);
            var linhaDuracaoProgressoRect: sdl.SDL_Rect = .{
                .x = start_x,
                .y = base_y,
                .w = @intFromFloat(total_width * (trackInfo.getProgressPercent() * 0.01)),
                .h = progress_h,
            };

            _ = sdl.SDL_RenderDrawRect(renderer, &linhaDuracaoProgressoRect);
            _ = sdl.SDL_RenderFillRect(renderer, &linhaDuracaoProgressoRect);
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
                    std.debug.print("\nTítulo: {s}\n", .{trackInfo.getTitle()});
                    std.debug.print("Artista: {s}\n", .{trackInfo.getArtist()});
                    std.debug.print("Duração: {}ms\n", .{trackInfo.duration});
                    std.debug.print("ta tocando?: {}\n", .{trackInfo.playing});
                    std.debug.print("Progresso: {}%\n", .{trackInfo.getProgressPercent()});

                    if (self.nextMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.nextMusic() catch |err| std.debug.print("Erro ao passar a música: {}\n", .{err});
                        return;
                    } else if (self.prevMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.previousMusic() catch |err| std.debug.print("Erro ao voltar na música anterior: {}\n", .{err});
                        return;
                    }

                    if (trackInfo.isPlaying() == true and self.pauseMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.pauseMusic() catch |err| std.debug.print("Erro ao pausar música: {}\n", .{err});
                        return;
                    } else if (trackInfo.isPlaying() == false and self.resumeMusicImg.hasBeenClicked(x, y)) {
                        self.btManager.unpauseMusic() catch |err| std.debug.print("Erro ao despausar a música: {}\n", .{err});
                        return;
                    }
                }
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *MusicScene) void {
        // _ = self;
        self.stopCava();
    }

    pub fn inOfFocus(self: *MusicScene) void {
        self.lastTimeSeconds = 5.0;
        self.btManager.getMusicPlayer() catch |err| {
            std.debug.print("Erro ao obter music player: {}\n", .{err});
            return;
        };

        self.startCava() catch |err| {
            std.debug.print("Não foi possível iniciar o cava: {}\n", .{err});
        };
    }

    pub fn startCava(self: *MusicScene) !void {
        const config =
            \\[general]
            \\bars = 64
            \\[output]
            \\method = raw
            \\channels = mono
            \\raw_target = /dev/stdout
            \\data_format = ascii
            \\ascii_max_range = 100
            \\
        ;
        var file = try std.fs.cwd().createFile("/tmp/cava_natucci.conf", .{});
        defer file.close();
        try file.writeAll(config);

        const argv = &[_][]const u8{ "cava", "-p", "/tmp/cava_natucci.conf" };
        var child = try self.allocator.create(std.process.Child);
        child.* = std.process.Child.init(argv, self.allocator);
        child.stdout_behavior = .Pipe;
        try child.spawn();

        self.cavaProcess = child;
        self.cavaRunning.store(true, .seq_cst);
        self.cavaThread = try std.Thread.spawn(.{}, cavaReaderThread, .{self});
    }

    pub fn stopCava(self: *MusicScene) void {
        if (self.cavaRunning.load(.seq_cst)) {
            self.cavaRunning.store(false, .seq_cst);
            if (self.cavaProcess) |process| {
                _ = process.kill() catch {};

                if (self.cavaThread) |*thread| {
                    thread.join();
                    self.cavaThread = null;
                }

                _ = process.wait() catch {};
                self.allocator.destroy(process);
                self.cavaProcess = null;
            }

            // Reseta as barras para 0
            self.cavaMutex.lock();
            self.cavaBars = [_]u8{0} ** 64;
            self.cavaMutex.unlock();
        }
    }
};

fn cavaReaderThread(self: *MusicScene) void {
    const stdout = self.cavaProcess.?.stdout orelse return;
    var buf: [4096]u8 = undefined;
    var buf_len: usize = 0;

    while (self.cavaRunning.load(.seq_cst)) {
        if (buf_len >= buf.len) buf_len = 0;

        const bytes_read = stdout.read(buf[buf_len..]) catch 0;
        if (bytes_read == 0) break; // EOF ou processo morto
        buf_len += bytes_read;

        while (true) {
            if (std.mem.indexOfScalar(u8, buf[0..buf_len], '\n')) |idx| {
                const line = buf[0..idx];
                var it = std.mem.splitScalar(u8, line, ';');
                var i: usize = 0;

                self.cavaMutex.lock();
                while (it.next()) |val_str| {
                    if (val_str.len == 0) continue;
                    if (i >= 64) break;
                    if (std.fmt.parseInt(u8, val_str, 10)) |val| {
                        self.cavaBars[i] = val;
                        i += 1;
                    } else |_| {}
                }
                self.cavaMutex.unlock();

                const remaining = buf_len - (idx + 1);
                std.mem.copyForwards(u8, buf[0..remaining], buf[idx + 1 .. buf_len]);
                buf_len = remaining;
            } else {
                break; // Precisa ler mais para completar uma linha
            }
        }
    }
}
