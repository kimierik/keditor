const std = @import("std");
const raylib = @import("raylib.zig");

const GapBuffer = @import("gapBuffer.zig");

const rl = raylib.raylib;

/// only for ints
inline fn intCastAs(T: type, val: anytype) T {
    return @as(T, (@intCast(val)));
}

const State = struct {
    cursorLineC: usize,
    cursorColumnC: usize,
};

var state: State = .{ .cursorLineC = 0, .cursorColumnC = 1 };

var globalAllocator: std.mem.Allocator = undefined;

fn readFileToBuffer(fileName: []const u8, buffer: *GapBuffer.GapBuffer(u8)) !void {
    const file = try std.fs.cwd().openFile(fileName, .{});

    var reading = true;
    while (reading) {
        const c = file.reader().readByte() catch {
            reading = false;
            continue;
        };

        if (c == 0) {
            reading = false;
            continue;
        }

        try buffer.insert(c);
    }

    for (0..buffer.position) |_| {
        _ = buffer.left();
    }
}

fn setCursorPrevLine(buffer: *GapBuffer.GapBuffer(u8)) void {
    const slice = buffer.items[0 .. buffer.position - 1];
    const i = std.mem.lastIndexOf(u8, slice, "\n");

    if (i) |index| {
        const n = slice.len - index;
        state.cursorColumnC = n + 1 + 1; // 1 since first line does not have a \n, one bc we remove one at the end of this if statement
        state.cursorLineC -= 1;
    } else {
        state.cursorColumnC = buffer.position + 2; // 1 since first line does not have a \n, one bc we remove one at the end of this if statement
        state.cursorLineC -= 1;
    }
}
fn setCursorNextLine() void {
    state.cursorLineC += 1;
    state.cursorColumnC = 1;
}

fn executeInput(key: c_int, buffer: *GapBuffer.GapBuffer(u8)) !void {
    if (key >= 'A' and key <= 'Z') {
        state.cursorColumnC += 1;
        return try buffer.insert(@intCast(key));
    }

    if (key == rl.KEY_SPACE) {
        state.cursorColumnC += 1;
        return try buffer.insert(' ');
    }

    if (key == rl.KEY_BACKSPACE) {
        const char = buffer.delete();
        if (char) |c| {
            if (c == '\n') {
                setCursorPrevLine(buffer);
            }
        }
        state.cursorColumnC -= 1;
    }

    if (key == rl.KEY_ENTER) {
        state.cursorLineC += 1;
        state.cursorColumnC = 1;
        return try buffer.insert('\n');
    }

    if (key == rl.KEY_LEFT) {
        if (buffer.left()) {
            if (buffer.items[buffer.position + buffer.gap_size] == '\n') {
                setCursorPrevLine(buffer);
            }
            state.cursorColumnC -= 1;
        }
    }

    if (key == rl.KEY_RIGHT) {
        if (buffer.right()) {
            state.cursorColumnC += 1;
            if (buffer.items[buffer.position - 1] == '\n') {
                setCursorNextLine();
            }
        }
    }
}

const FONT_SIZE = 32;

fn startGui(allocator: std.mem.Allocator, textBuffer: *GapBuffer.GapBuffer(u8)) !void {
    rl.InitWindow(800, 800, "keditor");
    defer rl.CloseWindow();

    const FONT = rl.LoadFontEx("./assets/FantasqueSansMono-Regular.ttf", FONT_SIZE, 0, 0);
    defer rl.UnloadFont(FONT);
    const glyphsize = rl.MeasureTextEx(FONT, "A", FONT_SIZE, 0);
    const glyphX = @as(usize, @intFromFloat(glyphsize.x));
    //const glyphY = @as(usize, @intFromFloat(glyphsize.y)); //glyph y is fontsize

    while (!rl.WindowShouldClose()) {
        const key = rl.GetKeyPressed();
        try executeInput(key, textBuffer);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        const a = try textBuffer.getList(allocator);
        defer allocator.free(a);

        const txt = @as([*c]u8, @ptrCast(a));
        const cursor_color = rl.Color{ .a = 50, .r = 30, .b = 30, .g = 30 };

        const cursorX: c_int = @intCast(glyphX * state.cursorColumnC);
        const cursorY: c_int = @intCast(state.cursorLineC * (FONT_SIZE + 2)); // magic number seems to be some spacing in this font

        rl.DrawRectangle(cursorX - intCastAs(c_int, glyphX / 2), intCastAs(c_int, cursorY + 10), @intCast(glyphX + 1), FONT_SIZE, cursor_color);

        rl.DrawTextEx(FONT, txt, rl.Vector2{ .x = 10, .y = 10 }, FONT_SIZE, 0, rl.BLACK);
    }
    // we exit normally
    std.process.exit(0);
}

fn printBuffer(textBuffer: *GapBuffer.GapBuffer(u8)) void {
    const str = textBuffer.getList(globalAllocator) catch unreachable;
    defer globalAllocator.free(str);
    std.debug.print("string is {s}", .{str});
    std.debug.print("string is {d}", .{str});
}

fn printHelp() void {
    const helpmsg =
        \\Useage:
        \\  keditor [options] [file]
        \\options:
        \\  -h, --help      Prints this help messege
    ;
    std.debug.print("{s}\n", .{helpmsg});
}

fn parseCmd(allocator: std.mem.Allocator, args: [][]u8) !void {
    const cmd = args[1];
    const cmd_args = args[2..];

    if (std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "-h")) {
        printHelp();
        return;
    }

    var textBuffer = try GapBuffer.GapBuffer(u8).init(allocator);

    try readFileToBuffer(cmd, &textBuffer);
    //printBuffer(&textBuffer);

    try startGui(allocator, &textBuffer);

    // if no
    _ = cmd_args;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    globalAllocator = allocator;

    // handle arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    rl.SetTraceLogLevel(rl.LOG_NONE);

    if (args.len == 1) {
        var textBuffer = try GapBuffer.GapBuffer(u8).init(allocator);
        try startGui(allocator, &textBuffer);
    } else {
        try parseCmd(allocator, args);
    }
}
