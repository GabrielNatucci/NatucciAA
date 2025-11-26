const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");

pub const HomeScene = struct {
    fonteHorario: ?*sdl.TTF_Font,
    horario: ?[6]u8,

    pub fn create() !HomeScene {
        const fonte = sdl.TTF_OpenFont("res/font/Fenix-Regular.ttf", 300);

        if (fonte == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
            return error.FonteNaoCarregada;
        } else {
            std.debug.print("Fonte carregada", .{});
        }

        return .{
            .fonteHorario = fonte,
            .horario = null,
        };
    }

    pub fn init(self: *HomeScene) !void {
        _ = self;
        std.debug.print("Inicializando scene...\n", .{});
    }

    pub fn deinit(self: *HomeScene) void {
        if (self.fonteHorario) |fonte| {
            sdl.TTF_CloseFont(fonte);
        }

        std.debug.print("Limpando recursos\n", .{});
    }

    pub fn update(self: *HomeScene, delta_time: f32) void {
        _ = delta_time;
        self.horario = timeUtil.getCurrentTime();
    }

    pub fn render(self: *HomeScene, renderer: *sdl.SDL_Renderer) void {
        if (self.horario == null) return;

        const color: sdl.SDL_Color = .{ .a = 255, .b = 0, .g = 0, .r = 255 };

        const textSurface = sdl.TTF_RenderText_Blended(self.fonteHorario, &self.horario.?, color);
        if (textSurface == null) return;

        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) return;

        defer sdl.SDL_DestroyTexture(textTexture);

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;

        var destination: sdl.SDL_Rect = .{ .x = 20, .y = 20, .w = width, .h = height };

        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        _ = sdl.SDL_RenderDrawRect(renderer, &destination);
        _ = sdl.SDL_RenderCopy(renderer, textTexture, null, &destination);
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
