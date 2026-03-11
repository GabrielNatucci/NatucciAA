const std = @import("std");
const ArrayList = std.array_list.Managed;

const c = @import("../../../../sdlImport/Sdl.zig").dbus;
const DbusError = @import("../../../../sdlImport/Sdl.zig").DBusError;
const BluetoothManager = @import("../../BluetoothManager.zig").BluetoothManager;
const Device = @import("../structs/Device.zig").Device;
const TrackInfo = @import("./../structs/TrackInfo.zig").TrackInfo;

fn buildPathToMusic(buffer: []u8, adapter_path: []const u8, connected_address: ?[]const u8) ![]const u8 {
    const addr_str = connected_address orelse return error.NoAddress;

    var mac_buf: [17]u8 = undefined;
    @memcpy(&mac_buf, addr_str[0..17]);
    std.mem.replaceScalar(u8, &mac_buf, ':', '_');

    return try std.fmt.bufPrint(buffer, "{s}/dev_{s}", .{ adapter_path, mac_buf });
}

pub fn pauseMusic(self: *BluetoothManager) !void {
    std.debug.print("Pausando música...\n", .{});

    var buf: [128]u8 = undefined;
    const path = try buildPathToMusic(
        &buf,
        std.mem.sliceTo(self.adapter_path, 0),
        if (self.connectedAddress) |addr| addr[0..] else null,
    );
    buf[path.len] = 0;

    std.debug.print("path: '{s}'\n", .{path});

    try self.dbus.callMethod(
        "org.bluez",
        path.ptr,
        "org.bluez.MediaControl1",
        "Pause",
    );
}

pub fn unpauseMusic(self: *BluetoothManager) !void {
    std.debug.print("Despausando música...\n", .{});

    var buf: [128]u8 = undefined;
    const path = try buildPathToMusic(
        &buf,
        std.mem.sliceTo(self.adapter_path, 0),
        if (self.connectedAddress) |addr| addr[0..] else null,
    );
    buf[path.len] = 0;

    std.debug.print("path: '{s}'\n", .{path});

    try self.dbus.callMethod(
        "org.bluez",
        path.ptr,
        "org.bluez.MediaControl1",
        "Play",
    );
}

pub fn nextMusic(self: *BluetoothManager) !void {
    std.debug.print("Próxima música...\n", .{});

    var buf: [128]u8 = undefined;
    const path = try buildPathToMusic(
        &buf,
        std.mem.sliceTo(self.adapter_path, 0),
        if (self.connectedAddress) |addr| addr[0..] else null,
    );
    buf[path.len] = 0;

    std.debug.print("path: '{s}'\n", .{path});

    try self.dbus.callMethod(
        "org.bluez",
        path.ptr,
        "org.bluez.MediaControl1",
        "Next",
    );
}

pub fn previousMusic(self: *BluetoothManager) !void {
    std.debug.print("Música anterior...\n", .{});

    var buf: [128]u8 = undefined;
    const path = try buildPathToMusic(
        &buf,
        std.mem.sliceTo(self.adapter_path, 0),
        if (self.connectedAddress) |addr| addr[0..] else null,
    );
    buf[path.len] = 0;

    std.debug.print("path: '{s}'\n", .{path});

    try self.dbus.callMethod(
        "org.bluez",
        path.ptr,
        "org.bluez.MediaControl1",
        "Previous",
    );
}

pub fn getTrackInfo(self: *BluetoothManager, out: *TrackInfo) !void {
    const player = self.player_path orelse return error.NoPlayer;

    const msg = c.dbus_message_new_method_call(
        "org.bluez",
        player,
        "org.freedesktop.DBus.Properties",
        "Get",
    ) orelse return error.DBusMessageNull;
    defer c.dbus_message_unref(msg);

    var msgIter: c.DBusMessageIter = undefined;
    _ = c.dbus_message_iter_init_append(msg, &msgIter);
    const iface: [*:0]const u8 = "org.bluez.MediaPlayer1";
    const prop: [*:0]const u8 = "Track";
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&iface));
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&prop));

    var bufErr: DbusError = undefined;
    const dbusError: *c.DBusError = @ptrCast(&bufErr);
    c.dbus_error_init(dbusError);
    defer c.dbus_error_free(dbusError);

    const reply = c.dbus_connection_send_with_reply_and_block(
        self.dbus.conn,
        msg,
        -1,
        dbusError,
    ) orelse return error.SemRespostaDoDbus;
    defer c.dbus_message_unref(reply);

    var iter: c.DBusMessageIter = undefined;
    if (c.dbus_message_iter_init(reply, &iter) == 0) return error.EmptyReply;

    // Nível 1: VARIANT
    if (c.dbus_message_iter_get_arg_type(&iter) != c.DBUS_TYPE_VARIANT) return error.UnexpectedType;
    var variant: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(&iter, &variant);

    // Nível 2: ARRAY de DICT_ENTRY {sv}
    if (c.dbus_message_iter_get_arg_type(&variant) != c.DBUS_TYPE_ARRAY) return error.UnexpectedType;
    var array: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(&variant, &array);

    // Itera cada DICT_ENTRY
    while (c.dbus_message_iter_get_arg_type(&array) == c.DBUS_TYPE_DICT_ENTRY) {
        var entry: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&array, &entry);

        // Chave (string)
        var key: [*c]const u8 = undefined;
        c.dbus_message_iter_get_basic(&entry, @ptrCast(&key));
        _ = c.dbus_message_iter_next(&entry);

        // Valor (variant)
        var val_variant: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&entry, &val_variant);

        const key_str = std.mem.span(key);

        if (std.mem.eql(u8, key_str, "Title")) {
            var s: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&s));
            const span = std.mem.span(s);
            @memcpy(out.title[0..span.len], span);
            out.title[span.len] = 0;
        } else if (std.mem.eql(u8, key_str, "Artist")) {
            var s: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&s));
            const span = std.mem.span(s);
            @memcpy(out.artist[0..span.len], span);
            out.artist[span.len] = 0;
        } else if (std.mem.eql(u8, key_str, "Album")) {
            var s: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&s));
            const span = std.mem.span(s);
            @memcpy(out.album[0..span.len], span);
            out.album[span.len] = 0;
        } else if (std.mem.eql(u8, key_str, "Duration")) {
            var v: u32 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&v));
            out.duration = v;
        } else if (std.mem.eql(u8, key_str, "TrackNumber")) {
            var v: u32 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&v));
            out.track_number = v;
        } else if (std.mem.eql(u8, key_str, "NumberOfTracks")) {
            var v: u32 = undefined;
            c.dbus_message_iter_get_basic(&val_variant, @ptrCast(&v));
            out.number_of_tracks = v;
        }

        _ = c.dbus_message_iter_next(&array);
    }

    out.position = self.getPosition() catch 0;
    out.playing = self.isPlaying();
}

pub fn isPlaying(self: *BluetoothManager) bool {
    const player = self.player_path orelse return false;

    const msg = c.dbus_message_new_method_call(
        "org.bluez",
        player,
        "org.freedesktop.DBus.Properties",
        "Get",
    ) orelse return false;
    defer c.dbus_message_unref(msg);

    var msgIter: c.DBusMessageIter = undefined;
    _ = c.dbus_message_iter_init_append(msg, &msgIter);
    const iface: [*:0]const u8 = "org.bluez.MediaPlayer1";
    const prop: [*:0]const u8 = "Status";
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&iface));
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&prop));

    var bufErr: DbusError = undefined;
    const dbusError: *c.DBusError = @ptrCast(&bufErr);
    c.dbus_error_init(dbusError);
    defer c.dbus_error_free(dbusError);

    const reply = c.dbus_connection_send_with_reply_and_block(
        self.dbus.conn,
        msg,
        -1,
        dbusError,
    ) orelse return false;
    defer c.dbus_message_unref(reply);

    var iter: c.DBusMessageIter = undefined;
    if (c.dbus_message_iter_init(reply, &iter) == 0) return false;
    if (c.dbus_message_iter_get_arg_type(&iter) != c.DBUS_TYPE_VARIANT) return false;

    var variant: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(&iter, &variant);
    if (c.dbus_message_iter_get_arg_type(&variant) != c.DBUS_TYPE_STRING) return false;

    var status: [*c]const u8 = undefined;
    c.dbus_message_iter_get_basic(&variant, @ptrCast(&status));

    return std.mem.eql(u8, std.mem.span(status), "playing");
}

pub fn getPosition(self: *BluetoothManager) !u32 {
    const player = self.player_path orelse return error.NoPlayer;

    const msg = c.dbus_message_new_method_call(
        "org.bluez",
        player,
        "org.freedesktop.DBus.Properties",
        "Get",
    ) orelse return error.DBusMessageNull;
    defer c.dbus_message_unref(msg);

    var msgIter: c.DBusMessageIter = undefined;
    _ = c.dbus_message_iter_init_append(msg, &msgIter);
    const iface: [*:0]const u8 = "org.bluez.MediaPlayer1";
    const prop: [*:0]const u8 = "Position";
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&iface));
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&prop));

    var bufErr: DbusError = undefined;
    const dbusError: *c.DBusError = @ptrCast(&bufErr);
    c.dbus_error_init(dbusError);
    defer c.dbus_error_free(dbusError);

    const reply = c.dbus_connection_send_with_reply_and_block(
        self.dbus.conn,
        msg,
        -1,
        dbusError,
    ) orelse return error.SemRespostaDoDbus;
    defer c.dbus_message_unref(reply);

    var iter: c.DBusMessageIter = undefined;
    if (c.dbus_message_iter_init(reply, &iter) == 0) return error.EmptyReply;

    // VARIANT contendo u32
    if (c.dbus_message_iter_get_arg_type(&iter) != c.DBUS_TYPE_VARIANT) return error.UnexpectedType;
    var variant: c.DBusMessageIter = undefined;
    c.dbus_message_iter_recurse(&iter, &variant);

    var position: u32 = undefined;
    c.dbus_message_iter_get_basic(&variant, @ptrCast(&position));

    return position;
}

pub fn getMusicPlayer(self: *BluetoothManager) !void {
    std.debug.print("Pegando player...\n", .{});

    var buf: [128]u8 = undefined;
    const path = try buildPathToMusic(
        &buf,
        std.mem.sliceTo(self.adapter_path, 0),
        if (self.connectedAddress) |addr| addr[0..] else null,
    );
    buf[path.len] = 0;

    std.debug.print("caminho: {s}\n", .{path});
    const msg = c.dbus_message_new_method_call(
        "org.bluez",
        path.ptr,
        "org.freedesktop.DBus.Properties",
        "Get",
    ) orelse return error.DBusMessageNull;

    var msgIter: c.DBusMessageIter = undefined;
    _ = c.dbus_message_iter_init_append(msg, &msgIter);

    const arg0: [*:0]const u8 = "org.bluez.MediaControl1";
    const arg1: [*:0]const u8 = "Player";

    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&arg0));
    _ = c.dbus_message_iter_append_basic(&msgIter, c.DBUS_TYPE_STRING, @ptrCast(&arg1));

    var bufErr: DbusError = undefined;
    const dbusError: *c.DBusError = @ptrCast(&bufErr);
    c.dbus_error_init(dbusError);
    defer c.dbus_error_free(dbusError);

    const reply = c.dbus_connection_send_with_reply_and_block(self.dbus.conn, msg, -1, dbusError);

    if (reply == null) {
        return error.SemRespostaDoDbus;
    }

    var iter: c.DBusMessageIter = undefined;

    if (c.dbus_message_iter_init(reply, &iter) == 0) {
        return error.NaoFoiPossivelRecuperarOPlayer;
    }

    if (c.dbus_message_iter_get_arg_type(&iter) == c.DBUS_TYPE_VARIANT) {
        std.debug.print("c.dbus_message_iter_get_arg_type\n", .{});
        var variant: c.DBusMessageIter = undefined;
        c.dbus_message_iter_recurse(&iter, &variant);

        if (c.dbus_message_iter_get_arg_type(&variant) == c.DBUS_TYPE_OBJECT_PATH) {
            var player_path: [*c]const u8 = undefined;
            c.dbus_message_iter_get_basic(&variant, @ptrCast(&player_path));

            // Copia para o buffer próprio (não confiar na memória do dbus após unref)
            const span = std.mem.span(player_path);
            @memcpy(self.player_path_buf[0..span.len], span);
            self.player_path_buf[span.len] = 0;
            self.player_path = self.player_path_buf[0..span.len :0];

            std.debug.print("Player path salvo: {s}\n", .{self.player_path.?});
        }
    }

    c.dbus_message_unref(msg);
}
