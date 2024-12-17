const r = @import("renderer.zig");
const music = @import("../music.zig");
const sdl = @cImport(@cInclude("SDL.h"));

pub fn render() !void {
    _ = try music.play();

    _ = sdl.SDL_SetRenderDrawColor(r.renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(r.renderer);
    _ = sdl.SDL_RenderPresent(r.renderer);

    sdl.SDL_Delay(r.delay);
}
