const std = @import("std");
const dbus = @import("../../sdlImport/Sdl.zig").dbus;

// ============================================================================
// DBus - Gerenciador de conexão D-Bus
// ============================================================================
pub const DBus = struct {
    conn: ?*dbus.DBusConnection,

    pub fn init() !DBus {
        var err_buf: [64]u8 align(@alignOf(dbus.DBusError)) = undefined;
        const err: *dbus.DBusError = @ptrCast(&err_buf);
        dbus.dbus_error_init(err);
        defer dbus.dbus_error_free(err);

        const conn = dbus.dbus_bus_get(dbus.DBUS_BUS_SYSTEM, err);
        if (dbus.dbus_error_is_set(err) != 0) {
            return error.DBusConnectionFailed;
        }

        return DBus{ .conn = conn };
    }

    pub fn deinit(self: *DBus) void {
        if (self.conn) |conn| {
            _ = dbus.dbus_connection_unref(conn);
        }
    }

    pub fn callMethod(
        self: *DBus,
        destination: [*c]const u8,
        path: [*c]const u8,
        interface: [*c]const u8,
        method: [*c]const u8,
    ) !void {
        const msg = dbus.dbus_message_new_method_call(
            destination,
            path,
            interface,
            method,
        );
        if (msg == null) return error.OutOfMemory;
        defer _ = dbus.dbus_message_unref(msg);

        var err_buf: [64]u8 align(@alignOf(dbus.DBusError)) = undefined;
        const err: *dbus.DBusError = @ptrCast(&err_buf);
        dbus.dbus_error_init(err);
        defer dbus.dbus_error_free(err);

        const reply = dbus.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            err,
        );

        if (dbus.dbus_error_is_set(err) != 0) {
            return error.DBusCallFailed;
        }

        if (reply != null) {
            _ = dbus.dbus_message_unref(reply);
        }
    }

    pub fn getManagedObjects(
        self: *DBus,
        destination: [*c]const u8,
        path: [*c]const u8,
    ) !?*dbus.DBusMessage {
        const msg = dbus.dbus_message_new_method_call(
            destination,
            path,
            "org.freedesktop.DBus.ObjectManager",
            "GetManagedObjects",
        );
        if (msg == null) return error.OutOfMemory;
        defer _ = dbus.dbus_message_unref(msg);

        var err_buf: [64]u8 align(@alignOf(dbus.DBusError)) = undefined;
        const err: *dbus.DBusError = @ptrCast(&err_buf);
        dbus.dbus_error_init(err);
        defer dbus.dbus_error_free(err);

        const reply = dbus.dbus_connection_send_with_reply_and_block(
            self.conn,
            msg,
            -1,
            err,
        );

        if (dbus.dbus_error_is_set(err) != 0) {
            return error.DBusCallFailed;
        }

        return reply;
    }
};


