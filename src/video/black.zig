const ui = @import("../ui_lib.zig");
const r = @import("renderer.zig");
const music = @import("../music.zig");
const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_ttf.h");
});


const alloc = std.heap.page_allocator;

var count: u8 = 0;
var onFocus = false;
var cursor: u16 = 0;
var color = ui.colors.background;
var elements = std.ArrayList(ui.element).init(alloc);


pub fn render(screen: *const ui.screen) !void {

    var textField = try ui.textField.init(alloc);

    _ = try music.play();

    const renderer = screen.renderer;

    while (!screen.quit) {

        var window = ui.element{ .gap = 1, .orientation = ui.orientation.vertical_inverted, .color = ui.colors.background };
        window.area = ui.rect{ .x = 0, .y = 0, .h = @intCast(screen.h), .w = @intCast(screen.w) };

        _ = sdl.SDL_SetRenderDrawColor(renderer, 50, 50, 50, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderClear(renderer);
        //iconsr

        var searchbar = ui.element{.color = ui.colors.background,.size = 9 };
        var icon = ui.element{.color = ui.colors.background, .format = ui.format{.image= "src/res/search.png"}};
        var input = ui.element{.onclick = onClickMenu, .color = ui.colors.background,.size = 9, .format = ui.format{ .textinput = &textField}};

        try searchbar.add(&icon);
        try searchbar.add(&input);

        var header = ui.element{.color = ui.colors.background};
        var menu = ui.element{.color = ui.colors.background, .format = ui.format{.image = "src/res/menu.png"}};
        var settings = ui.element{.color = ui.colors.background, .format = ui.format{.image = "src/res/settings.png"}};

        try header.add(&menu);
        try header.add(&searchbar);
        try header.add(&settings);

        var list = ui.element{.orientation = ui.orientation.vertical, .size = 9, .gap = 1, .color = ui.colors.background};

        const query = std.mem.trim(u8, textField.text.items, &std.ascii.whitespace);
        try getList(music.musics.items, 20, query);
        
        for (0..elements.items.len)|i| {
            try list.add(&elements.items[i]);
        }

        try window.add(&list);
        try window.add(&header);

        window.fill();


        if (ui.isPosInRBounds(searchbar.area, screen.mousex, screen.mousey)){
            searchbar.color = [_]u8{40, 40, 40,255};
            input.color = [_]u8{40, 40, 40,255};
        }

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            window.handleEvent(event);
            switch(event.type) {
                sdl.SDL_TEXTINPUT => {
                    if (!textField.inFocus) continue;
                    try textField.append_char(event.text.text[0]);
                    std.debug.print("ühuuu", .{});
                    }, 
                    sdl.SDL_KEYDOWN => {
                        switch (event.key.keysym.sym) {
                        sdl.SDLK_BACKSPACE => {
                            try textField.pop_char();
                       },
                        sdl.SDLK_UP => {
                            if (cursor == 0) continue;
                            cursor -= 1;
                        },
                        sdl.SDLK_DOWN => {
                            cursor += 1;
                        },
                        else => {},
                        }
                    },
                    else => {},
                }
            }


        window.render(renderer);
        _ = sdl.SDL_RenderPresent(renderer);

        elements.shrinkAndFree(0);
        sdl.SDL_Delay(screen.delay);
    }


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

fn getList(totalItems: [][]u8, capacity: u16, query: []const u8) !void {
    var item: u16 = 0;
    var matchNumber: u16 = 0;
    var index: u16 = 0;
    while (item < capacity) {
        // checking if total items ended and populating remaning items
        if (totalItems.len - 1 < index) {
            while (item < capacity) {
                var el = ui.element{.color = ui.colors.background };
                el.format = ui.format{.text = ""};
                if (item == cursor) el.color = [_]u8{80,80,80,255};
                try elements.append(el);
                item += 1;
            }
            return;
        } 
        var itemName: []const u8 = totalItems[index];
        if (!filterEql(itemName, query)) {
            index += 1;
            continue;
        }

        matchNumber += 1;
        index += 1;

        var split = std.mem.splitSequence(u8, itemName, "\\");
        while (split.next()) |value| {
            itemName = value;
        }

        var el = ui.element{.color = ui.colors.background };
        el.format = ui.format{.text = itemName };
        if (item == cursor) el.color = [_]u8{80,80,80,255};
        try elements.append(el);

        item += 1;
    }

}

pub fn onClickMenu(self: *ui.element) void {
    if (self.format.textinput.inFocus) {
        self.format.textinput.inFocus = false;
    } else {
        self.format.textinput.inFocus = true;
    }
    std.debug.print("ühuuu {} \n", .{self.format.textinput.inFocus});
}
