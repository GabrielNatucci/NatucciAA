const std = @import("std");

pub fn getCurrentTime() [6]u8 {
    const timestamp = std.time.timestamp();
    const epoch_seconds = @as(u64, @intCast(timestamp));
    
    // Calcula horas e minutos (UTC-3 para horário de Brasília)
    const seconds_in_day = epoch_seconds % 86400;
    const hours_utc = @divFloor(seconds_in_day, 3600);
    
    // Ajusta para UTC-3 (horário de Brasília)
    const hours = if (hours_utc >= 3) hours_utc - 3 else hours_utc + 21;
    const minutes = @divFloor(seconds_in_day % 3600, 60);
    
    // Cria array com "HH:MM"
    var result: [6]u8 = undefined;
    result[0] = @as(u8, @intCast(hours / 10)) + '0';
    result[1] = @as(u8, @intCast(hours % 10)) + '0';
    result[2] = ':';
    result[3] = @as(u8, @intCast(minutes / 10)) + '0';
    result[4] = @as(u8, @intCast(minutes % 10)) + '0';
    result[5] = 0;
    
    return result;
}
