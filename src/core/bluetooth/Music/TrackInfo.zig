const std = @import("std");

pub const TrackInfo = struct {
    title: [256]u8 = std.mem.zeroes([256]u8),
    artist: [256]u8 = std.mem.zeroes([256]u8),
    album: [256]u8 = std.mem.zeroes([256]u8),
    duration: u32 = 0,
    track_number: u32 = 0,
    number_of_tracks: u32 = 0,
    position: u32 = 0,

    pub fn getTitle(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.title, 0);
    }

    pub fn getArtist(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.artist, 0);
    }

    pub fn getAlbum(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.album, 0);
    }

    pub fn getProgressPercent(self: *const TrackInfo) f32 {
        if (self.duration == 0) return 0;
        return @as(f32, @floatFromInt(self.position)) / @as(f32, @floatFromInt(self.duration)) * 100.0;
    }

    pub fn getPositionFormatted(self: *const TrackInfo, buf: []u8) [:0]u8 {
        const pos_seg = self.position / 1000;
        const dur_seg = self.duration / 1000;
        return std.fmt.bufPrintZ(buf, "{}:{:0>2} / {}:{:0>2}", .{
            pos_seg / 60, pos_seg % 60,
            dur_seg / 60, dur_seg % 60,
        }) catch blk: {
            buf[0] = 0;
            break :blk buf[0..0 :0];
        };
    }
};
