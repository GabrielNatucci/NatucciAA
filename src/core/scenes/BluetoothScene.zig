const ArrayList = std.array_list.Managed;

const bt = @import("../../core/bluetooth/BluetoothManager.zig");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;
const textureUtil = @import("../../util/SDLTextureUtil.zig");
const timeUtil = @import("../../util/TimeUtil.zig");
const Device = @import("../bluetooth/Device.zig").Device;
const Loading = @import("./components/Loading.zig").Loading;
const SceneManager = @import("../SceneManager.zig").SceneManager;
const Scene = @import("Scene.zig");
const Text = @import("./components/Text.zig").Text;
const std = @import("std");

// Constantes de UI - Proporcionais à tela
const LARGURA_TELA = @import("../../main.zig").WIDTH;
const ALTURA_TELA = @import("../../main.zig").HEIGHT;
const BRANCO: sdl.SDL_Color = .{ .a = 255, .r = 255, .g = 255, .b = 255 };

// Fontes
const TAMANHO_FONTE_TITULO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.045); // Aprox. 32 para 720p
const TAMANHO_FONTE_TEXTO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.045);
const POSICAO_TITULO_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.04); // Aprox. 30 para 720p

// Botão de voltar (canto superior esquerdo)
const BOTAO_VOLTAR_LARGURA: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.1); // Aprox. 70 para 720p
const BOTAO_VOLTAR_ALTURA: c_int = BOTAO_VOLTAR_LARGURA;
const BOTAO_VOLTAR_MARGEM_X: c_int = @intFromFloat(@as(f32, LARGURA_TELA) * 0.008); // Aprox. 10 para 1280p
const BOTAO_VOLTAR_MARGEM_Y: c_int = 0;
const botaoVoltarRect: sdl.SDL_Rect = .{ .x = BOTAO_VOLTAR_MARGEM_X, .y = BOTAO_VOLTAR_MARGEM_Y, .w = BOTAO_VOLTAR_LARGURA, .h = BOTAO_VOLTAR_ALTURA };

// Lista de Dispositivos
const LARGURA_CAIXA_DISPOSITIVO: c_int = @divTrunc(LARGURA_TELA, 2); // 50% da largura da tela
const ESPACAMENTO_VERTICAL_DISPOSITIVO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.065); // Aprox. 47 para 720p
const POSICAO_INICIAL_LISTA_Y: c_int = @divTrunc(ALTURA_TELA, 4); // Começa a 25% da altura da tela
const POSICAO_INICIAL_LISTA_X: c_int = @divTrunc(LARGURA_TELA - LARGURA_CAIXA_DISPOSITIVO, 2); // Centralizado
const PADDING_VERTICAL_CAIXA_DISPOSITIVO: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.007); // Aprox. 5 para 720p
const PADDING_ICONE_CONECTADO: c_int = @intFromFloat(@as(f32, LARGURA_TELA) * 0.008); // Aprox. 10 para 1280p

// Modal de pareamento
const BORDA_MODAL_X: c_int = @divTrunc(LARGURA_TELA, 6); // Margem de 1/6 da largura da tela
const BORDA_MODAL_Y: c_int = @divTrunc(ALTURA_TELA, 5); // Margem de 1/5 da altura da tela
const LARGURA_MODAL: c_int = LARGURA_TELA - (BORDA_MODAL_X * 2);
const ALTURA_MODAL: c_int = ALTURA_TELA - (BORDA_MODAL_Y * 2);
const BOTAO_MODAL_MARGEM_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.07); // Aprox. 50 para 720p
const PADDING_MODAL_TITULO_Y: c_int = @intFromFloat(@as(f32, ALTURA_TELA) * 0.035); // Aprox. 25 para 720p
const modalRect: sdl.SDL_Rect = .{ .x = BORDA_MODAL_X, .y = BORDA_MODAL_Y, .w = LARGURA_MODAL, .h = ALTURA_MODAL };

// Loading no Modal
const TAMANHO_LOADING: c_int = @divTrunc(ALTURA_MODAL, 3); // Um terço da altura do modal, para um tamanho razoável
const LOADING_MODAL_X: c_int = BORDA_MODAL_X + @divTrunc(LARGURA_MODAL - TAMANHO_LOADING, 2); // Centraliza no eixo X
const LOADING_MODAL_Y: c_int = BORDA_MODAL_Y + @divTrunc(ALTURA_MODAL - TAMANHO_LOADING, 2); // Centraliza no eixo Y
const LOADING_MODAL_POS: sdl.SDL_Rect = .{ .x = LOADING_MODAL_X, .y = LOADING_MODAL_Y, .w = TAMANHO_LOADING, .h = TAMANHO_LOADING };

pub const BluetoothScene = struct {
    fonteBluetooth: ?*sdl.TTF_Font,
    goBackTexture: *sdl.SDL_Texture,
    pageName: Text,
    querConectarSim: Text,
    querConectarNao: Text,
    querConectarText: Text,
    connectedTexture: *sdl.SDL_Texture,
    btManager: *bt.BluetoothManager,
    lastTimeSeconds: f32,
    devicesText: ?ArrayList(Text),
    allocator: std.mem.Allocator,
    selectedDevice: ?*Device,
    modalParingLoading: Loading,

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
        const bluetoothConnecetTexture = try textureUtil.loadSDLTexture(renderer, "res/images/btIcon.png");

        const textX = @divTrunc(LARGURA_TELA, 2);
        const pageNameTemp: Text = try Text.init("Bluetooth", renderer, allocator, TAMANHO_FONTE_TITULO, BRANCO, textX, POSICAO_TITULO_Y);

        const simX: c_int = BORDA_MODAL_X + (@divTrunc(LARGURA_MODAL, 4) * 3);
        const simY: c_int = (BORDA_MODAL_Y + ALTURA_MODAL) - BOTAO_MODAL_MARGEM_Y;
        const naoX: c_int = BORDA_MODAL_X + @divTrunc(LARGURA_MODAL, 4);
        const naoY: c_int = (BORDA_MODAL_Y + ALTURA_MODAL) - BOTAO_MODAL_MARGEM_Y;

        const simText: Text = try Text.init("Sim", renderer, allocator, TAMANHO_FONTE_TEXTO, BRANCO, simX, simY);
        const naoText: Text = try Text.init("Nao", renderer, allocator, TAMANHO_FONTE_TEXTO, BRANCO, naoX, naoY);

        const querConectarX: c_int = BORDA_MODAL_X + @divTrunc(LARGURA_MODAL, 2);
        const querConectarY: c_int = BORDA_MODAL_Y + @divTrunc(ALTURA_MODAL, 2);
        const querConectarText: Text = try Text.init("Deseja se conectar a esse dispositivo?", renderer, allocator, TAMANHO_FONTE_TEXTO, BRANCO, querConectarX, querConectarY);

        const loading: Loading = try Loading.init(renderer, LOADING_MODAL_POS);

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
            .querConectarSim = simText,
            .querConectarNao = naoText,
            .modalParingLoading = loading,
            .querConectarText = querConectarText
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

            if (self.btManager.devices.items.len >= 0) {
                self.deinitDevicesTextureSurface();

                self.devicesText = ArrayList(Text).init(self.allocator);

                for (self.btManager.devices.items, 0..) |value, i| {
                    // self.btManager.printDeviceInfo(&value); // borked
                    const yPos = POSICAO_INICIAL_LISTA_Y + @as(c_int, @intCast(i)) * ESPACAMENTO_VERTICAL_DISPOSITIVO;

                    const textX = POSICAO_INICIAL_LISTA_X + @divTrunc(LARGURA_CAIXA_DISPOSITIVO, 2);
                    const deviceText: Text = Text.init(value.name.items.ptr, renderer, self.allocator, TAMANHO_FONTE_TEXTO, BRANCO, textX, yPos) catch |err| {
                        std.debug.print("Erro ao criar texto de device: {}", .{err});
                        return;
                    };

                    self.devicesText.?.append(deviceText) catch |err| {
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
        if (self.devicesText) |deviceTextList| {
            for (deviceTextList.items, 0..) |deviceText, i| {
                // TEXTO
                deviceText.render();

                // BORDA
                const alturaCaixa = deviceText.height + (PADDING_VERTICAL_CAIXA_DISPOSITIVO * 2);
                const yCaixa = deviceText.y - PADDING_VERTICAL_CAIXA_DISPOSITIVO;

                _ = sdl.SDL_SetRenderDrawColor(renderer, BRANCO.r, BRANCO.g, BRANCO.b, BRANCO.a);
                var deviceDest: sdl.SDL_Rect = .{
                    .x = POSICAO_INICIAL_LISTA_X,
                    .y = yCaixa,
                    .w = LARGURA_CAIXA_DISPOSITIVO,
                    .h = alturaCaixa,
                };
                _ = sdl.SDL_RenderDrawRect(renderer, &deviceDest);

                if (self.btManager.devices.items[i].connected) {
                    const alturaIcone = deviceText.height;
                    const iconeX = POSICAO_INICIAL_LISTA_X + LARGURA_CAIXA_DISPOSITIVO - alturaIcone - PADDING_ICONE_CONECTADO;
                    const iconeY = deviceText.y;
                    var connectedTextDest: sdl.SDL_Rect = .{ .x = iconeX, .y = iconeY, .w = alturaIcone, .h = alturaIcone };
                    _ = sdl.SDL_RenderCopy(renderer, self.connectedTexture, null, &connectedTextDest);
                }
            }
        }
    }

    fn renderDevicePairing(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        // BORDA
        _ = sdl.SDL_SetRenderDrawColor(renderer, BRANCO.r, BRANCO.g, BRANCO.b, BRANCO.a);
        _ = sdl.SDL_RenderDrawRect(renderer, &modalRect);

        // NOME DISPOSITIVO
        const deviceX: c_int = BORDA_MODAL_X + @divTrunc(LARGURA_MODAL, 2);
        const deviceY: c_int = BORDA_MODAL_Y + PADDING_MODAL_TITULO_Y;

        const deviceName: Text = Text.init(self.selectedDevice.?.name.items.ptr, renderer, self.allocator, TAMANHO_FONTE_TEXTO, BRANCO, deviceX, deviceY) catch |err| {
            std.debug.print("Erro ao criar texto de device: {}", .{err});
            return;
        };

        deviceName.render();
        defer deviceName.deinit();

        // QUER CONECTAR, SIM - NAO?
        self.querConectarSim.render();
        self.querConectarNao.render();
        self.querConectarText.render();
    }

    fn renderDeviceConnecting(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, BRANCO.r, BRANCO.g, BRANCO.b, BRANCO.a);
        _ = sdl.SDL_RenderDrawRect(renderer, &modalRect);

        self.modalParingLoading.renderLoading();
    }

    // isso aqui é pra renderizar as coisas que sempre vão aparecer, botão de voltar e o nome da cena
    fn renderBoilerplate(self: *BluetoothScene, renderer: *sdl.SDL_Renderer) void {
        self.pageName.render();

        _ = sdl.SDL_RenderCopy(renderer, self.goBackTexture, null, &botaoVoltarRect);
    }

    fn isClickInsideRect(self: *const BluetoothScene, mouseX: c_int, mouseY: c_int, rect: sdl.SDL_Rect) bool {
        _ = self;
        return mouseX >= rect.x and mouseX <= rect.x + rect.w and
            mouseY >= rect.y and mouseY <= rect.y + rect.h;
    }

    pub fn handleEvent(self: *BluetoothScene, sManager: *SceneManager, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONUP => {
                const mouseX = event.button.x;
                const mouseY = event.button.y;

                if (self.selectedDevice == null) {
                    if (self.isClickInsideRect(mouseX, mouseY, botaoVoltarRect)) {
                        sManager.setScene(sManager.homeScene) catch |err| {
                            std.debug.print("Erro ao trocar de cena: {}\n", .{err});
                            return;
                        };
                    } else if (self.devicesText) |deviceTextList| {
                        for (deviceTextList.items, 0..) |text, i| {
                            const alturaCaixa = text.height + (PADDING_VERTICAL_CAIXA_DISPOSITIVO * 2);
                            const yCaixa = text.y - PADDING_VERTICAL_CAIXA_DISPOSITIVO;
                            const deviceRect = sdl.SDL_Rect{
                                .x = POSICAO_INICIAL_LISTA_X,
                                .y = yCaixa,
                                .w = LARGURA_CAIXA_DISPOSITIVO,
                                .h = alturaCaixa,
                            };

                            if (self.isClickInsideRect(mouseX, mouseY, deviceRect)) {
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
                        }
                    }
                } else {
                    if (self.querConectarSim.hasBeenClicked(mouseX, mouseY)) {
                        self.btManager.connectDeviceAsync(self.selectedDevice.?) catch |err| {
                            std.debug.print("Erro ao conectar dispositivo: {}", .{err});
                            return;
                        };
                    } else if (self.querConectarNao.hasBeenClicked(mouseX, mouseY)) {
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
        self.querConectarSim.deinit();
        self.querConectarNao.deinit();
        self.querConectarText.deinit();
        self.modalParingLoading.deinit();
        self.deinitDevicesTextureSurface();
    }
};
