const std = @import("std");
const bytesToValue = std.mem.bytesToValue;
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_img = @cImport(@cInclude("SDL_image.h"));
const ttf = @cImport(@cInclude("SDL_ttf.h"));
const music = @import("../music.zig");
const p = @import("./player.zig");
const space_ascci = 32;

pub var quit = false;

pub var mousex: f64 = 0;
pub var mousey: f64 = 0;

pub var w: u32 = 800;
pub var h: u32 = 500;

pub var delay: c_uint = 32;
const alloc = std.heap.page_allocator;
var inputText: std.ArrayList(u8) = std.ArrayList(u8).init(alloc);
var textIndex: u16 = 0;
var seletedIndex: u16 = 0;

pub var font: ?*ttf.TTF_Font = undefined;
pub const fontSize: u16 = 12;
pub const background: ttf.SDL_Color = .{
    .r = 23,
    .g = 23,
    .b = 23,
    .a = 255,
};
pub const gray: ttf.SDL_Color = .{
    .r = 80,
    .g = 80,
    .b = 80,
    .a = 255,
};
pub const red: ttf.SDL_Color = .{
    .r = 255,
    .g = 80,
    .b = 80,
    .a = 255,
};
pub const white: ttf.SDL_Color = .{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

const video = struct {
    renderer: ?*sdl.SDL_Renderer,
    window: ?*sdl.SDL_Window,
    delay: c_uint,
    font: ?*ttf.TTF_Font,
    w: u16,
    h: u16,
    mousex: f64,
    mousex: f64,
};

pub var search_texture: ?*sdl_img.SDL_Texture = undefined;
pub var play_texture: ?*sdl_img.SDL_Texture = undefined;
pub var pause_texture: ?*sdl_img.SDL_Texture = undefined;
pub var prev_texture: ?*sdl_img.SDL_Texture = undefined;
pub var next_texture: ?*sdl_img.SDL_Texture = undefined;

pub var renderer: ?*sdl.SDL_Renderer = undefined;
pub var screen: ?*sdl.SDL_Window = undefined;

pub fn isPosInRectBounds(rect: sdl.SDL_Rect, x: i32, y: i32) bool {
    if (rect.x < x and rect.y < y and y < rect.h + rect.y and x < rect.w + rect.x) {
        return true;
    }
    return false;
}

pub fn init() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    screen = sdl.SDL_CreateWindow("~~~~ RAYWAVEEE ~~~~", 200, 200, @intCast(w), @intCast(h), sdl.SDL_WINDOW_RESIZABLE) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    renderer = sdl.SDL_CreateRenderer(screen, -1, sdl.SDL_RENDERER_SOFTWARE);

    _ = ttf.TTF_Init();

    font = ttf.TTF_OpenFont("C:\\Windows\\Fonts\\arialbi.ttf", fontSize);
    assert(font != null);

    try p.inputText.appendNTimes(space_ascci, 20);

    _ = try music.play();

    search_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\search.png");
    play_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\play.png");
    pause_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\pause.png");
    prev_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\prev.png");
    next_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\next.png");
}
