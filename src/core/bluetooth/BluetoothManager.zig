const std = @import("std");
const ArrayList = std.array_list.Managed;

const c = @import("../../sdlImport/Sdl.zig").dbus;
const DbusError = @import("../../sdlImport/Sdl.zig").DBusError;
const DBus = @import("../dbus/dbus.zig").DBus;
const Connection = @import("./manager/connection/Connection.zig");
const Discovery = @import("./manager/discovery/Discovery.zig");
const MusicController = @import("./manager/musiccontroller/MusicController.zig");
const Device = @import("./manager/structs/Device.zig").Device;
const TrackInfo = @import("./manager/structs/TrackInfo.zig").TrackInfo;

const MAC_LEN = 17;
const MacAddress = [MAC_LEN]u8;

pub const BluetoothManager = struct {
    dbus: *DBus,
    discovery: bool,
    adapter_path: [*c]const u8,
    allocator: std.mem.Allocator,
    devices: std.array_list.Managed(Device),
    connected: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    connecting: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    connectionError: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    mu: std.Thread.Mutex = .{},
    connectedAddress: ?[MAC_LEN]u8 = null,
    player_path: ?[*:0]const u8 = null,
    player_path_buf: [128]u8 = undefined,

    pub fn init(dbus: *DBus, allocator: std.mem.Allocator) BluetoothManager {
        const devices = ArrayList(Device).init(allocator);

        var manager = BluetoothManager{
            .dbus = dbus,
            .adapter_path = "/org/bluez/hci0",
            .discovery = false,
            .allocator = allocator,
            .devices = devices,
        };

        manager.setupSimpleAgent() catch {
            std.debug.print("Erro ao setar agent\n", .{});
        };

        return manager;
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

    pub fn setupSimpleAgent(self: *BluetoothManager) !void {
        const msg = c.dbus_message_new_method_call(
            "org.bluez",
            "/org/bluez",
            "org.bluez.AgentManager1",
            "RegisterAgent",
        );
        if (msg == null) return error.OutOfMemory;
        defer _ = c.dbus_message_unref(msg);

        var args: c.DBusMessageIter = undefined;
        c.dbus_message_iter_init_append(msg, &args);

        const agent_path = "/org/bluez/auto_agent";
        var path_ptr: [*c]const u8 = agent_path.ptr;
        _ = c.dbus_message_iter_append_basic(&args, c.DBUS_TYPE_OBJECT_PATH, @ptrCast(&path_ptr));

        const capability = "NoInputNoOutput";
        var cap_ptr: [*c]const u8 = capability.ptr;
        _ = c.dbus_message_iter_append_basic(&args, c.DBUS_TYPE_STRING, @ptrCast(&cap_ptr));

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
            std.debug.print("Erro ao registrar agente\n", .{});
            return error.DBusCallFailed;
        }

        if (reply != null) {
            _ = c.dbus_message_unref(reply);
        }

        // Tornar padrão
        const msg2 = c.dbus_message_new_method_call(
            "org.bluez",
            "/org/bluez",
            "org.bluez.AgentManager1",
            "RequestDefaultAgent",
        );
        if (msg2 == null) return error.OutOfMemory;
        defer _ = c.dbus_message_unref(msg2);

        var args2: c.DBusMessageIter = undefined;
        c.dbus_message_iter_init_append(msg2, &args2);
        path_ptr = agent_path.ptr;
        _ = c.dbus_message_iter_append_basic(&args2, c.DBUS_TYPE_OBJECT_PATH, @ptrCast(&path_ptr));

        const reply2 = c.dbus_connection_send_with_reply_and_block(
            self.dbus.conn,
            msg2,
            -1,
            err,
        );

        if (reply2 != null) {
            _ = c.dbus_message_unref(reply2);
        }

        std.debug.print("Agente auto-accept registrado!\n", .{});
    }

    pub fn startDiscovery(self: *BluetoothManager) !void {
        try Discovery.startDiscovery(self);
    }

    pub fn stopDiscovery(self: *BluetoothManager) !void {
        try Discovery.stopDiscovery(self);
    }

    pub fn listDevices(self: *BluetoothManager) !void {
        try Discovery.listDevices(self);
    }

    pub fn connectDeviceAsync(self: *BluetoothManager, device: *const Device) !void {
        try Connection.connectDeviceAsync(self, device);
    }

    pub fn getConnectedAddress(self: *BluetoothManager) ?[MAC_LEN]u8 {
        return Connection.getConnectedAddress(self);
    }

    pub fn setConnectionStatus(self: *BluetoothManager, connecting: bool, connected: bool, connectionError: bool) void {
        Connection.setConnectionStatus(self, connecting, connected, connectionError);
    }

    pub fn disconnectDevice(self: *BluetoothManager, device: *const Device) !void {
        try Connection.disconnectDevice(self, device);
    }

    pub fn pairDevice(self: *BluetoothManager, device: *const Device) !void {
        try Connection.pairDevice(self, device);
    }

    pub fn trustDevice(self: *BluetoothManager, device: *const Device, trusted: bool) !void {
        try Connection.trustDevice(self, device, trusted);
    }

    pub fn pauseMusic(self: *BluetoothManager) !void {
        try MusicController.pauseMusic(self);
    }

    pub fn unpauseMusic(self: *BluetoothManager) !void {
        try MusicController.unpauseMusic(self);
    }

    pub fn nextMusic(self: *BluetoothManager) !void {
        try MusicController.nextMusic(self);
    }

    pub fn previousMusic(self: *BluetoothManager) !void {
        try MusicController.previousMusic(self);
    }

    pub fn getTrackInfo(self: *BluetoothManager, out: *TrackInfo) !void {
        try MusicController.getTrackInfo(self, out);
    }

    pub fn isPlaying(self: *BluetoothManager) bool {
        return MusicController.isPlaying(self);
    }

    pub fn getPosition(self: *BluetoothManager) !u32 {
        return try MusicController.getPosition(self);
    }

    pub fn getMusicPlayer(self: *BluetoothManager) !void {
        try MusicController.getMusicPlayer(self);
    }
};
