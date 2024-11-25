const music = @import("./music.zig");

var quit = false;

pub fn main() !void {
    try music.init();

    while (!quit) {
        quit = music.play();
    }
}
