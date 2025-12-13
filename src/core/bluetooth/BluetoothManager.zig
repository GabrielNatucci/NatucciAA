const std = @import("std");
const c = @cImport({
    @cInclude("dbus/dbus.h");
});

pub const Device = struct {
    path: []const u8,
    address: []const u8,
    name: []const u8,
    paired: bool,
    connected: bool,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Device) void {
        self.allocator.free(self.path);
        self.allocator.free(self.address);
        self.allocator.free(self.name);
    }
};

pub const BluetoothEvent = union(enum) {
    device_found: Device,
    device_removed: []const u8, // path
    device_connected: []const u8,
    device_disconnected: []const u8,
    scan_started,
    scan_stopped,
    error_occurred: []const u8,
};

pub const BluetoothManager = struct {
    conn: *c.DBusConnection,
    allocator: std.mem.Allocator,
    scan_thread: ?std.Thread = null,
    should_stop: std.atomic.Value(bool),
    devices: std.ArrayList(Device),
    event_queue: std.ArrayList(BluetoothEvent),
    mutex: std.Thread.Mutex,

    pub fn init(allocator: std.mem.Allocator) !BluetoothManager {
        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const conn = c.dbus_bus_get(c.DBUS_BUS_SYSTEM, &err);
        if (c.dbus_error_is_set(&err) != 0) {
            std.log.err("Erro ao conectar D-Bus: {s}", .{err.message});
            return error.DBusConnectionFailed;
        }

        std.log.info("Conectado ao D-Bus com sucesso!", .{});
        return BluetoothManager{
            .conn = conn.?,
            .allocator = allocator,
            .should_stop = std.atomic.Value(bool).init(false),
            .devices = std.ArrayList(Device).init(allocator),
            .event_queue = std.ArrayList(BluetoothEvent).init(allocator),
            .mutex = std.Thread.Mutex{},
        };
    }

    pub fn deinit(self: *BluetoothManager) void {
        self.stopScanAsync();

        for (self.devices.items) |*device| {
            device.deinit();
        }
        self.devices.deinit();
        self.event_queue.deinit();

        c.dbus_connection_unref(self.conn);
    }

    /// Pegar próximo evento (chamar no loop principal SDL)
    pub fn pollEvent(self: *BluetoothManager) ?BluetoothEvent {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.event_queue.items.len > 0) {
            return self.event_queue.orderedRemove(0);
        }
        return null;
    }

    /// Ligar o adaptador Bluetooth
    pub fn powerOn(self: *BluetoothManager) !void {
        std.log.info("Ligando adaptador Bluetooth...", .{});
        try self.setProperty(
            "/org/bluez/hci0",
            "org.bluez.Adapter1",
            "Powered",
            true,
        );
    }

    /// Iniciar scan assíncrono
    pub fn startScanAsync(self: *BluetoothManager) !void {
        if (self.scan_thread != null) {
            std.log.warn("Scan já está rodando", .{});
            return;
        }

        self.should_stop.store(false, .seq_cst);

        // Registrar para receber sinais D-Bus
        try self.setupSignalMatch();

        // Iniciar scan
        try self.startDiscoverySync();

        // Criar thread para processar eventos D-Bus
        self.scan_thread = try std.Thread.spawn(.{}, scanThreadFn, .{self});

        self.pushEvent(.scan_started);
    }

    /// Parar scan assíncrono
    pub fn stopScanAsync(self: *BluetoothManager) void {
        if (self.scan_thread == null) return;

        self.should_stop.store(true, .seq_cst);

        if (self.scan_thread) |thread| {
            thread.join();
            self.scan_thread = null;
        }

        self.stopDiscoverySync() catch |err| {
            std.log.err("Erro ao parar discovery: {}", .{err});
        };

        self.pushEvent(.scan_stopped);
    }

    /// Thread que processa eventos D-Bus
    fn scanThreadFn(self: *BluetoothManager) void {
        while (!self.should_stop.load(.seq_cst)) {
            // Processar mensagens D-Bus não-bloqueante
            while (c.dbus_connection_read_write_dispatch(self.conn, 100) != 0) {
                if (self.should_stop.load(.seq_cst)) break;
            }
            std.time.sleep(std.time.ns_per_ms * 50); // 50ms
        }
    }

    /// Configurar match para receber sinais de dispositivos
    fn setupSignalMatch(self: *BluetoothManager) !void {
        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        // Match para InterfacesAdded (novo dispositivo)
        const match_added = "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded'";
        c.dbus_bus_add_match(self.conn, match_added, &err);

        if (c.dbus_error_is_set(&err) != 0) {
            return error.SignalMatchFailed;
        }

        // Match para PropertiesChanged (dispositivo conectou/desconectou)
        const match_props = "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'";
        c.dbus_bus_add_match(self.conn, match_props, &err);

        c.dbus_connection_flush(self.conn);
    }

    /// Versão síncrona do startDiscovery
    fn startDiscoverySync(self: *BluetoothManager) !void {
        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            "/org/bluez/hci0",
            "org.bluez.Adapter1",
            "StartDiscovery",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            std.log.err("Erro ao iniciar discovery: {s}", .{err.message});
            return error.DiscoveryFailed;
        }

        if (reply) |r| c.dbus_message_unref(r);
    }

    fn stopDiscoverySync(self: *BluetoothManager) !void {
        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            "/org/bluez/hci0",
            "org.bluez.Adapter1",
            "StopDiscovery",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            &err,
        );

        if (reply) |r| c.dbus_message_unref(r);
    }

    /// Adicionar evento na fila (thread-safe)
    fn pushEvent(self: *BluetoothManager, event: BluetoothEvent) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.event_queue.append(event) catch |err| {
            std.log.err("Erro ao adicionar evento: {}", .{err});
        };
    }

    /// Parear com um dispositivo (não-bloqueante via thread)
    pub fn pairAsync(self: *BluetoothManager, device_path: []const u8) !void {
        const path_copy = try self.allocator.dupe(u8, device_path);
        const thread = try std.Thread.spawn(.{}, pairThreadFn, .{ self, path_copy });
        thread.detach();
    }

    fn pairThreadFn(self: *BluetoothManager, device_path: []const u8) void {
        defer self.allocator.free(device_path);
        self.pairSync(device_path) catch |err| {
            std.log.err("Erro ao parear: {}", .{err});
        };
    }

    fn pairSync(self: *BluetoothManager, device_path: []const u8) !void {
        const path_z = try self.allocator.dupeZ(u8, device_path);
        defer self.allocator.free(path_z);

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            path_z.ptr,
            "org.bluez.Device1",
            "Pair",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            30000,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            std.log.err("Erro ao parear: {s}", .{err.message});
            return error.PairingFailed;
        }

        if (reply) |r| c.dbus_message_unref(r);
    }

    /// Conectar (assíncrono)
    pub fn connectAsync(self: *BluetoothManager, device_path: []const u8) !void {
        const path_copy = try self.allocator.dupe(u8, device_path);
        const thread = try std.Thread.spawn(.{}, connectThreadFn, .{ self, path_copy });
        thread.detach();
    }

    fn connectThreadFn(self: *BluetoothManager, device_path: []const u8) void {
        defer self.allocator.free(device_path);
        self.connectSync(device_path) catch |err| {
            std.log.err("Erro ao conectar: {}", .{err});
        };
    }

    fn connectSync(self: *BluetoothManager, device_path: []const u8) !void {
        const path_z = try self.allocator.dupeZ(u8, device_path);
        defer self.allocator.free(path_z);

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            path_z.ptr,
            "org.bluez.Device1",
            "Connect",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            30000,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            return error.ConnectionFailed;
        }

        if (reply) |r| c.dbus_message_unref(r);

        self.pushEvent(.{ .device_connected = device_path });
    }

    /// Desconectar
    pub fn disconnect(self: *BluetoothManager, device_path: []const u8) !void {
        const path_z = try self.allocator.dupeZ(u8, device_path);
        defer self.allocator.free(path_z);

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            path_z.ptr,
            "org.bluez.Device1",
            "Disconnect",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            &err,
        );

        if (reply) |r| c.dbus_message_unref(r);
    }

    pub fn trust(self: *BluetoothManager, device_path: []const u8) !void {
        try self.setProperty(device_path, "org.bluez.Device1", "Trusted", true);
    }

    fn setProperty(self: *BluetoothManager, object_path: []const u8, interface: []const u8, property: []const u8, value: bool) !void {
        const path_z = try self.allocator.dupeZ(u8, object_path);
        defer self.allocator.free(path_z);

        const interface_z = try self.allocator.dupeZ(u8, interface);
        defer self.allocator.free(interface_z);

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            path_z.ptr,
            "org.freedesktop.DBus.Properties",
            "Set",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var iter: c.DBusMessageIter = undefined;
        c.dbus_message_iter_init_append(msg, &iter);

        const iface_cstr = interface_z.ptr;
        _ = c.dbus_message_iter_append_basic(&iter, c.DBUS_TYPE_STRING, &iface_cstr);

        const prop_cstr = @as([*:0]const u8, @ptrCast(property.ptr));
        _ = c.dbus_message_iter_append_basic(&iter, c.DBUS_TYPE_STRING, &prop_cstr);

        var variant_iter: c.DBusMessageIter = undefined;
        _ = c.dbus_message_iter_open_container(&iter, c.DBUS_TYPE_VARIANT, "b", &variant_iter);
        const bool_value: c_uint = if (value) 1 else 0;
        _ = c.dbus_message_iter_append_basic(&variant_iter, c.DBUS_TYPE_BOOLEAN, &bool_value);
        _ = c.dbus_message_iter_close_container(&iter, &variant_iter);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            return error.PropertySetFailed;
        }

        if (reply) |r| c.dbus_message_unref(r);
    }

    /// Obter lista de dispositivos (snapshot atual)
    pub fn getDevices(self: *BluetoothManager) []const Device {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.devices.items;
    }

    /// Buscar dispositivos conhecidos/pareados do sistema
    pub fn discoverKnownDevices(self: *BluetoothManager) !void {
        std.log.info("Buscando dispositivos conhecidos...", .{});

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            "/",
            "org.freedesktop.DBus.ObjectManager",
            "GetManagedObjects",
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            std.log.err("Erro ao buscar dispositivos: {s}", .{err.message});
            return error.DiscoverFailed;
        }

        if (reply) |r| {
            defer c.dbus_message_unref(r);
            try self.parseDevicesFromReply(r);
        }
    }

    /// Parse da resposta do GetManagedObjects
    fn parseDevicesFromReply(self: *BluetoothManager, reply: *c.DBusMessage) !void {
        var iter: c.DBusMessageIter = undefined;
        if (c.dbus_message_iter_init(reply, &iter) == 0) {
            return;
        }

        // Resposta é um array de dict entries
        if (c.dbus_message_iter_get_arg_type(&iter) != c.DBUS_TYPE_ARRAY) {
            return;
        }

        var dict_iter: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&iter, &dict_iter);

        // Iterar sobre cada objeto
        while (c.dbus_message_iter_get_arg_type(&dict_iter) == c.DBUS_TYPE_DICT_ENTRY) {
            var entry_iter: c.DBusMessageIter = undefined;
            c.dbus_message_iter_recurse(&dict_iter, &entry_iter);

            // Pegar o path do objeto
            if (c.dbus_message_iter_get_arg_type(&entry_iter) != c.DBUS_TYPE_OBJECT_PATH) {
                _ = c.dbus_message_iter_next(&dict_iter);
                continue;
            }

            var path: [*:0]const u8 = undefined;
            c.dbus_message_iter_get_basic(&entry_iter, &path);

            const path_str = std.mem.span(path);

            // Só processar se for um dispositivo
            if (!std.mem.containsAtLeast(u8, path_str, 1, "/dev_")) {
                _ = c.dbus_message_iter_next(&dict_iter);
                continue;
            }

            // Pegar propriedades do dispositivo
            _ = c.dbus_message_iter_next(&entry_iter);

            if (c.dbus_message_iter_get_arg_type(&entry_iter) == c.DBUS_TYPE_ARRAY) {
                var interfaces_iter: c.DBusMessageIter = undefined;
                c.dbus_message_iter_recurse(&entry_iter, &interfaces_iter);

                var device_name: ?[]const u8 = null;
                var device_addr: ?[]const u8 = null;
                var is_paired = false;
                var is_connected = false;

                // Iterar sobre interfaces
                while (c.dbus_message_iter_get_arg_type(&interfaces_iter) == c.DBUS_TYPE_DICT_ENTRY) {
                    var iface_entry: c.DBusMessageIter = undefined;
                    c.dbus_message_iter_recurse(&interfaces_iter, &iface_entry);

                    var iface_name: [*:0]const u8 = undefined;
                    c.dbus_message_iter_get_basic(&iface_entry, &iface_name);

                    const iface_str = std.mem.span(iface_name);

                    // Só processar interface Device1
                    if (std.mem.eql(u8, iface_str, "org.bluez.Device1")) {
                        _ = c.dbus_message_iter_next(&iface_entry);

                        if (c.dbus_message_iter_get_arg_type(&iface_entry) == c.DBUS_TYPE_ARRAY) {
                            var props_iter: c.DBusMessageIter = undefined;
                            c.dbus_message_iter_recurse(&iface_entry, &props_iter);

                            // Iterar sobre propriedades
                            while (c.dbus_message_iter_get_arg_type(&props_iter) == c.DBUS_TYPE_DICT_ENTRY) {
                                var prop_entry: c.DBusMessageIter = undefined;
                                c.dbus_message_iter_recurse(&props_iter, &prop_entry);

                                var prop_name: [*:0]const u8 = undefined;
                                c.dbus_message_iter_get_basic(&prop_entry, &prop_name);

                                const prop_str = std.mem.span(prop_name);
                                _ = c.dbus_message_iter_next(&prop_entry);

                                // Pegar valor da propriedade (está em uma variant)
                                if (c.dbus_message_iter_get_arg_type(&prop_entry) == c.DBUS_TYPE_VARIANT) {
                                    var variant_iter: c.DBusMessageIter = undefined;
                                    c.dbus_message_iter_recurse(&prop_entry, &variant_iter);

                                    if (std.mem.eql(u8, prop_str, "Name")) {
                                        if (c.dbus_message_iter_get_arg_type(&variant_iter) == c.DBUS_TYPE_STRING) {
                                            var name: [*:0]const u8 = undefined;
                                            c.dbus_message_iter_get_basic(&variant_iter, &name);
                                            device_name = std.mem.span(name);
                                        }
                                    } else if (std.mem.eql(u8, prop_str, "Address")) {
                                        if (c.dbus_message_iter_get_arg_type(&variant_iter) == c.DBUS_TYPE_STRING) {
                                            var addr: [*:0]const u8 = undefined;
                                            c.dbus_message_iter_get_basic(&variant_iter, &addr);
                                            device_addr = std.mem.span(addr);
                                        }
                                    } else if (std.mem.eql(u8, prop_str, "Paired")) {
                                        if (c.dbus_message_iter_get_arg_type(&variant_iter) == c.DBUS_TYPE_BOOLEAN) {
                                            var paired: c_uint = 0;
                                            c.dbus_message_iter_get_basic(&variant_iter, &paired);
                                            is_paired = paired != 0;
                                        }
                                    } else if (std.mem.eql(u8, prop_str, "Connected")) {
                                        if (c.dbus_message_iter_get_arg_type(&variant_iter) == c.DBUS_TYPE_BOOLEAN) {
                                            var connected: c_uint = 0;
                                            c.dbus_message_iter_get_basic(&variant_iter, &connected);
                                            is_connected = connected != 0;
                                        }
                                    }
                                }

                                _ = c.dbus_message_iter_next(&props_iter);
                            }
                        }
                    }

                    _ = c.dbus_message_iter_next(&interfaces_iter);
                }

                // Adicionar dispositivo se tiver nome e endereço
                if (device_name != null and device_addr != null) {
                    const device = Device{
                        .path = try self.allocator.dupe(u8, path_str),
                        .address = try self.allocator.dupe(u8, device_addr.?),
                        .name = try self.allocator.dupe(u8, device_name.?),
                        .paired = is_paired,
                        .connected = is_connected,
                        .allocator = self.allocator,
                    };

                    self.mutex.lock();
                    defer self.mutex.unlock();

                    // Verificar se já existe
                    var exists = false;
                    for (self.devices.items) |existing| {
                        if (std.mem.eql(u8, existing.path, device.path)) {
                            exists = true;
                            break;
                        }
                    }

                    if (!exists) {
                        try self.devices.append(device);
                        self.pushEventUnlocked(.{ .device_found = device });
                    }
                }
            }

            _ = c.dbus_message_iter_next(&dict_iter);
        }

        std.log.info("Encontrados {d} dispositivos", .{self.devices.items.len});
    }

    fn pushEventUnlocked(self: *BluetoothManager, event: BluetoothEvent) void {
        self.event_queue.append(event) catch |err| {
            std.log.err("Erro ao adicionar evento: {}", .{err});
        };
    }
};

// Controles de mídia
pub const MediaControl = struct {
    bt: *BluetoothManager,

    pub fn init(bt: *BluetoothManager) MediaControl {
        return MediaControl{ .bt = bt };
    }

    pub fn play(self: *MediaControl, player_path: []const u8) !void {
        try self.sendCommand(player_path, "Play");
    }

    pub fn pause(self: *MediaControl, player_path: []const u8) !void {
        try self.sendCommand(player_path, "Pause");
    }

    pub fn next(self: *MediaControl, player_path: []const u8) !void {
        try self.sendCommand(player_path, "Next");
    }

    pub fn previous(self: *MediaControl, player_path: []const u8) !void {
        try self.sendCommand(player_path, "Previous");
    }

    fn sendCommand(self: *MediaControl, player_path: []const u8, command: []const u8) !void {
        const path_z = try self.bt.allocator.dupeZ(u8, player_path);
        defer self.bt.allocator.free(path_z);

        const cmd_z = try self.bt.allocator.dupeZ(u8, command);
        defer self.bt.allocator.free(cmd_z);

        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            path_z.ptr,
            "org.bluez.MediaPlayer1",
            cmd_z.ptr,
        ) orelse return error.MessageCreationFailed;
        defer c.dbus_message_unref(msg);

        var err: c.DBusError = undefined;
        c.dbus_error_init(&err);
        defer c.dbus_error_free(&err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.bt.conn,
            msg,
            -1,
            &err,
        );

        if (c.dbus_error_is_set(&err) != 0) {
            return error.MediaControlFailed;
        }

        if (reply) |r| c.dbus_message_unref(r);
    }
};
