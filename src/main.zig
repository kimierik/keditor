const std = @import("std");
const raylib = @import("raylib.zig");

const GapBuffer = @import("gapBuffer.zig");

const rl = raylib.raylib;

pub fn executeInput(key: c_int, buffer: *GapBuffer.GapBuffer(u8)) !void {
    if (key >= 'A' and key <= 'Z') {
        return try buffer.insert(@intCast(key));
    }
    if (key == rl.KEY_LEFT) {
        buffer.left();
    }

    if (key == rl.KEY_RIGHT) {
        buffer.right();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    rl.InitWindow(800, 800, "keditor");

    var textBuffer = try GapBuffer.GapBuffer(u8).init(allocator);

    defer rl.CloseWindow();
    while (!rl.WindowShouldClose()) {
        const key = rl.GetKeyPressed();
        try executeInput(key, &textBuffer);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        const a = try textBuffer.getList(allocator);
        defer allocator.free(a);

        const txt = @as([*c]u8, @ptrCast(a));

        // we need to do some math to see if we go over the thing
        rl.DrawText(txt, 10, 10, 27, rl.BLACK);
    }
}
