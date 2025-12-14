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
    lastTimeSeconds: f32,

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

        return .{
            .fonteBluetooth = fonte,
            .goBackTexture = backTexture,
            .btManager = bluetooth,
            .lastTimeSeconds = 0,
        };
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
        _ = renderer;
        _ = active;
        self.lastTimeSeconds += delta_time;

        self.btManager.startDiscovery() catch |err| {
            std.debug.print("Erro ao startDiscovery: {}\n", .{err});
            return;
        };

        // para listar os dispositivos a cada dois segundos..
        // sem isso aqui dá merda!!
        if (self.lastTimeSeconds >= 2.0) {
            self.lastTimeSeconds = 0;

            self.btManager.listDevices() catch |err| {
                std.debug.print("Erro ao ListDevices: {}\n", .{err});
                return;
            };

            if (self.btManager.devices.items.len >= 0) {
                std.debug.print("\n===================================\n", .{});
                std.debug.print("=====Dispositivos encontrados:=====\n", .{});
                std.debug.print("===================================\n", .{});
                for (self.btManager.devices.items) |value| {
                    std.debug.print("Nome?: {s}\n", .{value.name.items});
                }
                std.debug.print("\n", .{});
            }
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

    pub fn outOfFocus(self: *BluetoothScene) void {
        self.btManager.stopDiscovery() catch |err| {
            std.debug.print("Erro ao parar o discovery: {}", .{err});
            return;
        };
    }
};
