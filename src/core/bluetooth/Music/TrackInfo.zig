const std = @import("std");

pub const TrackInfo = struct {
    title: [256]u8 = std.mem.zeroes([256]u8),
    artist: [256]u8 = std.mem.zeroes([256]u8),
    album: [256]u8 = std.mem.zeroes([256]u8),
    duration: u32 = 0,
    track_number: u32 = 0,
    number_of_tracks: u32 = 0,

    pub fn getTitle(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.title, 0);
    }
    pub fn getArtist(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.artist, 0);
    }
    pub fn getAlbum(self: *const TrackInfo) []const u8 {
        return std.mem.sliceTo(&self.album, 0);
    }
};
