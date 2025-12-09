const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const textureUtil = @import("../../util/SDLTextureUtil.zig");

pub const HomeScene = struct {
    fonteHorario: ?*sdl.TTF_Font,
    horario: ?[6]u8,
    horarioTexture: ?*sdl.SDL_Texture,
    horarioDest: ?sdl.SDL_Rect,

    androidAutoDest: ?sdl.SDL_Rect,
    androidAutoTexture: *sdl.SDL_Texture,

    bluetoothDest: ?sdl.SDL_Rect,
    bluetoothTexture: *sdl.SDL_Texture,

    filesDest: ?sdl.SDL_Rect,
    filesTexture: *sdl.SDL_Texture,

    radioDest: ?sdl.SDL_Rect,
    radioTexture: *sdl.SDL_Texture,

    configDest: ?sdl.SDL_Rect,
    configTexture: *sdl.SDL_Texture,

    pub fn create(iconsLen: c_int, aaXPos: c_int, btXPos: c_int, fileXPos: c_int, cfgXPos: c_int, radXPos: c_int, buttonheight: c_int, renderer: *sdl.SDL_Renderer) !HomeScene {
        std.debug.print("\nInicializando homeScene...\n", .{});

        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", 250);

        if (fonte == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
            return error.FonteNaoCarregada;
        } else {
            std.debug.print("Fonte da home carregada\n", .{});
            sdl.TTF_SetFontStyle(fonte, sdl.TTF_STYLE_NORMAL);
        }

        const aaDest: ?sdl.SDL_Rect = .{ .x = aaXPos, .y = buttonheight, .w = iconsLen, .h = iconsLen };
        const btDest: ?sdl.SDL_Rect = .{ .x = btXPos, .y = buttonheight, .w = iconsLen, .h = iconsLen };
        const filesDest: ?sdl.SDL_Rect = .{ .x = fileXPos, .y = buttonheight, .w = iconsLen, .h = iconsLen };
        const cfgDest: ?sdl.SDL_Rect = .{ .x = cfgXPos, .y = buttonheight, .w = iconsLen, .h = iconsLen };
        const radDest: ?sdl.SDL_Rect = .{ .x = radXPos, .y = buttonheight, .w = iconsLen, .h = iconsLen };

        const cfgTexture = try textureUtil.loadSDLTexture(renderer, "res/images/configIcon.png");
        const radTexture = try textureUtil.loadSDLTexture(renderer, "res/images/radioIcon.png");
        const flTexture = try textureUtil.loadSDLTexture(renderer, "res/images/fileIcon.png");
        const aaTexture = try textureUtil.loadSDLTexture(renderer, "res/images/aaIcon.png");
        const btTexture = try textureUtil.loadSDLTexture(renderer, "res/images/btIcon.png");

        return .{
            .fonteHorario = fonte,
            .horarioTexture = null,
            .horario = null,
            .androidAutoDest = aaDest,
            .bluetoothDest = btDest,
            .filesDest = filesDest,
            .configDest = cfgDest,
            .radioDest = radDest,
            .radioTexture = radTexture,
            .configTexture = cfgTexture,
            .filesTexture = flTexture,
            .androidAutoTexture = aaTexture,
            .bluetoothTexture = btTexture,
            .horarioDest = null
        };
    }

    pub fn init(self: *HomeScene) !void {
        _ = self;
        std.debug.print("Inicializando homeScene... (init)\n", .{});
    }

    pub fn deinit(self: *HomeScene) void {
        if (self.fonteHorario != null) {
            sdl.TTF_CloseFont(self.fonteHorario);
        }

        if (self.horarioTexture != null) {
            sdl.SDL_DestroyTexture(self.horarioTexture);
        }

        sdl.SDL_DestroyTexture(self.configTexture);
        sdl.SDL_DestroyTexture(self.radioTexture);
        sdl.SDL_DestroyTexture(self.bluetoothTexture);
        sdl.SDL_DestroyTexture(self.androidAutoTexture);
        sdl.SDL_DestroyTexture(self.filesTexture);

        std.debug.print("Desligando homeScene\n", .{});
    }

    pub fn update(self: *HomeScene, delta_time: f32, renderer: *sdl.SDL_Renderer) void {
        _ = delta_time;
        const currentTime = timeUtil.getCurrentTime();

        if (self.horario == null or std.mem.eql(u8, &self.horario.?, &currentTime) == false) {
            std.debug.print("atualizando horário\n", .{});
            self.horario = timeUtil.getCurrentTime();

            if (self.horarioTexture != null) {
                sdl.SDL_DestroyTexture(self.horarioTexture);
            }

            const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };
            const textSurface = sdl.TTF_RenderText_Blended(self.fonteHorario, &self.horario.?, color);
            defer sdl.SDL_FreeSurface(textSurface);

            if (textSurface == null) {
                std.debug.print("Erro ao criar surface de fonte: {s}\n", .{sdl.TTF_GetError()});
                return;
            }

            const width: c_int = textSurface.*.w;
            const height: c_int = textSurface.*.h;

            self.horarioDest = .{ .x = 70, .y = 100, .w = width, .h = height };
            self.horarioTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        }
    }

    pub fn render(self: *HomeScene, renderer: *sdl.SDL_Renderer) void {
        if (self.horario == null) return;

        _ = sdl.SDL_RenderCopy(renderer, self.horarioTexture, null, &self.horarioDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.androidAutoTexture, null, &self.androidAutoDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.bluetoothTexture, null, &self.bluetoothDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.filesTexture, null, &self.filesDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.radioTexture, null, &self.radioDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.configTexture, null, &self.configDest.?);
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
