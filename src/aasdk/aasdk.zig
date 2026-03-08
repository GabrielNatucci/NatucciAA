const std = @import("std");

/// Opaque type representing the C++ AASDK_Context.
pub const Context = opaque {};

// Extern C function declarations matching aasdk_wrapper.h
extern "C" fn aasdk_create_context() ?*Context;
extern "C" fn aasdk_destroy_context(ctx: ?*Context) void;
extern "C" fn aasdk_start(ctx: ?*Context) c_int;
extern "C" fn aasdk_stop(ctx: ?*Context) void;

pub const AasdkError = error{
    InitializationFailed,
    StartFailed,
    AlreadyRunning,
};

/// Zig wrapper for the AASDK C wrapper.
pub const AASdk = struct {
    ctx: *Context,

    /// Creates and initializes the AASDK context.
    pub fn init() !AASdk {
        const ctx = aasdk_create_context() orelse return error.InitializationFailed;
        return AASdk{ .ctx = ctx };
    }

    /// Destroys the AASDK context and frees resources.
    pub fn deinit(self: *AASdk) void {
        aasdk_destroy_context(self.ctx);
    }

    /// Starts the AASDK connection or service.
    pub fn start(self: *AASdk) !void {
        const result = aasdk_start(self.ctx);
        if (result == -2) {
            return error.AlreadyRunning;
        } else if (result < 0) {
            return error.StartFailed;
        }
    }

    /// Stops the AASDK connection or service.
    pub fn stop(self: *AASdk) void {
        aasdk_stop(self.ctx);
    }
};