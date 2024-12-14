const std = @import("std");
const assert = std.debug.assert;
const sdl = @cImport(@cInclude("SDL.h"));
const sdl_mixer = @cImport(@cInclude("SDL_mixer.h"));
const hook = @cImport(@cInclude("uiohook.h"));
const id3 = @import("./id3.zig");

pub const musicDisplayInfo = struct {
    name: []const u8,
    artist: []const u8,
    picture: []const u8,
};

const music2_path = "C:\\Users\\Luis\\musics\\";

const alloc = std.heap.page_allocator;
pub var musics: std.ArrayList([]u8) = std.ArrayList([]u8).init(alloc);
pub var index: u16 = 0;

pub var isPaused = false;
pub var currentMusicInfo: musicDisplayInfo = undefined;
var playingMusic: ?*sdl_mixer.Mix_Music = undefined;
var volume: u8 = 64;

pub fn getCurDuration() f64 {
    return sdl_mixer.Mix_MusicDuration(playingMusic);
}
pub fn getCurPosition() f64 {
    return sdl_mixer.Mix_GetMusicPosition(playingMusic);
}

pub fn setPosition(pos: f64) void {
    _ = sdl_mixer.Mix_SetMusicPosition(pos);
}

pub fn playSongInIndex(i: u16) !void {
    index = i;
    nextMusic();
}
pub fn insertSongToNextIndex(i: u16) !void {
    try musics.insert(index, musics.orderedRemove(i));
    nextMusic();
}
pub fn mute() void {
    _ = sdl_mixer.Mix_VolumeMusic(0);
}
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
pub fn getCurrentMusicInfo() !void {
    var split = std.mem.split(u8, musics.items[index], "\\");
    while (split.next()) |entry| {
        currentMusicInfo.name = entry;
    }
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

pub fn play() !bool {
    const status = sdl_mixer.Mix_PlayingMusic();
    if (status == 0) {
        playingMusic = sdl_mixer.Mix_LoadMUS(@ptrCast(musics.items[index]));
        _ = sdl_mixer.Mix_PlayMusic(playingMusic, 0);
        try getCurrentMusicInfo();
        assert(musics.items.len < 10000);
        if (musics.items.len < index) {
            index = 0;
        } else {
            index += 1;
        }
        sdl.SDL_Delay(34);
        return true;
    }
    sdl.SDL_Delay(34);
    return false;
}
