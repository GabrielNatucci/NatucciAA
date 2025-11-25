const std = @import("std");

pub fn getCurrentTime(buffer: []u8) ![]const u8 {
    if (buffer.len < 6) return error.BufferTooSmall;
    
    const timestamp = std.time.timestamp();
    const epoch_seconds = @as(u64, @intCast(timestamp));
    
    // Calcula horas e minutos (UTC-3 para horário de Brasília)
    const seconds_in_day = epoch_seconds % 86400;
    const hours_utc = @divFloor(seconds_in_day, 3600);
    
    // Ajusta para UTC-3 (horário de Brasília)
    const hours = if (hours_utc >= 3) hours_utc - 3 else hours_utc + 21;
    const minutes = @divFloor(seconds_in_day % 3600, 60);
    
    // Formata como "HH:MM\0"
    buffer[0] = @as(u8, @intCast(hours / 10)) + '0';
    buffer[1] = @as(u8, @intCast(hours % 10)) + '0';
    buffer[2] = ':';
    buffer[3] = @as(u8, @intCast(minutes / 10)) + '0';
    buffer[4] = @as(u8, @intCast(minutes % 10)) + '0';
    buffer[5] = 0; // '\0'
    
    return buffer[0..6];
}
