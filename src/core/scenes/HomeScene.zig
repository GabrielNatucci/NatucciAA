const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");

pub const HomeScene = struct {
    fonteHorario: ?*sdl.TTF_Font,
    horario: ?[6]u8,

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

    pub fn create(iconsLen: c_int, aaXPos: c_int, btXPos: c_int, fileXPos: c_int, cfgXPos: c_int, radXPos: c_int,  buttonheight: c_int, renderer: *sdl.SDL_Renderer) !HomeScene {
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

        // carregando textura de configuração
        const configSurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/configIcon.png");
        const cfgTexture = sdl.SDL_CreateTextureFromSurface(renderer, configSurface).?;
        sdl.SDL_FreeSurface(configSurface);

        const radioSurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/radioIcon.png");
        const radTexture = sdl.SDL_CreateTextureFromSurface(renderer, radioSurface).?;
        sdl.SDL_FreeSurface(radioSurface);

        const filesSurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/fileIcon.png");
        const flTexture = sdl.SDL_CreateTextureFromSurface(renderer, filesSurface).?;
        sdl.SDL_FreeSurface(filesSurface);

        const aaSurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/aaIcon.png");
        const aaTex = sdl.SDL_CreateTextureFromSurface(renderer, aaSurface).?;
        sdl.SDL_FreeSurface(aaSurface);

        const btsurface: ?*sdl.SDL_Surface = sdl.IMG_Load("res/images/btIcon.png");
        const btTexture = sdl.SDL_CreateTextureFromSurface(renderer, btsurface).?;
        sdl.SDL_FreeSurface(btsurface);

        return .{
            .fonteHorario = fonte,
            .horario = null,
            .androidAutoDest = aaDest,
            .bluetoothDest = btDest,
            .filesDest = filesDest,
            .configDest = cfgDest,
            .radioDest = radDest,
            .radioTexture = radTexture,
            .configTexture = cfgTexture,
            .filesTexture = flTexture,
            .androidAutoTexture = aaTex,
            .bluetoothTexture = btTexture
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

        sdl.SDL_DestroyTexture(self.configTexture);
        sdl.SDL_DestroyTexture(self.radioTexture);
        sdl.SDL_DestroyTexture(self.bluetoothTexture);
        sdl.SDL_DestroyTexture(self.androidAutoTexture);
        sdl.SDL_DestroyTexture(self.filesTexture);

        std.debug.print("Desligando homeScene\n", .{});
    }

    pub fn update(self: *HomeScene, delta_time: f32) void {
        _ = delta_time;
        self.horario = timeUtil.getCurrentTime();
    }

    pub fn render(self: *HomeScene, renderer: *sdl.SDL_Renderer) void {
        if (self.horario == null) return;

        const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

        const textSurface = sdl.TTF_RenderText_Blended(self.fonteHorario, &self.horario.?, color);
        if (textSurface == null) return;
        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) return;
        defer sdl.SDL_DestroyTexture(textTexture);

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;

        var clockDest: sdl.SDL_Rect = .{ .x = 70, .y = 100, .w = width, .h = height };

        _ = sdl.SDL_RenderCopy(renderer, textTexture, null, &clockDest);
        // _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 0);

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
