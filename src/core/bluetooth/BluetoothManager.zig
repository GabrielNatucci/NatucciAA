const DBus = @import("../dbus/dbus.zig").DBus;
const c = @import("../../sdlImport/Sdl.zig").dbus;
const std = @import("std");
const Device = @import("./Device.zig").Device;
const ArrayList = std.array_list.Managed;

// ============================================================================
// BluetoothManager - Gerenciador específico de Bluetooth
// ============================================================================
pub const BluetoothManager = struct {
    dbus: *DBus,
    discovery: bool,
    adapter_path: [*c]const u8,
    allocator: std.mem.Allocator,
    devices: std.array_list.Managed(Device),

    pub fn init(dbus: *DBus, allocator: std.mem.Allocator) BluetoothManager {
        const devices = ArrayList(Device).init(allocator);

        return BluetoothManager{
            .dbus = dbus,
            .adapter_path = "/org/bluez/hci0",
            .discovery = false,
            .allocator = allocator,
            .devices = devices,
        };
    }

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

        try self.parseDevices(&iter);
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

                while (c.dbus_message_iter_get_arg_type(&iface_array) != c.DBUS_TYPE_INVALID) {
                    var iface_dict: c.DBusMessageIter = undefined;
                    c.dbus_message_iter_recurse(&iface_array, &iface_dict);

                    var iface_name: [*c]const u8 = undefined;
                    c.dbus_message_iter_get_basic(&iface_dict, @ptrCast(&iface_name));

                    const iface_str = std.mem.span(iface_name);
                    if (std.mem.eql(u8, iface_str, "org.bluez.Device1")) {
                        _ = c.dbus_message_iter_next(&iface_dict);

                        const dev = try parseDeviceProperties(self, &iface_dict);

                        if (dev != null) {
                            try self.devices.append(dev.?);
                        }
                    }

                    _ = c.dbus_message_iter_next(&iface_array);
                }
            }

            _ = c.dbus_message_iter_next(&array_iter);
        }
    }

    pub fn deinit(self: BluetoothManager) void {
        self.deinitDevices();
    }

    pub fn deinitDevices(self: BluetoothManager) void {
        for (self.devices.items) |current| {
            current.deinit();
        }

        self.devices.deinit();
    }
};

fn parseDeviceProperties(self: *BluetoothManager, iter: *c.DBusMessageIter) !?Device {
    var prop_array: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(iter, &prop_array);

    var name: ?[]const u8 = null;
    var address: ?[]const u8 = null;
    var rssi: ?i16 = null;

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
        }

        _ = c.dbus_message_iter_next(&prop_array);
    }

    if (name != null and address != null and rssi != null) {
        var nomeCopy = ArrayList(u8).init(self.allocator);
        try nomeCopy.appendSlice(name.?);
        try nomeCopy.append(0);

        var addressCopy = ArrayList(u8).init(self.allocator);
        try addressCopy.appendSlice(address.?);
        try addressCopy.append(0);

        return Device.init(nomeCopy, addressCopy, rssi.?);
    } else {
        return null;
    }

    // if (name) |n| std.debug.print("  Nome: {s}\n", .{n});
    // if (address) |a| std.debug.print("  Endereço: {s}\n", .{a});
    // if (rssi) |r| std.debug.print("  RSSI: {d} dBm\n", .{r});
}
