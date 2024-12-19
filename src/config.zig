const std = @import("std");

const alloc = std.heap.page_allocator;
pub var path: []const u8 = "";

pub fn init() !void {
    const file = std.fs.cwd().openFile("options.json", .{ .mode = std.fs.File.OpenMode.read_only }) catch blk: {
        break :blk try std.fs.cwd().createFile("options.json", std.fs.File.CreateFlags{ .read = true });
    };

    var buffer: [100]u8 = undefined;
    const limit = try file.read(&buffer);

    std.debug.print("limit: {d} \n", .{limit});

    if (limit != 0) {
        const json = try std.json.parseFromSlice([]const u8, alloc, buffer[0..limit], .{});
        path = json.value;
    } else {
        path = "C:\\users\\luis\\musics\\";
    }

    file.close();
}
pub fn save() !void {
    const file = try std.fs.cwd().createFile("options.json", std.fs.File.CreateFlags{ .read = true });

    try std.json.stringify(path, .{}, file.writer());

    file.close();
}
