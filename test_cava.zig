const std = @import("std");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const argv = &[_][]const u8{ "cava", "-v" };
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();
    _ = try child.wait();
    std.debug.print("Cava ran.\n", .{});
}
