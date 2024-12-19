const music = @import("../music.zig");
const main = @import("../main.zig");
const conf = @import("../config.zig");
const r = @import("renderer.zig");
const std = @import("std");
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_img = @cImport(@cInclude("SDL_image.h"));
const ttf = @cImport(@cInclude("SDL_ttf.h"));

var back_rect: sdl.SDL_Rect = undefined;
var label_rect: sdl.SDL_Rect = undefined;
var button_rect: sdl.SDL_Rect = undefined;
var input_rect: sdl.SDL_Rect = undefined;
var back_texture: ?*sdl_img.SDL_Texture = undefined;
var text: r.text_input = undefined;

pub fn init(screen: *const r.screen) !void {
    const renderer = screen.renderer;

    text = try r.text_input.init(screen);

    try text.set_text(conf.path);

    back_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\back.png");
}

pub fn render(screen: *const r.screen) !void {
    const renderer = screen.renderer;

    _ = try music.play();

    _ = sdl.SDL_SetRenderDrawColor(renderer, 24, 24, 24, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(renderer);

    back_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 0,
        .w = 50,
        .h = 50,
    };
    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(back_texture), null, @ptrCast(&back_rect));

    label_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 65,
        .w = @intCast(screen.w / 2),
        .h = 35,
    };
    const label_surface = ttf.TTF_RenderText(screen.font, "Musics Path:", r.gray, r.background);
    defer sdl.SDL_FreeSurface(@ptrCast(label_surface));

    const label_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(label_surface));
    defer sdl.SDL_DestroyTexture(label_texture);

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(label_texture), null, &label_rect);

    input_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 100,
        .w = @intCast(screen.w),
        .h = 50,
    };
    text.render(input_rect);

    button_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 160,
        .w = @intCast(screen.w / 4),
        .h = 35,
    };
    const button_surface = ttf.TTF_RenderText(screen.font, " Save ", r.white, r.background);
    defer sdl.SDL_FreeSurface(@ptrCast(button_surface));

    const button_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(button_surface));
    defer sdl.SDL_DestroyTexture(button_texture);

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(button_texture), null, &button_rect);

    _ = sdl.SDL_RenderPresent(renderer);
}

pub fn eventHandler(event: sdl.SDL_Event) !void {
    switch (event.type) {
        sdl.SDL_QUIT => {},
        sdl.SDL_MOUSEBUTTONDOWN => {
            text.inFocus = false;
            if (r.isPosInRectBounds(back_rect, event.button.x, event.button.y)) {
                r.navigate(main.screens.player);
            }
            if (r.isPosInRectBounds(input_rect, event.button.x, event.button.y)) {
                text.inFocus = true;
            }
            if (r.isPosInRectBounds(button_rect, event.button.x, event.button.y)) {
                conf.path = std.mem.trim(u8, text.list.items, &std.ascii.whitespace);
                try conf.save();
                try music.list_musics();
            }
        },
        sdl.SDL_TEXTINPUT => {
            if (!text.inFocus) return;
            try text.append_char(event.text.text[0]);
            text.cursor += 1;
        },
        sdl.SDL_KEYDOWN => {
            switch (event.key.keysym.sym) {
                sdl.SDLK_BACKSPACE => {
                    try text.pop_text();
                },
                sdl.SDLK_ESCAPE => {
                    try text.empty_text();
                    text.inFocus = false;
                },
                else => {}
            }
        },
        else => {}
    }
}

pub fn free() !void {
    _ = sdl.SDL_DestroyTexture(@ptrCast(back_texture));
    text.deinit();
}
