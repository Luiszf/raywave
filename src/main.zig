const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));
const id3 = @import("./id3.zig");
const renderer = @import("video/renderer.zig");
const black = @import("video/black.zig");
const player = @import("video/player.zig");
const music = @import("./music.zig");
const config = @import("./config.zig");
const settings = @import("./video/settings.zig");

pub var nav: screens = screens.player;
pub var quit = false;

pub fn main() !void {
    try config.init();

    try music.init();

    while (!quit) {
        switch (nav) {
            screens.player => {
                try renderer.init(player.init);
                try renderer.render(player.render, player.eventHandler, player.free);
            },
            screens.settings => {
                try renderer.init(settings.init);
                try renderer.render(settings.render, settings.eventHandler, settings.free);
            },
            else => {
                std.debug.print("{} not implemented yet :( \n", .{nav});
            },
        }
    }
}
pub const screens = enum {
    player,
    settings,
    black,
};
