const music = @import("../music.zig");
const r = @import("renderer.zig");
const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));

pub fn init(screen: *const r.screen) !void {
    _ = screen;
}

pub fn render(screen: *const r.screen) !void {
    const renderer = screen.renderer;

    _ = try music.play();

    _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(renderer);
    _ = sdl.SDL_RenderPresent(renderer);
}

pub fn eventHandler(event: sdl.SDL_Event) !void {
    switch (event.type) {
        sdl.SDL_QUIT => {},
        else => {}
    }
}

pub fn free() !void {}
