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
    var child = try allocator.create(std.process.Child);
    child.* = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();

    var running = std.atomic.Value(bool).init(true);
    var thread = try std.Thread.spawn(.{}, cavaReaderThread, .{child, &running});

    std.Thread.sleep(1 * std.time.ns_per_s);
    std.debug.print("Stopping cava...\n", .{});
    running.store(false, .seq_cst);
    _ = child.kill() catch {};
    _ = child.wait() catch {};
    thread.join();
    std.debug.print("Done.\n", .{});
}

fn cavaReaderThread(child: *std.process.Child, running: *std.atomic.Value(bool)) void {
    const stdout = child.stdout orelse return;
    var buf: [4096]u8 = undefined;
    var buf_len: usize = 0;

    while (running.load(.seq_cst)) {
        if (buf_len >= buf.len) {
            buf_len = 0; // reset to avoid overflow if missing \n
        }

        const bytes_read = stdout.read(buf[buf_len..]) catch 0;
        if (bytes_read == 0) {
            break;
        }
        buf_len += bytes_read;

        while (true) {
            if (std.mem.indexOfScalar(u8, buf[0..buf_len], '\n')) |idx| {
                const line = buf[0..idx];
                var it = std.mem.splitScalar(u8, line, ';');
                var i: usize = 0;
                while (it.next()) |val_str| {
                    if (val_str.len == 0) continue;
                    if (std.fmt.parseInt(u8, val_str, 10)) |_| {
                        i += 1;
                    } else |_| {}
                }
                const remaining = buf_len - (idx + 1);
                std.mem.copyForwards(u8, buf[0..remaining], buf[idx + 1 .. buf_len]);
                buf_len = remaining;
            } else {
                break;
            }
        }
    }
}
