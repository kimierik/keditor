const std = @import("std");
const raylib = @import("raylib.zig");

const GapBuffer = @import("gapBuffer.zig");

const rl = raylib.raylib;

/// only for ints
inline fn trueCast(T: type, val: anytype) T {
    return @as(T, (@intCast(val)));
}

pub fn executeInput(key: c_int, buffer: *GapBuffer.GapBuffer(u8)) !void {
    if (key >= 'A' and key <= 'Z') {
        return try buffer.insert(@intCast(key));
    }

    if (key == rl.KEY_SPACE) {
        return try buffer.insert(' ');
    }

    if (key == rl.KEY_BACKSPACE) {
        _ = buffer.delete();
    }

    if (key == rl.KEY_ENTER) {
        return try buffer.insert('\n');
    }

    if (key == rl.KEY_LEFT) {
        buffer.left();
    }

    if (key == rl.KEY_RIGHT) {
        buffer.right();
    }
}

const FONT_SIZE = 32;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    rl.InitWindow(800, 800, "keditor");
    defer rl.CloseWindow();

    var textBuffer = try GapBuffer.GapBuffer(u8).init(allocator);

    const FONT = rl.LoadFontEx("./assets/FantasqueSansMono-Regular.ttf", FONT_SIZE, 0, 0);
    defer rl.UnloadFont(FONT);
    const glyphsize = rl.MeasureTextEx(FONT, "A", FONT_SIZE, 0);
    const glyphX = @as(usize, @intFromFloat(glyphsize.x));
    const glyphy = @as(usize, @intFromFloat(glyphsize.x));
    _ = glyphy; // autofix

    while (!rl.WindowShouldClose()) {
        const key = rl.GetKeyPressed();
        try executeInput(key, &textBuffer);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        const a = try textBuffer.getList(allocator);
        defer allocator.free(a);

        const txt = @as([*c]u8, @ptrCast(a));
        const cursor_color = rl.Color{ .a = 50, .r = 30, .b = 30, .g = 30 };

        const cursorX: c_int = @intCast(glyphX * textBuffer.position);

        rl.DrawRectangle(cursorX - trueCast(c_int, glyphX / 2), 10, @intCast(glyphX + 1), FONT_SIZE, cursor_color);

        rl.DrawTextEx(FONT, txt, rl.Vector2{ .x = 10, .y = 10 }, FONT_SIZE, 0, rl.BLACK);
    }
}
