const std = @import("std");
const ArrayList = std.array_list.Managed;

pub const Device = struct {
    name: ArrayList(u8),
    address: ArrayList(u8),
    rssi: i16,

    pub fn init(name: ArrayList(u8), address: ArrayList(u8), rssi: i16) Device {
        return .{
            .name = name,
            .address = address,
            .rssi = rssi,
        };
    }

    pub fn deinit(self: Device) void {
        self.name.deinit();
        self.address.deinit();
    }
};
