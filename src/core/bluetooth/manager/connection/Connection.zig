const std = @import("std");
const ArrayList = std.array_list.Managed;

const c = @import("../../../../sdlImport/Sdl.zig").dbus;
const BluetoothManager = @import("../../BluetoothManager.zig").BluetoothManager;
const Device = @import("../structs/Device.zig").Device;

const MAC_LEN = 17;

pub fn connectDeviceAsync(self: *BluetoothManager, device: *const Device) !void {
    const thread = try std.Thread.spawn(.{}, connectDevice, .{ self, device });
    thread.detach();
}

fn connectDevice(self: *BluetoothManager, device: *const Device) !void {
    self.setConnectionStatus(true, false, false);
    errdefer self.setConnectionStatus(false, false, true);

    if (device.paired == false) {
        self.pairDevice(device) catch |err| {
            std.debug.print("Erro ao parear no dispositivo: {}", .{err});
            return err;
        };

        self.trustDevice(device, false) catch |err| {
            std.debug.print("Erro ao confiar no dispositivo: {}", .{err});
            return err;
        };
    }

    const device_path = try buildDevicePath(self, device.address.items);
    defer self.allocator.free(device_path);

    std.debug.print("Conectando ao dispositivo: {s}\n", .{device.name.items});
    std.debug.print("Path: {s}\n", .{device_path});

    self.dbus.callMethod(
        "org.bluez",
        device_path.ptr,
        "org.bluez.Device1",
        "Connect",
    ) catch |err| {
        std.debug.print("❌ ERRO D-BUS: {}\n", .{err});
        return err;
    };

    self.setConnectionStatus(false, true, false);

    std.debug.print("Conectado com sucesso!\n", .{});

    self.mu.lock();
    defer self.mu.unlock();
    const address = device.address.items;
    self.connectedAddress = blk: {
        var addr: [MAC_LEN]u8 = undefined;
        @memcpy(&addr, address[0..MAC_LEN]);
        break :blk addr;
    };
}

pub fn setConnectionStatus(self: *BluetoothManager, connecting: bool, connected: bool, connectionError: bool) void {
    self.connecting.store(connecting, .seq_cst);
    self.connected.store(connected, .seq_cst);
    self.connectionError.store(connectionError, .seq_cst);
}

pub fn getConnectedAddress(self: *BluetoothManager) ?[MAC_LEN]u8 {
    self.mu.lock();
    defer self.mu.unlock();
    return self.connectedAddress;
}

pub fn disconnectDevice(self: *BluetoothManager, device: *const Device) !void {
    const device_path = try buildDevicePath(self, device.address.items);
    defer self.allocator.free(device_path);

    std.debug.print("Desconectando do dispositivo: {s}\n", .{device.name.items});

    try self.dbus.callMethod(
        "org.bluez",
        device_path.ptr,
        "org.bluez.Device1",
        "Disconnect",
    );

    self.connecting.store(false, .seq_cst);
    self.connected.store(false, .seq_cst);
    self.connectedAddress = null;
    std.debug.print("Desconectado com sucesso!\n", .{});
}

pub fn pairDevice(self: *BluetoothManager, device: *const Device) !void {
    const device_path = try buildDevicePath(self, device.address.items);
    defer self.allocator.free(device_path);

    std.debug.print("Pareando com dispositivo: {s}\n", .{device.name.items});

    try self.dbus.callMethod(
        "org.bluez",
        device_path.ptr,
        "org.bluez.Device1",
        "Pair",
    );

    std.debug.print("Pareado com sucesso!\n", .{});
}

pub fn trustDevice(self: *BluetoothManager, device: *const Device, trusted: bool) !void {
    const device_path = try buildDevicePath(self, device.address.items);
    defer self.allocator.free(device_path);

    std.debug.print("Configurando trust para: {s}\n", .{device.name.items});

    try setDeviceProperty(self, device_path, "Trusted", trusted);

    std.debug.print("Trust configurado!\n", .{});
}

pub fn buildDevicePath(self: *BluetoothManager, address: []const u8) ![]u8 {
    var path = ArrayList(u8).init(self.allocator);
    errdefer path.deinit();

    try path.appendSlice("/org/bluez/hci0/dev_");

    for (address) |char| {
        if (char == ':') {
            try path.append('_');
        } else if (char != 0) {
            try path.append(char);
        }
    }

    try path.append(0);

    return path.toOwnedSlice();
}

pub fn setDeviceProperty(self: *BluetoothManager, device_path: []const u8, property: []const u8, value: bool) !void {
        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            device_path.ptr,
            "org.freedesktop.DBus.Properties",
            "Set",
        );
        if (msg == null) return error.OutOfMemory;
        defer _ = c.dbus_message_unref(msg);

        // Adicionar argumentos: interface, property name, e variant
        var args: c.DBusMessageIter = undefined;
        c.dbus_message_iter_init_append(msg, &args);

        // Adicionar interface name
        const interface = "org.bluez.Device1";
        var interface_ptr: [*c]const u8 = interface.ptr;
        _ = c.dbus_message_iter_append_basic(&args, c.DBUS_TYPE_STRING, @ptrCast(&interface_ptr));

        // Adicionar property name
        var property_ptr: [*c]const u8 = property.ptr;
        _ = c.dbus_message_iter_append_basic(&args, c.DBUS_TYPE_STRING, @ptrCast(&property_ptr));

        // Adicionar variant com boolean
        var variant: c.DBusMessageIter = undefined;
        const variant_sig = "b";
        _ = c.dbus_message_iter_open_container(&args, c.DBUS_TYPE_VARIANT, variant_sig.ptr, &variant);

        const bool_value: u32 = if (value) 1 else 0;
        _ = c.dbus_message_iter_append_basic(&variant, c.DBUS_TYPE_BOOLEAN, @ptrCast(&bool_value));
        _ = c.dbus_message_iter_close_container(&args, &variant);

        // Enviar mensagem
        var err_buf: [64]u8 align(@alignOf(c.DBusError)) = undefined;
        const err: *c.DBusError = @ptrCast(&err_buf);
        c.dbus_error_init(err);
        defer c.dbus_error_free(err);

        const reply = c.dbus_connection_send_with_reply_and_block(
            self.dbus.conn,
            msg,
            -1,
            err,
        );

        if (c.dbus_error_is_set(err) != 0) {
            return error.DBusCallFailed;
        }

        if (reply != null) {
            _ = c.dbus_message_unref(reply);
        }
    }
