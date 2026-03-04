pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_mixer.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub const dbus = @cImport({
    @cDefine("DBUS_API_SUBJECT_TO_CHANGE", "1");
    @cInclude("dbus/dbus.h");
});
