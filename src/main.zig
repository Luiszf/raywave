const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));
const id3 = @import("./id3.zig");
const renderer = @import("video/renderer.zig");
const player = @import("video/player.zig");
const black = @import("video/black.zig");
const music = @import("./music.zig");
const settings = @import("./settings.zig");

pub fn main() !void {
    try settings.init();

    try music.init();

    try renderer.init();

    while (!renderer.quit) {
        if (music.index % 2 == 1) {
            try player.render();
        } else {
            try black.render();
        }
    }
}
