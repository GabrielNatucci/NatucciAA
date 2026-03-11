const std = @import("std");
const ArrayList = std.array_list.Managed;

const BluetoothManager = @import("../../BluetoothManager.zig").BluetoothManager;
const c = @import("../../../../sdlImport/Sdl.zig").dbus;
const Device = @import("../structs/Device.zig").Device;

const MAC_LEN = 17;

pub fn startDiscovery(self: *BluetoothManager) !void {
    if (self.discovery == false) {
        std.debug.print("Iniciando descoberta...\n", .{});
        self.discovery = true;
        try self.dbus.callMethod(
            "org.bluez",
            self.adapter_path,
            "org.bluez.Adapter1",
            "StartDiscovery",
        );
    }
}

pub fn stopDiscovery(self: *BluetoothManager) !void {
    if (self.discovery == true) {
        std.debug.print("Parando descoberta...\n", .{});
        self.discovery = false;
        try self.dbus.callMethod(
            "org.bluez",
            self.adapter_path,
            "org.bluez.Adapter1",
            "StopDiscovery",
        );
    }
}

pub fn listDevices(self: *BluetoothManager) !void {
    const reply = try self.dbus.getManagedObjects("org.bluez", "/");
    if (reply == null) return;
    defer _ = c.dbus_message_unref(reply);

    var iter: c.DBusMessageIter = undefined;
    if (c.dbus_message_iter_init(reply, &iter) == 0) {
        std.debug.print("Resposta vazia\n", .{});
        return;
    }

    self.deinitDevices();

    try parseDevices(self, &iter);
}

fn parseDeviceFromInterfaces(self: *BluetoothManager, iface_array_iter: *c.DBusMessageIter) !?Device {
    while (c.dbus_message_iter_get_arg_type(iface_array_iter) != c.DBUS_TYPE_INVALID) {
        var iface_dict_iter: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(iface_array_iter, &iface_dict_iter);

        var iface_name: [*c]const u8 = undefined;
        c.dbus_message_iter_get_basic(&iface_dict_iter, @ptrCast(&iface_name));
        const iface_str = std.mem.span(iface_name);

        if (std.mem.eql(u8, iface_str, "org.bluez.Device1")) {
            _ = c.dbus_message_iter_next(&iface_dict_iter);
            return try parseDeviceProperties(self, &iface_dict_iter);
        }

        _ = c.dbus_message_iter_next(iface_array_iter);
    }

    return null;
}

fn parseDeviceProperties(self: *BluetoothManager, iter: *c.DBusMessageIter) !?Device {
    var prop_array: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(iter, &prop_array);

    var name: ?[]const u8 = null;
    var address: ?[]const u8 = null;
    var rssi: ?i16 = null; // Agora pode ser null
    var connected: bool = false;
    var paired: bool = false;
    var trusted: bool = false;
    var blocked: bool = false;

    while (c.dbus_message_iter_get_arg_type(&prop_array) != c.DBUS_TYPE_INVALID) {
        var prop_dict: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&prop_array, &prop_dict);

        var prop_name: [*c]const u8 = undefined;
        c.dbus_message_iter_get_basic(&prop_dict, @ptrCast(&prop_name));
        const prop_str = std.mem.span(prop_name);

        _ = c.dbus_message_iter_next(&prop_dict);

        var variant: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&prop_dict, &variant);

        if (std.mem.eql(u8, prop_str, "Name")) {
            var value: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            name = std.mem.span(value);
        } else if (std.mem.eql(u8, prop_str, "Address")) {
            var value: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            address = std.mem.span(value);
        } else if (std.mem.eql(u8, prop_str, "RSSI")) {
            var value: i16 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            rssi = value;
        } else if (std.mem.eql(u8, prop_str, "Connected")) {
            var value: u32 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            connected = (value != 0);
        } else if (std.mem.eql(u8, prop_str, "Paired")) {
            var value: u32 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            paired = (value != 0);
        } else if (std.mem.eql(u8, prop_str, "Trusted")) {
            var value: u32 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            trusted = (value != 0);
        } else if (std.mem.eql(u8, prop_str, "Blocked")) {
            var value: u32 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&value));
            blocked = (value != 0);
        }

        _ = c.dbus_message_iter_next(&prop_array);
    }

    if (name != null and address != null) {
        var nomeCopy = ArrayList(u8).init(self.allocator);
        try nomeCopy.appendSlice(name.?);
        try nomeCopy.append(0);

        var addressCopy = ArrayList(u8).init(self.allocator);
        try addressCopy.appendSlice(address.?);
        try addressCopy.append(0);

        if (connected) {
            self.mu.lock();
            defer self.mu.unlock();
            const addressTemp = addressCopy.items;
            std.debug.print("Dispositivo conectado!\n", .{});
            std.debug.print("endereco: {s}\n", .{addressTemp});
            std.debug.print("nome: {s}\n", .{nomeCopy.items});
            self.connectedAddress = blk: {
                var addr: [MAC_LEN]u8 = undefined;
                @memcpy(&addr, addressTemp[0..MAC_LEN]);
                break :blk addr;
            };
        }

        return Device.init(
            nomeCopy,
            addressCopy,
            rssi,
            connected,
            paired,
            trusted,
            blocked,
        );
    } else {
        return null;
    }
}

fn parseDevices(self: *BluetoothManager, iter: *c.DBusMessageIter) !void {
    var array_iter: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(iter, &array_iter);

    self.devices = ArrayList(Device).init(self.allocator);

    while (c.dbus_message_iter_get_arg_type(&array_iter) != c.DBUS_TYPE_INVALID) {
        var dict_iter: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&array_iter, &dict_iter);

        var path: [*c]const u8 = undefined;
        c.dbus_message_iter_get_basic(&dict_iter, @ptrCast(&path));
        const path_str = std.mem.span(path);

        if (std.mem.indexOf(u8, path_str, "/dev_") != null) {
            _ = c.dbus_message_iter_next(&dict_iter);

            var iface_array: c.DBusMessageIter = undefined;
            c.dbus_message_iter_recurse(&dict_iter, &iface_array);

            if (try parseDeviceFromInterfaces(self, &iface_array)) |dev| {
                try self.devices.append(dev);
            }
        }

        _ = c.dbus_message_iter_next(&array_iter);
    }
}
