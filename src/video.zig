const std = @import("std");
const bytesToValue = std.mem.bytesToValue;
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_img = @cImport(@cInclude("SDL_image.h"));
const ttf = @cImport(@cInclude("SDL_ttf.h"));
const music = @import("./music.zig");
const space_ascci = 32;

var quit = false;

var cursor: u16 = 0;
var page: u16 = 0;
var searchPage: u16 = 0;
var inFocus = false;
var barOnFocus = false;

var mousex: f64 = 0;
var mousey: f64 = 0;

var w: u32 = 800;
var h: u32 = 500;

var delay: c_uint = 32;
const alloc = std.heap.page_allocator;
var inputText: std.ArrayList(u8) = std.ArrayList(u8).init(alloc);
var textIndex: u16 = 0;
var seletedIndex: u16 = 0;
var font: ?*ttf.TTF_Font = undefined;
const fontSize: u16 = 12;
const background: ttf.SDL_Color = .{
    .r = 23,
    .g = 23,
    .b = 23,
    .a = 255,
};
const gray: ttf.SDL_Color = .{
    .r = 80,
    .g = 80,
    .b = 80,
    .a = 255,
};
const red: ttf.SDL_Color = .{
    .r = 255,
    .g = 80,
    .b = 80,
    .a = 255,
};
const white: ttf.SDL_Color = .{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

pub fn isPosInRectBounds(rect: sdl.SDL_Rect, x: i32, y: i32) bool {
    if (rect.x < x and rect.y < y and y < rect.h + rect.y and x < rect.w + rect.x) {
        return true;
    }
    return false;
}

pub fn mediaBar() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    const screen = sdl.SDL_CreateWindow("~~~~ RAYWAVEEE ~~~~", 200, 200, @intCast(w), @intCast(h), sdl.SDL_WINDOW_RESIZABLE) orelse
        {
        sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer sdl.SDL_DestroyWindow(screen);

    const renderer: ?*sdl.SDL_Renderer = sdl.SDL_CreateRenderer(screen, -1, sdl.SDL_RENDERER_SOFTWARE);

    _ = ttf.TTF_Init();
    font = ttf.TTF_OpenFont("C:\\Windows\\Fonts\\arialbi.ttf", fontSize);
    assert(font != null);

    try inputText.appendNTimes(space_ascci, 20);

    _ = try music.play();

    const play_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "src/res/play.png");
    const pause_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "src/res/pause.png");
    const prev_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "src/res/prev.png");
    const next_texture = sdl_img.IMG_LoadTexture(@ptrCast(renderer), "src/res/next.png");

    while (!quit) {
        if (try music.play()) {
            page = (music.index - 1) / 8;
            cursor = (music.index - 1) % 8;
        }

        _ = sdl.SDL_SetRenderDrawColor(renderer, 23, 23, 23, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderClear(renderer);

        var text_surface: [*c]ttf.SDL_Surface = undefined;

        if (inFocus) {
            text_surface = ttf.TTF_RenderUTF8_LCD(font, @ptrCast(inputText.items), white, background);
        } else {
            text_surface = ttf.TTF_RenderUTF8_LCD(font, @ptrCast(inputText.items), background, white);
        }
        defer sdl.SDL_FreeSurface(@ptrCast(text_surface));

        const text_texture = sdl.SDL_CreateTextureFromSurface(renderer, @ptrCast(text_surface));
        defer sdl.SDL_DestroyTexture(text_texture);

        const text_rect: sdl.SDL_Rect = .{
            .x = 0,
            .y = 0,
            .w = @intCast(fontSize * inputText.items.len),
            .h = 50,
        };
        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(text_texture), null, &text_rect);
        if (inFocus and textIndex > 0) {
            const query = std.mem.trim(u8, inputText.items, &std.ascii.whitespace);
            try list(renderer, music.musics.items, 8, 400, 50, query);
        } else {
            try list(renderer, music.musics.items, 8, 400, 50, "");
        }
        const play_rect = sdl.SDL_Rect{
            .w = 30,
            .h = 30,
            .y = @intCast(h - 52),
            .x = @intCast((w - 30) / 2),
        };

        if (music.isPaused) {
            _ = sdl.SDL_RenderCopy(renderer, @ptrCast(play_texture), null, @ptrCast(&play_rect));
        } else {
            _ = sdl.SDL_RenderCopy(renderer, @ptrCast(pause_texture), null, @ptrCast(&play_rect));
        }

        const prev_rect = sdl.SDL_Rect{
            .w = 30,
            .h = 30,
            .y = @intCast(h - 52),
            .x = @intCast(play_rect.x - 60),
        };

        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(prev_texture), null, @ptrCast(&prev_rect));

        const next_rect = sdl.SDL_Rect{
            .w = 30,
            .h = 30,
            .y = @intCast(h - 52),
            .x = @intCast(play_rect.x + 60),
        };

        _ = sdl.SDL_RenderCopy(renderer, @ptrCast(next_texture), null, @ptrCast(&next_rect));

        const bar_rect = sdl.SDL_Rect{
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
        const progress_rect = sdl.SDL_Rect{
            .x = 0,
            .y = @intCast(h - 12),
            .w = @intFromFloat(progress),
            .h = 8,
        };

        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderFillRect(renderer, @ptrCast(&progress_rect));

        _ = sdl.SDL_RenderPresent(renderer);

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        sdl.SDLK_ESCAPE => {
                            if (inFocus) inFocus = !inFocus;
                            inputText.shrinkAndFree(0);
                            try inputText.appendNTimes(space_ascci, 20);
                            textIndex = 0;
                        },
                        sdl.SDLK_SPACE => {
                            if (!inFocus) continue;
                            if (inputText.items.len > 50) continue;
                            try inputText.insert(textIndex, space_ascci);
                            textIndex += 1;
                        },
                        sdl.SDLK_DOWN => {
                            cursorNext();
                        },
                        sdl.SDLK_UP => {
                            cursorPrev();
                        },
                        sdl.SDLK_RETURN => {
                            if (inFocus) {
                                var matchIndex: u16 = 0;
                                for (music.musics.items, 0..) |value, i| {
                                    const input = std.mem.trim(u8, inputText.items, &std.ascii.whitespace);
                                    const isEqual = filterEql(value, input);
                                    if (!isEqual) continue;
                                    if (matchIndex == (cursor + (searchPage * 8))) {
                                        try music.insertSongToNextIndex(@intCast(i));
                                        break;
                                    } else {
                                        matchIndex += 1;
                                    }
                                }
                            } else {
                                try music.playSongInIndex(cursor + (page * 8));
                            }
                        },
                        sdl.SDLK_BACKSPACE => {
                            if (textIndex == 0) continue;
                            textIndex -= 1;
                            _ = inputText.orderedRemove(textIndex);
                            try inputText.append(space_ascci);
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
                    sdl.SDL_GetWindowSize(screen, @ptrCast(&w), @ptrCast(&h));

                    // TODO: check how sdl gpu usage works and remove this TEMPORARY fix

                    if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_GAINED) delay = 32;
                    if (event.window.event == sdl.SDL_WINDOWEVENT_FOCUS_LOST) delay = 500;
                },
                sdl.SDL_QUIT => {
                    quit = true;
                },
                sdl.SDL_MOUSEMOTION => {
                    mousex = @floatFromInt(event.motion.x);
                    mousey = @floatFromInt(event.motion.y);
                },
                sdl.SDL_MOUSEBUTTONDOWN => {
                    if (isPosInRectBounds(play_rect, event.button.x, event.button.y)) {
                        music.pauseMusic();
                    }
                    if (isPosInRectBounds(prev_rect, event.button.x, event.button.y)) {
                        music.prevMusic();
                    }
                    if (isPosInRectBounds(next_rect, event.button.x, event.button.y)) {
                        music.nextMusic();
                    }
                    if (isPosInRectBounds(text_rect, event.button.x, event.button.y)) {
                        inFocus = !inFocus;
                    }
                    if (isPosInRectBounds(bar_rect, event.button.x, event.button.y)) {
                        barOnFocus = true;
                        music.pauseMusic();
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
        sdl.SDL_Delay(delay);
    }
}
fn cursorNext() void {
    if (cursor == 7) {
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
        cursor = 7;
        if (inFocus) {
            if (searchPage > 0) searchPage -= 1;
        } else {
            if (page > 0) page -= 1;
        }
        return;
    }
    cursor -= 1;
}
fn filterEql(musicName: []u8, query: []const u8) bool {
    if (query.len == 0) return true;
    if (query.len > musicName.len) return false;
    var valueUpper: [255]u8 = undefined;
    _ = std.ascii.upperString(&valueUpper, musicName);
    const isEqual = std.mem.containsAtLeast(u8, &valueUpper, 1, query);
    return isEqual;
}

fn list(renderer: ?*sdl.SDL_Renderer, totalItems: [][]u8, capacity: u16, height: u16, offset: u8, query: []const u8) !void {
    var item: u16 = 0;
    var matchNumber: u16 = 0;
    var index: u16 = 0;
    while (item < capacity) {
        var style: u8 = 0;
        if (totalItems.len - 1 < index) return;
        const itemName: []u8 = totalItems[index];
        if (!filterEql(itemName, query)) {
            index += 1;
            continue;
        }
        if (item == cursor) style = 1;
        if (index == music.index - 1) style = 2;
        if (item == cursor and index == music.index - 1) style = 3;

        matchNumber += 1;
        index += 1;

        if (inFocus) {
            if ((matchNumber - 1) < (searchPage * 8)) continue;
        } else {
            if ((matchNumber - 1) < (page * 8)) continue;
        }

        listItem(renderer, itemName, @intCast(height / capacity), item, style, offset);
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
