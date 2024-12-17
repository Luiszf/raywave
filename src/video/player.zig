const std = @import("std");
const bytesToValue = std.mem.bytesToValue;
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_img = @cImport(@cInclude("SDL_image.h"));
const ttf = @cImport(@cInclude("SDL_ttf.h"));
const music = @import("../music.zig");
const r = @import("./renderer.zig");

var listCapacity: u16 = 8;
var cursor: u16 = 0;
var page: u16 = 0;
var searchPage: u16 = 0;
var inFocus = false;
var barOnFocus = false;

const alloc = std.heap.page_allocator;
pub var inputText: std.ArrayList(u8) = std.ArrayList(u8).init(alloc);
var textIndex: u16 = 0;
var seletedIndex: u16 = 0;

pub fn render() !void {
    if (try music.play()) {
        page = @divTrunc((music.index), listCapacity);
        cursor = (music.index) % listCapacity;
    }

    listCapacity = @intCast((r.h - 100) / 50);

    _ = sdl.SDL_SetRenderDrawColor(r.renderer, 23, 23, 23, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderClear(r.renderer);

    var text_surface: [*c]ttf.SDL_Surface = undefined;

    if (!inFocus) {
        text_surface = ttf.TTF_RenderUTF8_LCD(r.font, @ptrCast(inputText.items), r.white, r.background);
    } else {
        text_surface = ttf.TTF_RenderUTF8_LCD(r.font, @ptrCast(inputText.items), r.background, r.white);
    }
    defer sdl.SDL_FreeSurface(@ptrCast(text_surface));

    const text_texture = sdl.SDL_CreateTextureFromSurface(r.renderer, @ptrCast(text_surface));
    defer sdl.SDL_DestroyTexture(text_texture);

    const text_rect: sdl.SDL_Rect = .{
        .x = 0,
        .y = 0,
        .w = @intCast(r.fontSize * inputText.items.len),
        .h = 50,
    };
    _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(text_texture), null, &text_rect);

    if (inFocus) _ = sdl.SDL_SetTextureAlphaMod(@ptrCast(r.search_texture), sdl.SDL_ALPHA_TRANSPARENT);
    if (!inFocus) _ = sdl.SDL_SetTextureAlphaMod(@ptrCast(r.search_texture), sdl.SDL_ALPHA_OPAQUE);

    const search_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 0,
        .w = 50,
        .h = 50,
    };

    _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(r.search_texture), null, &search_rect);

    const list_rect = sdl.SDL_Rect{
        .x = 0,
        .y = 50,
        .w = @intCast(r.w),
        .h = @intCast(50 * listCapacity),
    };
    if (inFocus and textIndex > 0) {
        const query = std.mem.trim(u8, inputText.items, &std.ascii.whitespace);
        try list(music.musics.items, listCapacity, list_rect, query);
    } else {
        try list(music.musics.items, listCapacity, list_rect, "");
    }
    const play_rect = sdl.SDL_Rect{
        .w = 30,
        .h = 30,
        .y = @intCast(r.h - 46),
        .x = @intCast((r.w - 30) / 2),
    };

    if (music.isPaused) {
        _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(r.play_texture), null, @ptrCast(&play_rect));
    } else {
        _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(r.pause_texture), null, @ptrCast(&play_rect));
    }

    const prev_rect = sdl.SDL_Rect{
        .w = 30,
        .h = 30,
        .y = @intCast(r.h - 46),
        .x = @intCast(play_rect.x - 60),
    };

    _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(r.prev_texture), null, @ptrCast(&prev_rect));

    const next_rect = sdl.SDL_Rect{
        .w = 30,
        .h = 30,
        .y = @intCast(r.h - 46),
        .x = @intCast(play_rect.x + 60),
    };

    _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(r.next_texture), null, @ptrCast(&next_rect));

    const bar_rect = sdl.SDL_Rect{
        .x = 0,
        .y = @intCast(r.h - 12),
        .w = @intCast(r.w),
        .h = 8,
    };

    _ = sdl.SDL_SetRenderDrawColor(r.renderer, 95, 95, 95, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderFillRect(r.renderer, @ptrCast(&bar_rect));

    const width: f64 = @floatFromInt(r.w);
    if (barOnFocus) {
        const position = (r.mousex / width) * music.getCurDuration();
        music.setPosition(position);
    }

    const progress: f64 = (width / music.getCurDuration()) * music.getCurPosition();
    const progress_rect = sdl.SDL_Rect{
        .x = 0,
        .y = @intCast(r.h - 12),
        .w = @intFromFloat(progress),
        .h = 8,
    };

    _ = sdl.SDL_SetRenderDrawColor(r.renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
    _ = sdl.SDL_RenderFillRect(r.renderer, @ptrCast(&progress_rect));

    _ = sdl.SDL_RenderPresent(r.renderer);

    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            sdl.SDL_KEYDOWN => {
                switch (event.key.keysym.sym) {
                    sdl.SDLK_ESCAPE => {
                        if (inFocus) inFocus = !inFocus;
                        inputText.shrinkAndFree(0);
                        try inputText.appendNTimes(32, 20);
                        textIndex = 0;
                    },
                    sdl.SDLK_SPACE => {
                        if (!inFocus) continue;
                        if (inputText.items.len > 50) continue;
                        try inputText.insert(textIndex, 32);
                        textIndex += 1;
                    },
                    sdl.SDLK_DOWN => {
                        cursorNext();
                    },
                    sdl.SDLK_UP => {
                        cursorPrev();
                    },
                    sdl.SDLK_RETURN => {
                        try playUnderCursor();
                    },
                    sdl.SDLK_BACKSPACE => {
                        if (textIndex == 0) continue;
                        textIndex -= 1;
                        _ = inputText.orderedRemove(textIndex);
                        try inputText.append(32);
                    },
                    else => {
                        if (!inFocus) continue;
                        if (inputText.items.len > 50) continue;
                        searchPage = 0;
                        const s = sdl.SDL_GetKeyName(event.key.keysym.sym).*;
                        try inputText.insert(textIndex, s);
                        textIndex += 1;
                    }
                }
            },
            sdl.SDL_WINDOWEVENT => {
                sdl.SDL_GetWindowSize(r.screen, @ptrCast(&r.w), @ptrCast(&r.h));

                // TODO: check how sdl gpu usage works and remove this TEMPORARY fix

                if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_GAINED) r.delay = 32;
                if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_LOST) r.delay = 500;
            },
            sdl.SDL_QUIT => {
                r.quit = true;
            },
            sdl.SDL_MOUSEMOTION => {
                r.mousex = @floatFromInt(event.motion.x);
                r.mousey = @floatFromInt(event.motion.y);
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
                    inFocus = !inFocus;
                }
                if (r.isPosInRectBounds(bar_rect, event.button.x, event.button.y)) {
                    barOnFocus = true;
                    music.pauseMusic();
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
    sdl.SDL_Delay(r.delay);
}

fn playUnderCursor() !void {
    if (inFocus) {
        var matchIndex: u16 = 0;
        for (music.musics.items, 0..) |value, i| {
            const input = std.mem.trim(u8, inputText.items, &std.ascii.whitespace);
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
        if (inFocus) {
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
        if (inFocus) {
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
    var valueUpper: [255]u8 = undefined;
    _ = std.ascii.upperString(&valueUpper, musicName);
    const isEqual = std.mem.containsAtLeast(u8, &valueUpper, 1, query);
    return isEqual;
}

fn list(totalItems: [][]u8, capacity: u16, rect: sdl.SDL_Rect, query: []const u8) !void {
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

        if (inFocus) {
            if ((matchNumber - 1) < (searchPage * capacity)) continue;
        } else {
            if ((matchNumber - 1) < (page * capacity)) continue;
        }
        var split = std.mem.split(u8, itemName, "\\");
        while (split.next()) |value| {
            itemName = value;
        }

        listItem(itemName, @intCast(@divFloor(rect.h, capacity)), item, style, @intCast(rect.y));
        item += 1;
    }
}
fn listItem(text: []const u8, height: u16, index: usize, style: u8, offset: u8) void {
    var name_surface: [*c]ttf.SDL_Surface = undefined;

    switch (style) {
        0 => name_surface = ttf.TTF_RenderText_LCD(r.font, @ptrCast(text), r.white, r.background),
        1 => name_surface = ttf.TTF_RenderText_LCD(r.font, @ptrCast(text), r.background, r.white),
        2 => name_surface = ttf.TTF_RenderText_LCD(r.font, @ptrCast(text), r.red, r.background),
        3 => name_surface = ttf.TTF_RenderText_LCD(r.font, @ptrCast(text), r.red, r.white),
        else => {
            std.debug.print("unknown style for list item: {d} \n", .{style});
        }
    }
    defer sdl.SDL_FreeSurface(@ptrCast(name_surface));

    const name_texture = sdl.SDL_CreateTextureFromSurface(r.renderer, @ptrCast(name_surface));
    defer sdl.SDL_DestroyTexture(name_texture);

    const name_rect: sdl.SDL_Rect = .{
        .x = 0,
        .y = @intCast((height * index) + offset),
        .w = @intCast(r.fontSize * text.len),
        .h = height,
    };

    _ = sdl.SDL_RenderCopy(r.renderer, @ptrCast(name_texture), null, &name_rect);
}
