const std = @import("std");
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_mixer = @cImport(@cInclude("SDL_mixer.h"));
const hook = @cImport(@cInclude("uiohook.h"));

const music2_path = "C:\\Users\\Luis\\musics\\";

const alloc = std.heap.page_allocator;
var musics: std.ArrayList([]u8) = std.ArrayList([]u8).init(alloc);
var index: u16 = 0;
var isPaused = false;
var quit = false;
var volume: u8 = 64;

pub fn volumeUp() void {
    if (volume > 127) return;
    volume += 4;
    _ = sdl_mixer.Mix_VolumeMusic(volume);
}
pub fn volumeDown() void {
    if (volume == 0) return;
    volume -= 4;
    _ = sdl_mixer.Mix_VolumeMusic(volume);
}
pub fn pauseMusic() void {
    if (!isPaused) {
        sdl_mixer.Mix_PauseMusic();
    } else {
        sdl_mixer.Mix_ResumeMusic();
    }
    isPaused = !isPaused;
}
pub fn prevMusic() void {
    _ = sdl_mixer.Mix_HaltMusic();
    assert(musics.items.len < 10000);
    switch (index) {
        0 => index = @intCast(musics.items.len - 1),
        1 => index = @intCast(musics.items.len),
        else => index -= 2,
    }
}
pub fn nextMusic() void {
    _ = sdl_mixer.Mix_HaltMusic();
}

fn dispacher(event: [*c]const hook.uiohook_event) callconv(.C) void {
    const keycode = event.*.data.keyboard.keycode;
    if (event.*.type == hook.EVENT_KEY_PRESSED) {
        std.debug.print("rawcode {}\n", .{keycode});
        switch (keycode) {
            65 => prevMusic(),
            66 => pauseMusic(),
            67 => nextMusic(),
            87 => volumeDown(),
            88 => volumeUp(),
            else => {},
        }
    }
}
fn hookRun() void {
    _ = hook.hook_run();
}

pub fn init() !void {
    hook.hook_set_dispatch_proc(dispacher);
    const thread = try std.Thread.spawn(.{}, hookRun, .{});
    defer thread.detach();

    var iter = (try std.fs.openDirAbsolute(
        "C:\\Users\\Luis\\musics",
        .{ .iterate = true },
    )).iterate();

    while (try iter.next()) |entry| {
        if (entry.kind == .file) {
            var name = std.ArrayList(u8).init(alloc);
            try name.appendSlice(music2_path);
            try name.appendSlice(entry.name);
            if (std.mem.endsWith(u8, entry.name, ".mp3")) {
                try musics.append(name.items);
            }
        }
    }
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    var rand = std.Random.Sfc64.init(seed);
    rand.random().shuffle([]u8, musics.items);

    _ = sdl.SDL_Init(sdl.SDL_INIT_AUDIO);

    _ = sdl_mixer.Mix_OpenAudio(22050, sdl_mixer.AUDIO_S16SYS, 2, 640);
    _ = sdl_mixer.Mix_Init(sdl_mixer.MIX_INIT_MP3);
    _ = sdl_mixer.Mix_VolumeMusic(volume);
}
pub fn play() bool {
    const status = sdl_mixer.Mix_PlayingMusic();
    if (status == 0) {
        const music: ?*sdl_mixer.Mix_Music = sdl_mixer.Mix_LoadMUS(@ptrCast(musics.items[index]));
        _ = sdl_mixer.Mix_PlayMusic(music, 0);
        std.debug.print("musica: {s}\n", .{musics.items[index]});
        assert(musics.items.len < 10000);
        if (musics.items.len < index) {
            index = 0;
        } else {
            index += 1;
        }
    }
    sdl.SDL_Delay(500);
    return quit;
}
