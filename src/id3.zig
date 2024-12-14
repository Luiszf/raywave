const std = @import("std");
const bytesToValue = std.mem.bytesToValue;
const readInt = std.mem.readInt;
const assert = std.debug.assert;

const FrameTags = enum {
    TPIC,
    TIT2,
    TPE1,
    TYER,
    TXXX,
    TALB,
    TSSE,
    APIC,
    TCON,
    COMM,
};
pub const FileTypes = enum {
    JPG,
    PNG,
    TXT,
};

const Frame = struct {
    frame: [4]u8,
    framesize: u32,
    content: []u8,
    file_type: FileTypes = FileTypes.TXT,

    pub fn getContent(array: *const []u8) []u8 {
        const content = bytesToValue([]u8, array[0..1]);
        return content;
    }
    pub fn getSize(array: []u8) u32 {
        const frame: [4]u8 = bytesToValue([4]u8, array[0..3]);
        if (isValidFrame(frame)) {
            const size: [4]u8 = bytesToValue([4]u8, array[4..7]);
            const contentSize = readInt(u32, &size, std.builtin.Endian.big);
            return contentSize;
        }
        return 0;
    }

    pub fn decode(array: []u8, size: u32) Frame {
        const frame: [4]u8 = bytesToValue([4]u8, array[0..3]);
        const content = getContent(&array[10 .. 10 + size]);
        const frameStruct = Frame{
            .frame = frame,
            .framesize = size,
            .content = content,
        };

        return frameStruct;
    }
    pub fn isValidFrame(tag: [4]u8) bool {
        const tags = @typeInfo(FrameTags).Enum.fields;
        inline for (0..tags.len) |i| {
            if (std.mem.eql(u8, tags[i].name, &tag)) {
                return true;
            }
        }
        return true;
    }
};

pub const Id3Tag = struct {
    id: [3]u8,
    version: u16,
    flags: u8,
    size: u32,
    frames: std.ArrayList(Frame),

    pub fn decode(filePath: []const u8, alloc: std.mem.Allocator) !Id3Tag {
        var file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());

        var array: [500000]u8 = undefined;
        _ = try buf_reader.read(&array);

        if (std.mem.containsAtLeast(u8, &array, 1, "unicode")) {
            std.debug.print("it has unicode \n", .{});
        }

        var size: [4]u8 = bytesToValue([4]u8, array[6..9]);

        std.mem.reverse(u8, size[0..]);
        var total: u32 = 0;
        for (0..3) |i| {
            total += size[i] * std.math.pow(u32, 128, @intCast(i));
        }

        var fistIndex: u32 = 10;
        var lastIndex: u32 = 20;
        var index: u32 = 0;
        var frames = std.ArrayList(Frame).init(alloc);
        while (fistIndex < total) {
            const frameSize = Frame.getSize(array[fistIndex..lastIndex]);
            if (lastIndex + frameSize > array.len or frameSize == 0) {
                break;
            }
            var frame = Frame.decode(array[fistIndex .. lastIndex + frameSize], frameSize);
            if (std.mem.eql(u8, &frame.frame, "APIC")) {
                var begin: u32 = 0;
                for (0..100) |i| {
                    // jpeg
                    const isJpg = std.mem.eql(u8, frame.content[i .. i + 2], &.{ 0xFF, 0xd8 });
                    if (isJpg) {
                        begin = @intCast(i);
                        frame.file_type = FileTypes.JPG;
                        break;
                    }
                    // png
                    //89 50 4E 47 0D 0A 1A 0A
                    const isPng = std.mem.eql(u8, frame.content[i .. i + 8], &.{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
                    if (isPng) {
                        begin = @intCast(i);
                        frame.file_type = FileTypes.PNG;
                        break;
                    }
                }
                frame.content = frame.content[begin..];
            }
            fistIndex = lastIndex + frameSize;
            lastIndex = fistIndex + 10;

            try frames.append(frame);

            index += 1;
        }

        const id3 = Id3Tag{
            .id = bytesToValue([3]u8, array[0..2]),
            .version = bytesToValue(u16, array[3..4]),
            .flags = array[5],
            .size = total,
            .frames = frames,
        };
        return id3;
    }
};
fn tests() !void {
    const alloc = std.heap.page_allocator;
    var music_name: std.ArrayList(u8) = std.ArrayList(u8).init(alloc);

    var iter = (try std.fs.openDirAbsolute(
        "C:\\Users\\Luis\\musics",
        .{ .iterate = true },
    )).iterate();

    var index: u16 = 0;
    while (try iter.next()) |entry| {
        if (entry.kind == .file) {
            if (!std.mem.endsWith(u8, entry.name, ".mp3")) {
                continue;
            }
            index += 1;
            try music_name.appendSlice("C:\\Users\\Luis\\musics\\");
            try music_name.appendSlice(entry.name);
            std.debug.print(" ------------------     {s}      ------------------------- \n", .{music_name.items});

            const id3tag = try Id3Tag.decode(music_name.items, alloc);

            music_name.clearRetainingCapacity();
            try music_name.appendSlice("src/res/");
            try music_name.appendSlice(entry.name);
            _ = music_name.pop();
            _ = music_name.pop();
            _ = music_name.pop();
            _ = music_name.pop();

            for (id3tag.frames.items) |value| {
                if (std.mem.eql(u8, &value.frame, "APIC")) {
                    _ = switch (value.file_type) {
                        .JPG => try music_name.appendSlice(".jpg"),
                        .PNG => try music_name.appendSlice(".png"),
                        else => {},
                    };
                    const filex = try std.fs.cwd().createFile(music_name.items, .{});
                    _ = try filex.write(value.content);
                    filex.close();
                }
            }
            music_name.clearRetainingCapacity();
        }
    }
}
