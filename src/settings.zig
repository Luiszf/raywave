const std = @import("std");

const alloc = std.heap.page_allocator;
pub var path: []const u8 = "";

pub fn init() !void {
    const file = try std.fs.cwd().openFile("options.json", .{});

    var buffer: [100]u8 = undefined;
    const limit = try file.read(&buffer);

    const json = try std.json.parseFromSlice([]const u8, alloc, buffer[0..limit], .{});
    path = json.value;
}
pub fn save() !void {
    const file = try std.fs.cwd().openFile("options.json", .{ .mode = std.fs.File.OpenMode.read_write });
    try std.json.stringify(path, .{}, file.writer());
}
