const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const bt = @import("../../core/bluetooth/BluetoothManager.zig");

pub const BluetoothScene = struct {
    fonteBluetooth: ?*sdl.TTF_Font,
    goBackTexture: *sdl.SDL_Texture,
    btManager: *bt.BluetoothManager,

    pub fn create(renderer: *sdl.SDL_Renderer, bluetooth: *bt.BluetoothManager) !BluetoothScene {
        std.debug.print("\nInicializando bluetoothScene...\n", .{});

        const fonte = sdl.TTF_OpenFont("res/font/Roboto-VariableFont_wdth,wght.ttf", 32);

        if (fonte == null) {
            std.debug.print("Erro ao carregar a fenix font -> {s}\n", .{sdl.TTF_GetError()});
            return error.FonteNaoCarregada;
        } else {
            std.debug.print("Fonte da bluetooth carregada\n", .{});
            sdl.TTF_SetFontStyle(fonte, sdl.TTF_STYLE_NORMAL);
        }

        const backTexture = try textureUtil.loadSDLTexture(renderer, "res/images/backButton.png");

        return .{ .fonteBluetooth = fonte, .goBackTexture = backTexture, .btManager = bluetooth };
    }

    pub fn init(self: *BluetoothScene) !void {
        _ = self;
        std.debug.print("Inicializando bluetoothScene... (init)\n", .{});
    }

    pub fn deinit(self: *BluetoothScene) void {
        std.debug.print("Desligando bluetoothScene\n", .{});

        if (self.fonteBluetooth != null) {
            sdl.TTF_CloseFont(self.fonteBluetooth);
        }

        sdl.SDL_DestroyTexture(self.goBackTexture);
    }

    pub fn update(self: *BluetoothScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = delta_time;
        _ = renderer;

        std.debug.print("Active?: {}\n", .{active});
        if (active == true) {
            self.btManager.startDiscovery() catch |err| {
                std.debug.print("Erro ao startDiscovery: {}\n", .{err});
                return;
            };

            // self.btManager.listDevices() catch |err| {
            //     std.debug.print("Erro ao listar devices: {}\n", .{err});
            //     return;
            // };
        } else {
            self.btManager.stopDiscovery() catch |err| {
                std.debug.print("Erro ao parar o discovery: {}", .{err});
                return;
            };
        }
    }

    pub fn render(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        renderBoilerplate(self, renderer);
    }

    fn renderBoilerplate(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

        const textSurface = sdl.TTF_RenderText_Blended(self.fonteBluetooth, "Bluetooth", color);
        if (textSurface == null) return;
        defer sdl.SDL_FreeSurface(textSurface);

        const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);
        if (textTexture == null) return;
        defer sdl.SDL_DestroyTexture(textTexture);

        const width: c_int = textSurface.*.w;
        const height: c_int = textSurface.*.h;

        var bluetoothDest: sdl.SDL_Rect = .{ .x = 565, .y = 10, .w = width, .h = height };
        _ = sdl.SDL_RenderCopy(renderer, textTexture, null, &bluetoothDest);
        var backDest: sdl.SDL_Rect = .{ .x = 10, .y = 0, .w = 70, .h = 70 };

        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &backDest);
    }

    pub fn handleEvent(self: *BluetoothScene, event: sdl.SDL_Event) void {
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
