const ui = @import("../ui_lib.zig");
const r = @import("renderer.zig");
const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});

pub fn init(screen: *const r.screen) !void {
    _ = screen;
    std.debug.print("chegou legal", .{});
}

var window = ui.element{ .gap = 1, .orientation = ui.orientation.vertical_inverted, .color = ui.colors.background };
var color = [_]u8{ 40, 40, 40, 255 };
var count: u8 = 0;

pub fn render(screen: *const r.screen) !void {
    const renderer = screen.renderer;

    window.area = ui.rect{ .x = 0, .y = 0, .h = @intCast(screen.h), .w = @intCast(screen.w) };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(renderer);

    var list = ui.element{ .orientation = ui.orientation.vertical, .size = 9, .gap = 4, .color = ui.colors.background };
    try list.add_many(@intCast((screen.h + count) / 50));

    for (0..list.childs.?.len) |i| {
        list.childs.?[i].format = ui.format{ .text = "uhuuuuuu" };
    }

    try window.add_many(2);
    window.childs.?[0] = list;
    window.render(renderer);
    _ = sdl.SDL_RenderPresent(renderer);
}
pub fn onClickMenu(x: i32, y: i32) void {
    std.debug.print("click on menu x:{d} -- y:{d} \n", .{ x, y });
}

pub fn eventHandler(event: sdl.SDL_Event) !void {
    switch (event.type) {
        sdl.SDL_QUIT => {},
        sdl.SDL_MOUSEBUTTONDOWN => {},
        else => {}
    }
}

pub fn free() !void {}
