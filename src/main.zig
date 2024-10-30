const std = @import("std");

pub const rl = @cImport({
    @cInclude("raylib.h");
    @cDefine("RAYGUI_IMPLEMENTATION", "1");
    @cInclude("raygui.h");
});

pub fn main() !void {
    rl.InitWindow(800, 800, "keditor");
    defer rl.CloseWindow();
    var showMessageBox = false;
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        if (rl.GuiButton(rl.Rectangle{ .x = 24, .y = 24, .width = 120, .height = 30 }, "#191#Show Message") == 1)
            showMessageBox = true;

        if (showMessageBox) {
            const result = rl.GuiMessageBox(rl.Rectangle{ .x = 85, .y = 70, .width = 250, .height = 100 }, "#191#Message Box", "Hi! This is a message!", "Nice;Cool");

            if (result >= 0) showMessageBox = false;
        }
    }
}
