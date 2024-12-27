const std = @import("std");
const bytesToValue = std.mem.bytesToValue;
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_img = @cImport(@cInclude("SDL_image.h"));
const ttf = @cImport(@cInclude("SDL_ttf.h"));
const music = @import("../music.zig");
const main = @import("../main.zig");
const r = @import("./renderer.zig");
const space_ascii = 32;

var listCapacity: u16 = 8;
var cursor: u16 = 0;
var page: u16 = 0;
var searchPage: u16 = 0;
var barOnFocus = false;
var seletedIndex: u16 = 0;

var text_input: r.text_input = undefined;

var text_rect: sdl.SDL_Rect = undefined;
var search_rect: sdl.SDL_Rect = undefined;
var list_rect: sdl.SDL_Rect = undefined;
var play_rect: sdl.SDL_Rect = undefined;
var prev_rect: sdl.SDL_Rect = undefined;
var loop_rect: sdl.SDL_Rect = undefined;
var shuffle_rect: sdl.SDL_Rect = undefined;
var next_rect: sdl.SDL_Rect = undefined;
var bar_rect: sdl.SDL_Rect = undefined;
var progress_rect: sdl.SDL_Rect = undefined;
var settings_rect: sdl.SDL_Rect = undefined;

pub var search_texture: ?*sdl_img.SDL_Texture = undefined;
pub var play_texture: ?*sdl_img.SDL_Texture = undefined;
pub var pause_texture: ?*sdl_img.SDL_Texture = undefined;
pub var prev_texture: ?*sdl_img.SDL_Texture = undefined;
pub var next_texture: ?*sdl_img.SDL_Texture = undefined;
pub var shuffle_texture: ?*sdl_img.SDL_Texture = undefined;
pub var loop_texture: ?*sdl_img.SDL_Texture = undefined;
pub var settings_texture: ?*sdl_img.SDL_Texture = undefined;

var font: ?*ttf.TTF_Font = undefined;
var fontSize: u16 = 12;

var white: ttf.SDL_Color = undefined;
var background: ttf.SDL_Color = undefined;
var red: ttf.SDL_Color = undefined;

pub fn init(screen: *const r.screen) !void {
    const renderer = screen.renderer;
    font = screen.font;
    fontSize = screen.fontSize;

    white = r.white;
    background = r.background;
    red = r.red;

    text_input = try r.text_input.init(screen);

    _ = try music.play();

    search_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\search.png");
    play_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\play.png");
    pause_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\pause.png");
    prev_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\prev.png");
    shuffle_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\shuffle.png");
    loop_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\repeat.png");
    next_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\next.png");
    settings_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "C:\\users\\luis\\Development\\raywave\\src\\res\\settings.png");
}

pub fn render(screen: *const r.screen) !void {
    const renderer = screen.renderer;
    const h = screen.h;
    const w = screen.w;
    const mousex = screen.mousex;

    if (try music.play()) {
        page = @divTrunc((music.index), listCapacity);
        cursor = (music.index) % listCapacity;
    }

    listCapacity = @intCast((screen.h - 100) / 50);

    _ = sdl.SDL_SetRenderDrawColor(renderer, 23, 23, 23, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(renderer);

    text_rect = .{
        .y = 2,
        .w = @intCast(fontSize * text_input.list.items.len),
        .h = 46,
    };
    text_rect.x = @intCast((w - (fontSize * text_input.list.items.len)) / 2);

    text_input.render(text_rect);

    if (text_input.inFocus) _ = sdl.SDL_SetTextureAlphaMod(@ptrCast(search_texture), sdl.SDL_ALPHA_TRANSPARENT);
    if (!text_input.inFocus) _ = sdl.SDL_SetTextureAlphaMod(@ptrCast(search_texture), sdl.SDL_ALPHA_OPAQUE);

    search_rect = .{
        .x = text_rect.x,
        .y = text_rect.y,
        .w = 46,
        .h = 46,
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(search_texture), null, &search_rect);

    settings_rect = .{
        .x = @intCast(w - 50),
        .y = 0,
        .w = 50,
        .h = 50,
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(settings_texture), null, &settings_rect);

    list_rect = .{
        .x = 0,
        .y = 50,
        .w = @intCast(w),
        .h = @intCast(50 * listCapacity),
    };
    if (text_input.inFocus and text_input.list.items.len > 0) {
        const query = std.mem.trim(u8, text_input.list.items, &std.ascii.whitespace);
        try list(renderer, music.musics.items, listCapacity, list_rect, query);
    } else {
        try list(renderer, music.musics.items, listCapacity, list_rect, "");
    }

    play_rect = .{
        .w = 30,
        .h = 30,
        .y = @intCast(h - 46),
        .x = @intCast((w - 30) / 2),
    };

    if (music.isPaused) {
        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(play_texture), null, @ptrCast(&play_rect));
    } else {
        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(pause_texture), null, @ptrCast(&play_rect));
    }

    prev_rect = .{
        .w = 30,
        .h = 30,
        .y = @intCast(h - 46),
        .x = @intCast(play_rect.x - 60),
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(prev_texture), null, @ptrCast(&prev_rect));

    shuffle_rect = .{
        .w = 30,
        .h = 30,
        .y = @intCast(h - 46),
        .x = @intCast(play_rect.x - 120),
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(shuffle_texture), null, @ptrCast(&shuffle_rect));

    loop_rect = .{
        .w = 30,
        .h = 30,
        .y = @intCast(h - 46),
        .x = @intCast(play_rect.x + 120),
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(loop_texture), null, @ptrCast(&loop_rect));

    next_rect = .{
        .w = 30,
        .h = 30,
        .y = @intCast(h - 46),
        .x = @intCast(play_rect.x + 60),
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(next_texture), null, @ptrCast(&next_rect));

    bar_rect = .{
        .x = 0,
        .y = @intCast(h - 12),
        .w = @intCast(w),
        .h = 8,
    };

    _ = sdl.SDL_SetRenderDrawColor(renderer, 95, 95, 95, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&bar_rect));

    const width: f64 = @floatFromInt(w);
    if (barOnFocus) {
        const position = (mousex / width) * music.getCurDuration();
        music.setPosition(position);
    }

    const progress: f64 = (width / music.getCurDuration()) * music.getCurPosition();
    progress_rect = .{
        .x = 0,
        .y = @intCast(h - 12),
        .w = @intFromFloat(progress),
        .h = 8,
    };

    _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&progress_rect));

    _ = sdl.SDL_RenderPresent(renderer);
}
pub fn eventHandler(event: sdl.SDL_Event) !void {
    switch (event.type) {
        sdl.SDL_TEXTINPUT => {
            if (text_input.inFocus) {
                try text_input.append_char(event.text.text[0]);
                text_input.cursor += 1;
            }
        },
        sdl.SDL_KEYDOWN => {
            switch (event.key.keysym.sym) {
                sdl.SDLK_RETURN => {
                    try playUnderCursor();
                },
                sdl.SDLK_BACKSPACE => {
                    try text_input.pop_text();
                },
                sdl.SDLK_ESCAPE => {
                    try text_input.empty_text();
                    text_input.inFocus = false;
                },
                sdl.SDLK_DOWN => {
                    cursorNext();
                },
                sdl.SDLK_UP => {
                    cursorPrev();
                },
                else => {}
            }
        },

        sdl.SDL_MOUSEBUTTONDOWN => {
            if (r.isPosInRectBounds(play_rect, event.button.x, event.button.y)) {
                music.pauseMusic();
            }
            if (r.isPosInRectBounds(prev_rect, event.button.x, event.button.y)) {
                music.prevMusic();
            }
            if (r.isPosInRectBounds(next_rect, event.button.x, event.button.y)) {
                music.nextMusic();
            }
            if (r.isPosInRectBounds(text_rect, event.button.x, event.button.y)) {
                text_input.inFocus = !text_input.inFocus;
            }
            if (r.isPosInRectBounds(bar_rect, event.button.x, event.button.y)) {
                barOnFocus = true;
                music.pauseMusic();
            }
            if (r.isPosInRectBounds(settings_rect, event.button.x, event.button.y)) {
                r.navigate(main.screens.settings);
            }
            if (r.isPosInRectBounds(list_rect, event.button.x, event.button.y)) {
                const list_h = event.button.y - list_rect.y;
                const item_number = @divFloor(list_h, 50);

                if (cursor == item_number) {
                    try playUnderCursor();
                } else {
                    cursor = @intCast(item_number);
                }
            }
        },
        sdl.SDL_MOUSEWHEEL => {
            if (event.wheel.y > 0) {
                cursorPrev();
            }
            if (event.wheel.y < 0) {
                cursorNext();
            }
        },
        sdl.SDL_MOUSEBUTTONUP => {
            if (barOnFocus) {
                music.pauseMusic();
                barOnFocus = false;
            }
        },
        else => {},
    }
}
pub fn free() !void {
    sdl.SDL_DestroyTexture(@ptrCast(search_texture));
    sdl.SDL_DestroyTexture(@ptrCast(play_texture));
    sdl.SDL_DestroyTexture(@ptrCast(pause_texture));
    sdl.SDL_DestroyTexture(@ptrCast(prev_texture));
    sdl.SDL_DestroyTexture(@ptrCast(next_texture));
    text_input.deinit();
}

fn playUnderCursor() !void {
    if (text_input.inFocus) {
        var matchIndex: u16 = 0;
        for (music.musics.items, 0..) |value, i| {
            const input = std.mem.trim(u8, text_input.list.items, &std.ascii.whitespace);
            const isEqual = filterEql(value, input);
            if (!isEqual) continue;
            if (matchIndex == (cursor + (searchPage * listCapacity))) {
                try music.insertSongToNextIndex(@intCast(i));
                break;
            } else {
                matchIndex += 1;
            }
        }
    } else {
        try music.playSongInIndex(cursor + (page * listCapacity));
    }
}
fn cursorNext() void {
    if (cursor == (listCapacity - 1)) {
        cursor = 0;
        if (text_input.inFocus) {
            searchPage += 1;
        } else {
            page += 1;
        }
        return;
    }
    cursor += 1;
}
fn cursorPrev() void {
    if (cursor == 0) {
        cursor = (listCapacity - 1);
        if (text_input.inFocus) {
            if (searchPage > 0) searchPage -= 1;
        } else {
            if (page > 0) page -= 1;
        }
        return;
    }
    cursor -= 1;
}
fn filterEql(musicName: []const u8, query: []const u8) bool {
    if (query.len == 0) return true;
    if (query.len > musicName.len) return false;
    var musicUpper: [255]u8 = undefined;
    _ = std.ascii.upperString(&musicUpper, musicName);
    var queryUpper: [255]u8 = undefined;
    _ = std.ascii.upperString(&queryUpper, query);
    const input = std.mem.trim(u8, &queryUpper, &std.ascii.whitespace);
    const isEqual = std.mem.containsAtLeast(u8, &musicUpper, 1, input[0..query.len]);
    return isEqual;
}

fn list(renderer: ?*sdl.SDL_Renderer, totalItems: [][]u8, capacity: u16, rect: sdl.SDL_Rect, query: []const u8) !void {
    var item: u16 = 0;
    var matchNumber: u16 = 0;
    var index: u16 = 0;
    while (item < capacity) {
        var style: u8 = 0;
        if (totalItems.len - 1 < index) return;
        var itemName: []const u8 = totalItems[index];
        if (!filterEql(itemName, query)) {
            index += 1;
            continue;
        }
        if (item == cursor) style = 1;
        if (index == music.index) style = 2;
        if (item == cursor and index == music.index) style = 3;

        matchNumber += 1;
        index += 1;

        if (text_input.inFocus) {
            if ((matchNumber - 1) < (searchPage * capacity)) continue;
        } else {
            if ((matchNumber - 1) < (page * capacity)) continue;
        }
        var split = std.mem.split(u8, itemName, "\\");
        while (split.next()) |value| {
            itemName = value;
        }

        listItem(renderer, itemName, @intCast(@divFloor(rect.h, capacity)), item, style, @intCast(rect.y));
        item += 1;
    }
}
fn listItem(renderer: ?*sdl.SDL_Renderer, text: []const u8, height: u16, index: usize, style: u8, offset: u8) void {
    var name_surface: [*c]ttf.SDL_Surface = undefined;

    switch (style) {
        0 => name_surface = ttf.TTF_RenderText_LCD(font, @ptrCast(text), white, background),
        1 => name_surface = ttf.TTF_RenderText_LCD(font, @ptrCast(text), background, white),
        2 => name_surface = ttf.TTF_RenderText_LCD(font, @ptrCast(text), red, background),
        3 => name_surface = ttf.TTF_RenderText_LCD(font, @ptrCast(text), red, white),
        else => {
            std.debug.print("unknown style for list item: {d} \n", .{style});
        }
    }
    defer sdl.SDL_FreeSurface(@ptrCast(name_surface));

    const name_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(name_surface));
    defer sdl.SDL_DestroyTexture(name_texture);

    const name_rect: sdl.SDL_Rect = .{
        .x = 0,
        .y = @intCast((height * index) + offset),
        .w = @intCast(fontSize * text.len),
        .h = height,
    };

    _ = sdl.SDL_RenderCopy(renderer, @ptrCast(name_texture), null, &name_rect);
}
