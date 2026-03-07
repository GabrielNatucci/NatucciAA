const std = @import("std");
pub fn main() void {
    var buf: [10]u8 = "0123456789".*;
    std.mem.copyForwards(u8, buf[0..5], buf[5..10]);
    std.debug.print("{s}\n", .{buf});
}
