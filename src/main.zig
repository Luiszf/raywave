const std = @import("std");
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_mixer = @cImport(@cInclude("SDL_mixer.h"));
const hook = @cImport(@cInclude("uiohook.h"));

const music = @import("./music.zig");

var quit = false;

pub fn main() !void {
    try music.init();

    // video
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const screen = sdl.SDL_CreateWindow("My Game Window", 400, 400, 800, 400, sdl.SDL_WINDOW_OPENGL) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyWindow(screen);

    const renderer: ?*sdl.SDL_Renderer = sdl.SDL_CreateRenderer(screen, -1, sdl.SDL_RENDERER_ACCELERATED);
    const rect: sdl.SDL_Rect = .{
        .x = 0,
        .y = 0,
        .w = 40,
        .h = 40,
    };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 18, 18, 18, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(renderer);

    while (!quit) {
        _ = sdl.SDL_RenderDrawRect(renderer, @ptrCast(&rect));
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&rect));
        _ = sdl.SDL_RenderPresent(renderer);

        var event: sdl.SDL_Event = undefined;
        quit = music.play();

        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        sdl.SDL_Delay(34);
    }
}
