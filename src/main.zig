const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));
const id3 = @import("./id3.zig");
const video = @import("./video.zig");
const music = @import("./music.zig");

pub fn main() !void {
    try music.init();
    for (0..12) |i| {
        _ = i;
        music.volumeDown();
    }

    try video.mediaBar();
}
