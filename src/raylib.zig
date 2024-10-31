pub const raylib = @cImport({
    @cInclude("raylib.h");
    @cDefine("RAYGUI_IMPLEMENTATION", "1");
    @cInclude("raygui.h");
});
