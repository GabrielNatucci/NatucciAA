const ArrayList = std.array_list.Managed;

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const WIDTH_RES = @import("../../main.zig").WIDTH;
const HEIGHT_RES = @import("../../main.zig").HEIGHT;
const DEVICE_BOX_LENGTH: c_int = 600;
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const Device = @import("../bluetooth/Device.zig").Device;
const SceneManager = @import("../SceneManager.zig").SceneManager;
const Scene = @import("Scene.zig");
const Text = @import("./components/Text.zig").Text;

const WHITE: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

const std = @import("std");
const backButtonDest: sdl.SDL_Rect = .{ .x = 10, .y = 0, .w = 70, .h = 70 };
const devicesX: c_int = 355;
const deviceColor: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

const bordaX: c_int = 200;
const bordaY: c_int = 150;
const bordaWidth: c_int = WIDTH_RES - (bordaX * 2);
const bordaHeight: c_int = HEIGHT_RES - (bordaY * 2);

pub const BluetoothScene = struct {
    fonteBluetooth: ?*sdl.TTF_Font,
    goBackTexture: *sdl.SDL_Texture,
    pageName: Text,
    connectedTexture: *sdl.SDL_Texture,
    btManager: *bt.BluetoothManager,
    lastTimeSeconds: f32,
    devicesText: ?ArrayList(Text),
    allocator: std.mem.Allocator,
    selectedDevice: ?*Device,

    pub fn create(
        renderer: *sdl.SDL_Renderer,
        bluetooth: *bt.BluetoothManager,
        allocator: std.mem.Allocator,
    ) !BluetoothScene {
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
        const bluetoothConnecetTexture = try textureUtil.loadSDLTexture(renderer, "res/images/btIcon.png");

        const textX = @divTrunc(WIDTH_RES, 2);
        const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };
        const pageNameTemp: Text = try Text.init("Bluetooth", renderer, allocator, 32, color, textX, 10);

        return .{
            .fonteBluetooth = fonte,
            .goBackTexture = backTexture,
            .connectedTexture = bluetoothConnecetTexture,
            .btManager = bluetooth,
            .lastTimeSeconds = 0,
            .devicesText = null,
            .allocator = allocator,
            .selectedDevice = null,
            .pageName = pageNameTemp,
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

        if (self.btManager.connected.load(.seq_cst) == true) {
            self.selectedDevice = null;
        }
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

            var yPosIndex: u16 = 154;

            if (self.btManager.devices.items.len >= 0) {
                self.deinitDevicesTextureSurface();

                self.devicesText = ArrayList(Text).init(self.allocator);

                for (self.btManager.devices.items) |value| {
                    // self.btManager.printDeviceInfo(&value); // borked
                    yPosIndex += 47;

                    const textX = devicesX + @divTrunc(DEVICE_BOX_LENGTH, 2);
                    const pageNameTemp: Text = Text.init(value.name.items.ptr, renderer, self.allocator, 32, WHITE, textX, yPosIndex) catch |err| {
                        std.debug.print("Erro ao criar texto de device: {}", .{err});
                        return;
                    };

                    self.devicesText.?.append(pageNameTemp) catch |err| {
                        std.debug.print("Erro ao dar append DEVICES TEXT: {}\n", .{err});
                        return;
                    };
                }
            }
        }
    }

    pub fn render(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        if (self.selectedDevice == null) {
            self.renderDevices(renderer);
        } else if (self.btManager.connected.load(.seq_cst) == false and self.btManager.connecting.load(.seq_cst) == false) {
            self.renderDevicePairing(renderer);
        } else if (self.btManager.connecting.load(.seq_cst) == true) {
            self.renderDeviceConnecting(renderer);
        }

        self.renderBoilerplate(renderer);
    }

    fn renderDevices(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        var yPosIndex: u16 = 200;

        if (self.devicesText.?.items.len >= 0) {
            for (0..self.devicesText.?.items.len) |i| {
                const deviceText: Text = self.devicesText.?.items[i];

                // TEXTO
                deviceText.render();

                const height: c_int = deviceText.height;

                // BORDA
                _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
                var deviceDest: sdl.SDL_Rect = .{ .x = devicesX - 15, .y = yPosIndex - 5, .w = DEVICE_BOX_LENGTH, .h = height + 10 };
                _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);

                yPosIndex += 47;

                if (self.btManager.devices.items[i].connected) {
                    var connectedTextDest: sdl.SDL_Rect = .{ .x = devicesX + DEVICE_BOX_LENGTH - 60, .y = yPosIndex - height - 8, .w = height, .h = height };
                    _ = sdl.SDL_RenderCopy(renderer, self.connectedTexture, null, &connectedTextDest);
                }
            }
        }
    }

    fn renderDevicePairing(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        // BORDA
        const color: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

        var deviceDest: sdl.SDL_Rect = .{
            .x = bordaX,
            .y = bordaY,
            .w = bordaWidth,
            .h = bordaHeight,
        };
        _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);

        const deviceX: c_int = bordaX + @divTrunc(bordaWidth, 2);
        const deviceY: c_int = bordaY + 10;

        const deviceName: Text = Text.init(self.selectedDevice.?.name.items.ptr, renderer, self.allocator, 32, WHITE, deviceX, deviceY) catch |err| {
            std.debug.print("Erro ao criar texto de device: {}", .{err});
            return;
        };

        deviceName.render();
        defer deviceName.deinit();

        const querConectarText = sdl.TTF_RenderText_Blended(self.fonteBluetooth, "Deseja se conectar a esse dispositivo?", color) orelse return;
        defer sdl.SDL_FreeSurface(querConectarText);

        const querConectarTexture = sdl.SDL_CreateTextureFromSurface(renderer, querConectarText) orelse return;
        defer sdl.SDL_DestroyTexture(querConectarTexture);

        const querConectarWidth: c_int = querConectarText.*.w;
        const querConectarHeight: c_int = querConectarText.*.h;

        const querConectarX: c_int = bordaX + @divTrunc(bordaWidth, 2) - @divTrunc(querConectarWidth, 2);
        const querConectarY: c_int = bordaY + @divTrunc(bordaHeight, 2) - @divTrunc(querConectarHeight, 2);

        var querConectarDest: sdl.SDL_Rect = .{
            .x = querConectarX,
            .y = querConectarY,
            .w = querConectarWidth,
            .h = querConectarHeight,
        };

        _ = sdl.SDL_RenderCopy(renderer, querConectarTexture, null, &querConectarDest);

        const simText = sdl.TTF_RenderText_Blended(self.fonteBluetooth, "Sim", color) orelse return;
        const naoText = sdl.TTF_RenderText_Blended(self.fonteBluetooth, "Nao", color) orelse return;
        defer sdl.SDL_FreeSurface(simText);
        defer sdl.SDL_FreeSurface(naoText);

        const simTexture = sdl.SDL_CreateTextureFromSurface(renderer, simText) orelse return;
        const naoTexture = sdl.SDL_CreateTextureFromSurface(renderer, naoText) orelse return;
        defer sdl.SDL_DestroyTexture(simTexture);
        defer sdl.SDL_DestroyTexture(naoTexture);

        const simWidth: c_int = simText.*.w;
        const simHeight: c_int = simText.*.h;

        const simX: c_int = bordaX + @divTrunc(bordaWidth, 4) + @divTrunc(bordaWidth, 2) - @divTrunc(simWidth, 2);
        const simY: c_int = (bordaY + bordaHeight) - 50 - (@divTrunc(simHeight, 2));

        var simDest: sdl.SDL_Rect = .{
            .x = simX,
            .y = simY,
            .w = simWidth,
            .h = simHeight,
        };

        _ = sdl.SDL_RenderCopy(renderer, simTexture, null, &simDest);

        const naoWidth: c_int = naoText.*.w;
        const naoHeight: c_int = naoText.*.h;

        const naoX: c_int = bordaX + @divTrunc(bordaWidth, 4) - @divTrunc(naoWidth, 2);
        const naoY: c_int = (bordaY + bordaHeight) - 50 - (@divTrunc(naoHeight, 2));

        var naoDest: sdl.SDL_Rect = .{
            .x = naoX,
            .y = naoY,
            .w = naoWidth,
            .h = naoHeight,
        };

        _ = sdl.SDL_RenderCopy(renderer, naoTexture, null, &naoDest);
    }

    fn renderDeviceConnecting(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        _ = self;

        var deviceDest: sdl.SDL_Rect = .{
            .x = bordaX,
            .y = bordaY,
            .w = bordaWidth,
            .h = bordaHeight,
        };
        _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);
    }

    // isso aqui é pra renderizar as coisas que sempre vão aparecer, botão de voltar e o nome da cena
    fn renderBoilerplate(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        self.pageName.render();

        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &backButtonDest);
    }

    pub fn handleEvent(self: *BluetoothScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                if (self.selectedDevice == null) {
                    const isBackbuttonHeight: bool = mouseY > backButtonDest.y and mouseY < backButtonDest.y + backButtonDest.h;
                    const isBackbuttonWidth: bool = mouseX > backButtonDest.x and mouseX < backButtonDest.x + backButtonDest.w;

                    if (isBackbuttonHeight and isBackbuttonWidth) {
                        sManager.setScene(sManager.homeScene) catch |err| {
                            std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                            return;
                        };
                    } else if (self.devicesText.?.items.len >= 0) {
                        var yPosIndex: u16 = 200;
                        for (0..self.devicesText.?.items.len) |i| {
                            const text: Text = self.devicesText.?.items[i];
                            const height: c_int = text.height;

                            if (mouseY > yPosIndex - 5 and mouseY < height + 10 + yPosIndex and mouseX > devicesX - 15 and mouseX < devicesX - 15 + DEVICE_BOX_LENGTH) {
                                self.selectedDevice = &self.btManager.devices.items[i];

                                if (self.selectedDevice.?.connected) {
                                    self.btManager.disconnectDevice(self.selectedDevice.?) catch |err| {
                                        std.debug.print("Erro ao desconectar dispositivo: {}\n", .{err});
                                        return;
                                    };

                                    self.selectedDevice = null;
                                }

                                break;
                            }

                            yPosIndex += 47;
                        }
                    }
                } else {
                    const simWidth: c_int = 55;
                    const simHeight: c_int = 38;
                    const simX: c_int = bordaX + @divTrunc(bordaWidth, 4) + @divTrunc(bordaWidth, 2) - @divTrunc(simWidth, 2);
                    const simY: c_int = (bordaY + bordaHeight) - 50 - (@divTrunc(simHeight, 2));

                    const naoWidth: c_int = 55;
                    const naoHeight: c_int = 38;
                    const naoX: c_int = bordaX + @divTrunc(bordaWidth, 4) - @divTrunc(naoWidth, 2);
                    const naoY: c_int = (bordaY + bordaHeight) - 50 - (@divTrunc(naoHeight, 2));

                    const isSim: bool = (mouseX >= simX and mouseX <= (simX + simWidth)) and (mouseY >= simY and mouseY <= (simY + simHeight));
                    const isNao: bool = (mouseX >= naoX and mouseX <= (naoX + naoWidth)) and (mouseY >= naoY and mouseY <= (naoY + naoHeight));

                    if (isSim) {
                        if (self.selectedDevice.?.paired == false) {
                            self.btManager.pairDevice(self.selectedDevice.?) catch |err| {
                                std.debug.print("Erro ao parear no dispositivo: {}", .{err});
                                return;
                            };

                            self.btManager.trustDevice(self.selectedDevice.?, false) catch |err| {
                                std.debug.print("Erro ao confiar no dispositivo: {}", .{err});
                                return;
                            };
                        }

                        self.btManager.connectDeviceAsync(self.selectedDevice.?) catch |err| {
                            std.debug.print("Erro ao conectar dispositivo: {}", .{err});
                            return;
                        };

                        // self.selectedDevice = null;
                    } else if (isNao) {
                        self.selectedDevice = null;
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
        self.selectedDevice = null;
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

        self.devicesText = ArrayList(Text).init(self.allocator);

        self.lastTimeSeconds = 100;
    }

    fn deinitDevicesTextureSurface(self: *BluetoothScene) void {
        if (self.devicesText) |*list| {
            for (list.items) |current| {
                current.deinit();
            }

            list.deinit();
            self.devicesText = null;
        }
    }

    pub fn deinit(self: *BluetoothScene) void {
        std.debug.print("Desligando bluetoothScene\n", .{});

        if (self.fonteBluetooth != null) {
            sdl.TTF_CloseFont(self.fonteBluetooth);
        }

        sdl.SDL_DestroyTexture(self.goBackTexture);
        sdl.SDL_DestroyTexture(self.connectedTexture);

        self.pageName.deinit();
        self.deinitDevicesTextureSurface();
    }
};
