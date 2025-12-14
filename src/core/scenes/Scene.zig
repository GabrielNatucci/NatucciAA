const std = @import("std");
const sdl = @import("../../sdlImport/Sdl.zig").sdl;

pub const Scene = struct {
    name: []const u8,
    active: bool,
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        init: *const fn (*anyopaque) anyerror!void, // Está correto
        deinit: *const fn (*anyopaque) void,
        update: *const fn (*anyopaque, f32, *sdl.SDL_Renderer, active: bool) void,
        render: *const fn (*anyopaque, *sdl.SDL_Renderer) void,
        outOfFocus: *const fn (*anyopaque) void,
    };

    pub fn init(name: []const u8, pointer: anytype) Scene {
        const T = @TypeOf(pointer.*);

        const gen = struct {
            fn init(ptr: *anyopaque) anyerror!void { // ← Adicione anyerror!
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.init(); // Precisa retornar o erro
            }

            fn deinit(ptr: *anyopaque) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.deinit();
            }

            fn update(ptr: *anyopaque, delta_time: f32, renderer: *sdl.SDL_Renderer, active: bool) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.update(delta_time, renderer, active);
            }

            fn render(ptr: *anyopaque, renderer: *sdl.SDL_Renderer) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.render(renderer);
            }

            fn outOfFocus(ptr: *anyopaque) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.outOfFocus();
            }
        };

        return .{
            .name = name,
            .active = true,
            .ptr = pointer,
            .vtable = &.{
                .init = gen.init,
                .deinit = gen.deinit,
                .update = gen.update,
                .render = gen.render,
                .outOfFocus = gen.outOfFocus,
            },
        };
    }
    pub fn initScene(self: *Scene) !void {
        return self.vtable.init(self.ptr);
    }

    pub fn deinit(self: *Scene) void {
        self.vtable.deinit(self.ptr);
    }

    pub fn update(self: Scene, delta_time: f32, renderer: *sdl.SDL_Renderer) void {
        if (self.active) {
            self.vtable.update(self.ptr, delta_time, renderer, self.active);
        }
    }

    pub fn render(self: Scene, renderer: *sdl.SDL_Renderer) void {
        if (self.active) {
            self.vtable.render(self.ptr, renderer);
        }
    }

    pub fn outOfFocus(self: Scene) void {
        self.vtable.outOfFocus(self.ptr);
    }

    // Métodos que trabalham com as propriedades comuns
    pub fn setActive(self: *Scene, active: bool) void {
        self.active = active;
        std.debug.print("Scene '{s}' agora está: {s}\n", .{ self.name, if (active) "ATIVA" else "INATIVA" });
    }
};
