const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig").Scene;
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const textureUtil = @import("../../util/SDLTextureUtil.zig");

pub const iconsSize: c_int = 120;
pub const buttonsHeight: c_int = 500;
pub const aaXPos: c_int = 70;
pub const btXPos: c_int = 310;
pub const radXPos: c_int = 550;
pub const fileXPos: c_int = 790;
pub const cfgXPos: c_int = 1030;

pub const HomeScene = struct {
    fonteHorario: ?*sdl.TTF_Font = null,
    horario: ?[6]u8,
    horarioTexture: ?*sdl.SDL_Texture = null,
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

    pub fn create(renderer: *sdl.SDL_Renderer) !HomeScene {
        std.debug.print("\nInicializando homeScene...\n", .{});

        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", 250);

        if (fonte == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
            return error.FonteNaoCarregada;
        } else {
            std.debug.print("Fonte da home carregada\n", .{});
            sdl.TTF_SetFontStyle(fonte, sdl.TTF_STYLE_NORMAL);
        }

        const aaDest: ?sdl.SDL_Rect = .{ .x = aaXPos, .y = buttonsHeight, .w = iconsSize, .h = iconsSize };
        const btDest: ?sdl.SDL_Rect = .{ .x = btXPos, .y = buttonsHeight, .w = iconsSize, .h = iconsSize };
        const filesDest: ?sdl.SDL_Rect = .{ .x = fileXPos, .y = buttonsHeight, .w = iconsSize, .h = iconsSize };
        const cfgDest: ?sdl.SDL_Rect = .{ .x = cfgXPos, .y = buttonsHeight, .w = iconsSize, .h = iconsSize };
        const radDest: ?sdl.SDL_Rect = .{ .x = radXPos, .y = buttonsHeight, .w = iconsSize, .h = iconsSize };

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
            .horarioDest = null,
        };
    }

    pub fn init(self: *HomeScene) !void {
        _ = self;
        std.debug.print("Inicializando homeScene... (init)\n", .{});
    }

    pub fn update(self: *HomeScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = delta_time;
        _ = active;
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
        _ = sdl.SDL_RenderCopy(renderer, self.horarioTexture, null, &self.horarioDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.androidAutoTexture, null, &self.androidAutoDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.bluetoothTexture, null, &self.bluetoothDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.filesTexture, null, &self.filesDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.radioTexture, null, &self.radioDest.?);
        _ = sdl.SDL_RenderCopy(renderer, self.configTexture, null, &self.configDest.?);
    }

    pub fn handleEvent(self: *HomeScene, sManager: *SceneManager.SceneManager, event: *sdl.SDL_Event) void {
        _ = self;

        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                const isButtonHeight: bool = mouseY > buttonsHeight and mouseY < buttonsHeight + iconsSize;
                var scene: ?*Scene = null;

                if (mouseX > cfgXPos and mouseX < (cfgXPos + iconsSize) and isButtonHeight == true) {
                    scene = sManager.configScene;
                } else if (mouseX > btXPos and mouseX < (btXPos + iconsSize) and isButtonHeight == true) {
                    scene = sManager.btScene;
                }

                if (scene != null) {
                    sManager.setScene(scene.?) catch |err| {
                        std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                        return;
                    };
                }

                std.debug.print("Mouse pos X: {}, Y: {}\n", .{ mouseX, mouseY });
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *HomeScene) void {
        _ = self;
    }

    pub fn inOfFocus(self: *HomeScene) void {
        _ = self;
    }

    pub fn deinit(self: *HomeScene) void {
        if (self.fonteHorario) |font| {
            sdl.TTF_CloseFont(font);
            self.fonteHorario = null;
        }

        if (self.horarioTexture) |tex| {
            sdl.SDL_DestroyTexture(tex);
            self.horarioTexture = null;
        }

        sdl.SDL_DestroyTexture(self.configTexture);
        sdl.SDL_DestroyTexture(self.radioTexture);
        sdl.SDL_DestroyTexture(self.bluetoothTexture);
        sdl.SDL_DestroyTexture(self.androidAutoTexture);
        sdl.SDL_DestroyTexture(self.filesTexture);

        std.debug.print("Desligando homeScene\n", .{});
    }
};
