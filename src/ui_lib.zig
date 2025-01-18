const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});
const std = @import("std");

const alloc = std.heap.page_allocator;

pub const screen = struct {
    renderer: ?*sdl.SDL_Renderer = undefined,
    window: ?*sdl.SDL_Window = undefined,
    quit: bool = false,
    mousex: i32 = 0,
    mousey: i32 = 0,
    w: u32 = 800,
    h: u32 = 500,
    font: ?*sdl.TTF_Font = undefined,
    fontSize: u16 = 36,
    delay: u16 = 34,
};

pub var main = screen{};

pub fn initScreen() !*const screen {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }

    main.window = sdl.SDL_CreateWindow("~~~~ RAYWAVEEE ~~~~", 200, 200, @intCast(main.w), @intCast(main.h), sdl.SDL_WINDOW_RESIZABLE) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    main.renderer = sdl.SDL_CreateRenderer(main.window, -1, sdl.SDL_RENDERER_SOFTWARE);

    _ = sdl.TTF_Init();

    main.font = sdl.TTF_OpenFont("C:\\Windows\\Fonts\\arialbi.ttf", main.fontSize);
    if (main.font == null) {
        std.debug.panic("could not find font", .{});
    }

    return &main;
}



pub const formatTag = enum { text, image, rect, textinput };

pub const format = union(formatTag) {
    text: []const u8,
    image: []const u8,
    rect: void,
    textinput: *textField,
};

pub const textField = struct {
    const Self = @This();

    inFocus: bool = false,
    cursor: u16 = 0,
    text: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) !Self {
        var s = Self{
            .text = std.ArrayList(u8).init(allocator)
        };
        try s.text.appendNTimes(32, 20);
        return s;
    }
 

    pub fn empty_text(self: *Self) !void {
        self.text.shrinkAndFree(0);
        try self.text.appendNTimes(32, 20);
        self.cursor = 0;
    }

    pub fn pop_char(self: *Self) !void {
        if (self.cursor > 0) self.cursor -= 1;
        try self.text.replaceRange(self.cursor, 1, " ");
    }

    pub fn append_char(self: *Self, char: u8) !void {
        try self.text.insert(self.cursor, char);
        self.cursor += 1;
    }
};

pub const rect = struct {
    x: i16 = 0,
    y: i16 = 0,
    h: i16 = 0,
    w: i16 = 0,

    pub fn toSdl(r: rect) sdl.SDL_Rect {
        return sdl.SDL_Rect{
            .x = @intCast(r.x),
            .y = @intCast(r.y),
            .h = @intCast(r.h),
            .w = @intCast(r.w),
        };
    }
};

pub const orientation = enum {
    vertical,
    horizontal,
    vertical_inverted,
    horizontal_inverted,
};

pub const element = struct {
    const Self = @This();

    area: rect = rect{},
    color: [4]u8 = [4]u8{ 0, 0, 0, 255 },
    size: u8 = 1,
    gap: u8 = 0,
    offset: i8 = 0,
    format: format = format.rect,
    orientation: orientation = orientation.horizontal,
    childs: ?[]*element = null,
    onclick: ?*const fn (self: *Self) void = null,
    elements: std.ArrayList(*element) = std.ArrayList(*element).init(alloc),

    pub fn add(self: *Self, el:*element) !void {
        var newElements = std.ArrayList(*element).init(alloc);
        if(self.childs != null) {
            try newElements.appendSlice(self.childs.?);
        }
        try newElements.append(el);

        self.elements.deinit();
        self.elements = newElements;

        self.childs = self.elements.items;
    }

    pub fn fill(self: *Self) void {
        if (self.childs == null) return;
        const gap = self.gap;

        switch (self.orientation) {
            orientation.horizontal => {
                var sizes: u8 = 0;
                var countx: i16 = self.area.x;

                for (self.childs.?) |value| {
                    sizes += value.size;
                }
                for (self.childs.?, 0..) |value, i| {
                    const width = @divFloor(self.area.w, sizes) * value.size;

                    const area = rect{
                        .x = @intCast(countx + gap - self.offset),
                        .y = gap + self.area.y,
                        .w = width - gap,
                        .h = self.area.h - gap,
                    };

                    countx += width;

                    self.childs.?[i].area = area;
                    self.childs.?[i].fill();
                }
            },
            orientation.vertical => {
                var sizes: u8 = 0;
                var county: i16 = self.area.y;

                for (self.childs.?) |value| {
                    sizes += value.size;
                }
                for (self.childs.?, 0..) |value, i| {
                    const height = @divFloor(self.area.h, sizes) * value.size;

                    const area = rect{
                        .x = gap + self.area.x,
                        .y = @intCast(county + gap - self.offset),
                        .h = height - (gap * 2),
                        .w = self.area.w - (gap * 2),
                    };

                    county += height;

                    self.childs.?[i].area = area;
                    self.childs.?[i].fill();
                }
            },
            orientation.horizontal_inverted => {},
            orientation.vertical_inverted => {
                var sizes: u8 = 0;
                var county: i16 = self.area.y + self.area.h;

                for (self.childs.?) |value| {
                    sizes += value.size;
                }
                for (self.childs.?, 0..) |value, i| {
                    const height = @divFloor(self.area.h, sizes) * value.size;

                    county -= height;

                    const area = rect{
                        .x = gap + self.area.x,
                        .y = @intCast(county + gap + self.offset),
                        .h = height - (gap * 2),
                        .w = self.area.w - (gap * 2),
                    };

                    self.childs.?[i].area = area;
                    self.childs.?[i].fill();
                }
            },
        }
    }

    pub fn render(self: *Self, renderer: ?*sdl.SDL_Renderer) void {
       switch (self.format) {
            format.image => |path| {
                self.render_image(renderer, path);
            },
            format.text => |text| {
                self.render_text(renderer, text);
            },
            format.textinput => |textinput| {
                self.render_text(renderer, textinput.text.items);
            },
            else => {
                self.render_rect_fill(renderer);
            }
        }
        if (self.childs == null) return;
        for(0..self.childs.?.len)|i| {
            self.childs.?[i].render(renderer);
        }
        self.elements.deinit();
    }

    pub fn render_image(self: *const Self, renderer: ?*sdl.SDL_Renderer, path: []const u8) void {
        const text = sdl.IMG_LoadTexture(renderer, @ptrCast(path));
        defer sdl.SDL_DestroyTexture(text);

        _ = sdl.SDL_RenderCopy(renderer, text, null, @ptrCast(&rect.toSdl(self.area)));
    }

    pub fn render_text(self: *const Self, renderer: ?*sdl.SDL_Renderer, text: []const u8) void {
        const text_surface = sdl.TTF_RenderUTF8_LCD(main.font, @ptrCast(text), white, toSDLcolor(self.color));
        defer sdl.SDL_FreeSurface(@ptrCast(text_surface));

        const text_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(text_surface));
        defer sdl.SDL_DestroyTexture(text_texture);

        const text_area = rect{
            .x = self.area.x,
            .y = self.area.y,
            .w = @intCast(text.len * 12),
            .h = self.area.h,
        };

        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(text_texture), null, @ptrCast(&rect.toSdl(text_area)));
    }

    pub fn render_rect(self: *const Self, renderer: ?*sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, @intCast(self.color[0]), @intCast(self.color[1]), @intCast(self.color[2]), @intCast(self.color[3]));
        _ = sdl.SDL_RenderDrawRect(renderer, @ptrCast(&rect.toSdl(self.area)));
    }

    pub fn render_rect_fill(self: *const Self, renderer: ?*sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, @intCast(self.color[0]), @intCast(self.color[1]), @intCast(self.color[2]), @intCast(self.color[3]));
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&rect.toSdl(self.area)));
    }

    pub fn handleEvent(self: *Self, event: sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_WINDOWEVENT => {
                sdl.SDL_GetWindowSize(main.window, @ptrCast(&main.w), @ptrCast(&main.h));

                // TODO: check how sdl gpu usage works and remove this TEMPORARY fix

                if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_GAINED) main.delay = 32;
                if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_LOST) main.delay = 500;
            },
            sdl.SDL_QUIT => {
                main.quit = true;
            },
            sdl.SDL_MOUSEMOTION => {
                main.mousex = event.motion.x;
                main.mousey = event.motion.y;
          },

            sdl.SDL_MOUSEBUTTONDOWN => {
                if (self.onclick != null) {
                    if (isPosInRBounds(self.area, event.button.x, event.button.y)) {
                        self.onclick.?(self);
                    }
                }
            },
            else => {},
        }
        if (self.childs == null) return;
        for(self.childs.?, 0..)|value, i| {
            _ = value;
            self.childs.?[i].handleEvent(event);
        }
    }
};

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
    .r = 200,
    .g = 200,
    .b = 200,
    .a = 255,
};

pub const colors = struct {
    pub const background = [_]u8{ 24, 24, 24, 255 };
};

pub fn toSDLcolor(color: [4]u8) sdl.SDL_Color {
    return sdl.SDL_Color {
        .r = color[0],
        .g = color[1],
        .b = color[2],
        .a = color[3],
    };
}

pub fn isPosInRBounds(area: rect, x: i32, y: i32) bool {
    if (area.x < x and area.y < y and y < area.h + area.y and x < area.w + area.x) {
        return true;
    }
    return false;
}
