const std = @import("std");

pub const Device = struct {
    name: []const u8,
    address: []const u8,
    rssi: ?i16,

    pub fn init(
        name: []const u8,
        address: []const u8,
        rssi: ?i16,
        allocator: std.mem.Allocator,
    ) !Device {
        return .{
            .name = try allocator.dupe(u8, name),
            .address = try allocator.dupe(u8, address),
            .rssi = rssi,
        };
    }

    pub fn deinit(self: *Device, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.address);
    }
};
