const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const Scene = @import("Scene.zig");
const SceneManager = @import("../SceneManager.zig").SceneManager;
const timeUtil = @import("../../util/TimeUtil.zig");
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const ArrayList = std.array_list.Managed;
const Device = @import("../bluetooth/Device.zig").Device;
const bt = @import("../../core/bluetooth/BluetoothManager.zig");

const backButtonDest: sdl.SDL_Rect = .{ .x = 10, .y = 0, .w = 70, .h = 70 };
const xOrigin: c_int = 355;
const deviceColor: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

pub const BluetoothScene = struct {
    fonteBluetooth: ?*sdl.TTF_Font,
    goBackTexture: *sdl.SDL_Texture,
    btManager: *bt.BluetoothManager,
    lastTimeSeconds: f32,
    devicesTex: ?ArrayList(*sdl.SDL_Texture),
    devicesSur: ?ArrayList(*sdl.SDL_Surface),
    allocator: std.mem.Allocator,
    selectedDevice: ?*Device,

    pub fn create(renderer: *sdl.SDL_Renderer, bluetooth: *bt.BluetoothManager, allocator: std.mem.Allocator) !BluetoothScene {
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
            .devicesTex = null,
            .devicesSur = null,
            .allocator = allocator,
            .selectedDevice = null,
        };
    }

    pub fn init(self: *BluetoothScene) !void {
        _ = self;
        std.debug.print("Inicializando bluetoothScene... (init)\n", .{});
    }

    pub fn update(self: *BluetoothScene, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
        _ = active;
        self.lastTimeSeconds += delta_time;
        self.listarDispositivos(renderer);
    }

    fn listarDispositivos(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        // para listar os dispositivos a cada dois segundos..
        // sem isso aqui dá merda!!
        if (self.lastTimeSeconds >= 3.0 and self.selectedDevice == null) {
            self.lastTimeSeconds = 0;

            self.btManager.listDevices() catch |err| {
                std.debug.print("Erro ao ListDevices: {}\n", .{err});
                return;
            };

            if (self.btManager.devices.items.len >= 0) {
                self.deinitDevicesTextureSurface();

                self.devicesTex = ArrayList(*sdl.SDL_Texture).init(self.allocator);
                self.devicesSur = ArrayList(*sdl.SDL_Surface).init(self.allocator);

                for (self.btManager.devices.items) |value| {
                    const textSurface = sdl.TTF_RenderText_Blended(self.fonteBluetooth, value.name.items.ptr, deviceColor);
                    const textTexture = sdl.SDL_CreateTextureFromSurface(renderer, textSurface);

                    if (textSurface == null) return;
                    if (textTexture == null) return;

                    self.devicesTex.?.append(textTexture.?) catch |err| {
                        std.debug.print("Erro ao dar append DEVICES TEXTURE: {}\n", .{err});
                        return;
                    };

                    self.devicesSur.?.append(textSurface.?) catch |err| {
                        std.debug.print("Erro ao dar append DEVICES SURFACE: {}\n", .{err});
                        return;
                    };
                }
            }
        }
    }

    pub fn render(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        if (self.selectedDevice == null) {
            self.renderDevices(renderer);
        } else {
            self.renderDevicePairing(renderer);
        }

        self.renderBoilerplate(renderer);
    }

    fn renderDevices(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        var yPosIndex: u16 = 200;

        if (self.devicesTex.?.items.len >= 0) {
            for (0..self.devicesTex.?.items.len) |i| {
                const textSurface: *sdl.SDL_Surface = self.devicesSur.?.items[i];
                const textTexture: *sdl.SDL_Texture = self.devicesTex.?.items[i];

                const width: c_int = textSurface.*.w;
                const height: c_int = textSurface.*.h;

                var bluetoothDest: sdl.SDL_Rect = .{ .x = xOrigin, .y = yPosIndex, .w = width, .h = height };

                // TEXTO
                _ = sdl.SDL_RenderCopy(renderer, textTexture, null, &bluetoothDest);
                _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

                // BORDA
                var deviceDest: sdl.SDL_Rect = .{ .x = xOrigin - 15, .y = yPosIndex - 5, .w = 600, .h = textSurface.*.h + 10 };
                _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);

                yPosIndex += 47;
            }
        }
    }

    fn renderDevicePairing(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        _ = self;

        // BORDA
        var deviceDest: sdl.SDL_Rect = .{ .x = 200, .y = 150, .w = 880, .h = 420 };
        _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);

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
        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &backButtonDest);
    }

    pub fn handleEvent(self: *BluetoothScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                const isBackbuttonHeight: bool = mouseY > backButtonDest.y and mouseY < backButtonDest.y + backButtonDest.h;
                const isBackbuttonWidth: bool = mouseX > backButtonDest.x and mouseX < backButtonDest.x + backButtonDest.w;

                if (isBackbuttonHeight and isBackbuttonWidth) {
                    sManager.setScene(sManager.homeScene) catch |err| {
                        std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                        return;
                    };
                } else if (self.devicesTex.?.items.len >= 0) {
                    var yPosIndex: u16 = 200;
                    for (0..self.devicesTex.?.items.len) |i| {
                        const textSurface: *sdl.SDL_Surface = self.devicesSur.?.items[i];
                        const height: c_int = textSurface.*.h;

                        if (mouseY > yPosIndex - 5 and mouseY < height + 10 + yPosIndex and mouseX > xOrigin - 15 and mouseX < xOrigin - 15 + 600) {
                            self.selectedDevice = &self.btManager.devices.items[i];

                            break;
                        }

                        yPosIndex += 47;
                    }
                }
            },
            else => {},
        }
    }

    pub fn outOfFocus(self: *BluetoothScene) void {
        self.btManager.stopDiscovery() catch |err| {
            std.debug.print("Erro ao parar o discovery: {}", .{err});
            return;
        };

        self.deinitDevicesTextureSurface();
    }

    pub fn inOfFocus(self: *BluetoothScene) void {
        self.btManager.startDiscovery() catch |err| {
            std.debug.print("Erro ao startDiscovery: {}\n", .{err});
            return;
        };

        self.btManager.listDevices() catch |err| {
            std.debug.print("Erro ao ListDevices: {}\n", .{err});
            return;
        };

        self.devicesTex = ArrayList(*sdl.SDL_Texture).init(self.allocator);
        self.devicesSur = ArrayList(*sdl.SDL_Surface).init(self.allocator);
    }

    fn deinitDevicesTextureSurface(self: *BluetoothScene) void {
        if (self.devicesTex) |*list| {
            for (list.items) |current| {
                sdl.SDL_DestroyTexture(current);
            }

            list.deinit();
            self.devicesTex = null;
        }

        if (self.devicesSur) |*list| {
            for (list.items) |current| {
                sdl.SDL_FreeSurface(current);
            }

            list.deinit();
            self.devicesSur = null;
        }
    }

    pub fn deinit(self: *BluetoothScene) void {
        std.debug.print("Desligando bluetoothScene\n", .{});

        if (self.fonteBluetooth != null) {
            sdl.TTF_CloseFont(self.fonteBluetooth);
        }

        sdl.SDL_DestroyTexture(self.goBackTexture);

        self.deinitDevicesTextureSurface();
    }
};
