// Device.zig
const std = @import("std");
const ArrayList = std.array_list.Managed;

pub const Device = struct {
    name: ArrayList(u8),
    address: ArrayList(u8),
    rssi: ?i16,
    connected: bool, 
    paired: bool, 
    trusted: bool, 
    blocked: bool, 

    pub fn init(
        name: ArrayList(u8),
        address: ArrayList(u8),
        rssi: ?i16,
        connected: bool,
        paired: bool,
        trusted: bool,
        blocked: bool,
    ) Device {
        return Device{
            .name = name,
            .address = address,
            .rssi = rssi,
            .connected = connected,
            .paired = paired,
            .trusted = trusted,
            .blocked = blocked,
        };
    }

    pub fn deinit(self: Device) void {
        self.name.deinit();
        self.address.deinit();
    }
};
