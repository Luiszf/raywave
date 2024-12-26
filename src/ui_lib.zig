const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});
const std = @import("std");
const rdr = @import("video/renderer.zig");

const alloc = std.heap.page_allocator;

pub const formatTag = enum { text, image, rect, textinput };

pub const format = union(formatTag) {
    text: []const u8,
    image: []const u8,
    rect: void,
    textinput: []u8,
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
    childs: ?[]element = null,
    onclick: ?*const fn (x: u16, y: u16) void = null,

    pub fn add(self: *Self, el: element) !void {
        var elements = std.ArrayList(element).init(alloc);
        try elements.appendSlice(self.childs);
        try elements.append(el);
        self.childs = elements.items;
    }

    pub fn add_many(self: *Self, count: u8) !void {
        var elements = std.ArrayList(element).init(alloc);
        for (0..count) |i| {
            _ = i;
            const el = element{};
            try elements.append(el);
        }
        self.childs = elements.items;
    }

    pub fn fill(self: *Self, renderer: ?*sdl.SDL_Renderer) void {
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
                    self.childs.?[i].render(renderer);
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
                    self.childs.?[i].render(renderer);
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
                    self.childs.?[i].render(renderer);
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
            else => {
                self.render_rect_fill(renderer);
            }
        }
        if (self.childs == null) return;
        self.fill(renderer);
    }
    pub fn render_image(self: *const Self, renderer: ?*sdl.SDL_Renderer, path: []const u8) void {
        const text = sdl.IMG_LoadTexture(renderer, @ptrCast(path));
        _ = sdl.SDL_RenderCopy(renderer, text, null, @ptrCast(&rect.toSdl(self.area)));
    }

    pub fn render_text(self: *const Self, renderer: ?*sdl.SDL_Renderer, text: []const u8) void {
        const text_surface = sdl.TTF_RenderUTF8_LCD(rdr.new_screen.font, @ptrCast(text), rdr.white, rdr.background);
        defer sdl.SDL_FreeSurface(@ptrCast(text_surface));

        const text_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(text_surface));
        defer sdl.SDL_DestroyTexture(text_texture);

        const text_area = rect{
            .x = self.area.x,
            .y = self.area.y,
            .w = @intCast(text.len * 16),
            .h = self.area.h,
        };

        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(text_texture), null, @ptrCast(&rect.toSdl(text_area)));
    }

    pub fn render_rect(self: *const Self, renderer: ?*sdl.SDL_Renderer) void {
        _ = sdl.SDL_SetRenderDrawColor(renderer, @intCast(self.color[0]), @intCast(self.color[1]), @intCast(self.color[2]), @intCast(self.color[3]));
        _ = sdl.SDL_RenderDrawRect(renderer, @ptrCast(&rect.toSdl(self.area)));
    }

    pub fn render_rect_fill(self: *const Self, renderer: ?*sdl.SDL_Renderer) void {
        std.debug.print("color: {d} {d} {d} {d} \n", .{ (self.color[0]), (self.color[1]), (self.color[2]), (self.color[3]) });
        std.debug.print("area: x:{d} y:{d} w:{d} h:{d} \n", .{ self.area.x, self.area.y, self.area.w, self.area.h });
        _ = sdl.SDL_SetRenderDrawColor(renderer, @intCast(self.color[0]), @intCast(self.color[1]), @intCast(self.color[2]), @intCast(self.color[3]));
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&rect.toSdl(self.area)));
    }
};

pub const colors = struct {
    pub const background = [_]u8{ 24, 24, 24, 255 };
};
