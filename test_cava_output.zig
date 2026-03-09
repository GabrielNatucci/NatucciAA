const std = @import("std");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const config =
        \\[general]
        \\bars = 64
        \\[output]
        \\channels = mono
        \\method = raw
        \\raw_target = /dev/stdout
        \\data_format = ascii
        \\ascii_max_range = 100
        \\
    ;
    var file = try std.fs.cwd().createFile("/tmp/cava_natucci.conf", .{});
    defer file.close();
    try file.writeAll(config);

    const argv = &[_][]const u8{ "cava", "-p", "/tmp/cava_natucci.conf" };
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();

    var buf: [1024]u8 = undefined;
    if (child.stdout) |stdout| {
        if (stdout.read(&buf) catch null) |bytes_read| {
            std.debug.print("Got line: {s}\n", .{buf[0..bytes_read]});
        }
    }

    _ = try child.kill();
    _ = try child.wait();
}
