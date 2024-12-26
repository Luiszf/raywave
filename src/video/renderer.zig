const std = @import("std");
const ui = @import("../ui_lib.zig");
const bytesToValue = std.mem.bytesToValue;
const assert = std.debug.assert;

const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});
const music = @import("../music.zig");
const main = @import("../main.zig");
const space_ascci = 32;

pub var delay: c_uint = 32;
const alloc = std.heap.page_allocator;

pub const background: sdl.SDL_Color = .{
    .r = 23,
    .g = 23,
    .b = 23,
    .a = 255,
};
pub const gray: sdl.SDL_Color = .{
    .r = 80,
    .g = 80,
    .b = 80,
    .a = 255,
};
pub const red: sdl.SDL_Color = .{
    .r = 255,
    .g = 80,
    .b = 80,
    .a = 255,
};
pub const white: sdl.SDL_Color = .{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

pub const screen = struct {
    renderer: ?*sdl.SDL_Renderer = undefined,
    window: ?*sdl.SDL_Window = undefined,
    quit: bool = false,
    mousex: f64 = 0,
    mousey: f64 = 0,
    w: u32 = 800,
    h: u32 = 500,
    font: ?*sdl.TTF_Font = undefined,
    fontSize: u16 = 12,
    delay: u16 = 34,
};

pub var new_screen = screen{};

pub fn isPosInRBounds(rect: ui.rect, x: i32, y: i32) bool {
    if (rect.x < x and rect.y < y and y < rect.h + rect.y and x < rect.w + rect.x) {
        return true;
    }
    return false;
}

pub fn isPosInRectBounds(rect: sdl.SDL_Rect, x: i32, y: i32) bool {
    if (rect.x < x and rect.y < y and y < rect.h + rect.y and x < rect.w + rect.x) {
        return true;
    }
    return false;
}

pub fn init(onInit: fn (sc: *const screen) anyerror!void) !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    new_screen.window = sdl.SDL_CreateWindow("~~~~ RAYWAVEEE ~~~~", 200, 200, @intCast(new_screen.w), @intCast(new_screen.h), sdl.SDL_WINDOW_RESIZABLE) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    new_screen.renderer = sdl.SDL_CreateRenderer(new_screen.window, -1, sdl.SDL_RENDERER_SOFTWARE);

    _ = sdl.TTF_Init();

    new_screen.font = sdl.TTF_OpenFont("C:\\Windows\\Fonts\\arialbi.ttf", new_screen.fontSize);
    assert(new_screen.font != null);

    new_screen.delay = 1000;

    try onInit(&new_screen);
}

pub fn render(onRender: fn (sc: *const screen) anyerror!void, handleEvents: fn (event: sdl.SDL_Event) anyerror!void, free: fn () anyerror!void) !void {
    while (!new_screen.quit) {
        try onRender(&new_screen);
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            try handleEvents(event);
            switch (event.type) {
                sdl.SDL_WINDOWEVENT => {
                    sdl.SDL_GetWindowSize(new_screen.window, @ptrCast(&new_screen.w), @ptrCast(&new_screen.h));

                    // TODO: check how sdl gpu usage works and remove this TEMPORARY fix

                    //if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_GAINED) new_screen.delay = 32;
                    //if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_LOST) new_screen.delay = 500;
                },
                sdl.SDL_QUIT => {
                    main.quit = true;
                    new_screen.quit = true;
                },
                sdl.SDL_MOUSEMOTION => {
                    new_screen.mousex = @floatFromInt(event.motion.x);
                    new_screen.mousey = @floatFromInt(event.motion.y);
                },
                else => {}
            }
        }
        sdl.SDL_Delay(new_screen.delay);
    }
    try free();
    new_screen.quit = false;
}

pub fn navigate(id: main.screens) void {
    main.nav = id;
    new_screen.quit = true;
}

pub const text_input = struct {
    const Self = @This();
    screen: *const screen,
    inFocus: bool = false,
    cursor: u8 = 0,
    list: std.ArrayList(u8) = std.ArrayList(u8).init(alloc),

    pub fn init(screen_render: *const screen) !Self {
        var s = Self{
            .screen = screen_render,
        };
        try s.list.appendNTimes(space_ascci, 20);
        return s;
    }
    pub fn empty_text(self: *Self) !void {
        self.list.shrinkAndFree(0);
        try self.list.appendNTimes(space_ascci, 20);
        self.cursor = 0;
    }

    pub fn pop_text(self: *Self) !void {
        if (self.cursor > 0) self.cursor -= 1;
        try self.list.replaceRange(self.cursor, 1, " ");
    }

    pub fn append_text(self: *Self, text: []const u8) !void {
        try self.list.insertSlice(self.cursor, text);
    }

    pub fn append_char(self: *Self, char: u8) !void {
        try self.list.insert(self.cursor, char);
    }

    pub fn set_text(self: *Self, text: []const u8) !void {
        try self.list.appendNTimes(space_ascci, text.len);
        try self.list.replaceRange(0, text.len, text);
        self.cursor = @intCast(text.len);
    }

    pub fn render(self: *Self, rect: sdl.SDL_Rect) void {
        var text_surface: [*c]sdl.SDL_Surface = undefined;

        var box = rect;

        box.x += 2;
        box.y += 2;
        box.w -= 4;
        box.h -= 4;

        _ = sdl.SDL_SetRenderDrawColor(self.screen.renderer, 180, 180, 180, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderDrawRect(self.screen.renderer, &rect);

        text_surface = sdl.TTF_RenderUTF8_LCD(self.screen.font, @ptrCast(self.list.items), white, background);
        defer sdl.SDL_FreeSurface(@ptrCast(text_surface));

        const text_texture = sdl.SDL_CreateTextureFromSurface(self.screen.renderer, @ptrCast(text_surface));
        defer sdl.SDL_DestroyTexture(text_texture);

        _ = sdl.SDL_RenderCopy(self.screen.renderer, @ptrCast(text_texture), null, &box);
    }

    pub fn deinit(self: *Self) void {
        self.list.clearRetainingCapacity();
    }
};
