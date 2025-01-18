const std = @import("std");
const id3 = @import("./id3.zig");
const black = @import("video/black.zig");
const player = @import("video/player.zig");
const ui = @import("ui_lib.zig");
const music = @import("./music.zig");
const config = @import("./config.zig");
const settings = @import("./video/settings.zig");
const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
});

pub var nav: screens = screens.player;
pub var quit = false;
pub var w: u16 = 800;
pub var h: u16 = 500;

pub fn main() !void {
    try config.init();
    try music.init();
    const s = try ui.initScreen();
    try black.render(s);
}
pub const screens = enum {
    player,
    settings,
    black,
};
