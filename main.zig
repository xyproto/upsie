const std = @import("std");
const print = std.debug.print;

// ANSI color codes for terminal output
const ColorReset = "\x1b[0m";
const ColorBold = "\x1b[1m";
const ColorErrorRed = "\x1b[91m";

// Gradient colors: White -> Red -> Orange -> Yellow
const ColorWhite = "\x1b[97m";
const ColorRed = "\x1b[31m";
const ColorOrange = "\x1b[33m";
const ColorYellow = "\x1b[93m";

const UtsName = extern struct {
    sysname: [65]u8,
    nodename: [65]u8,
    release: [65]u8,
    version: [65]u8,
    machine: [65]u8,
    domainname: [65]u8,
};

extern "c" fn uname(buf: *UtsName) c_int;

fn trimNullBytes(s: []const u8) []const u8 {
    return std.mem.sliceTo(s, 0);
}

fn formatUptime(allocator: std.mem.Allocator, total_seconds: i64) ![]u8 {
    if (total_seconds == 0) {
        return try allocator.dupe(u8, "just started");
    }
    if (total_seconds < 60) {
        return try allocator.dupe(u8, "less than 1m");
    }

    var result = try std.ArrayList(u8).initCapacity(allocator, 64);
    defer result.deinit(allocator);

    var first = true;
    const total_minutes = @divTrunc(total_seconds, 60);
    const minutes = @mod(total_minutes, 60);
    const total_hours = @divTrunc(total_minutes, 60);
    const hours = @mod(total_hours, 24);
    const total_days = @divTrunc(total_hours, 24);
    const days = @mod(total_days, 7);
    const weeks = @divTrunc(total_days, 7);

    if (weeks > 0) {
        try result.writer(allocator).print("{d}w", .{weeks});
        first = false;
    }
    if (days > 0) {
        if (!first) try result.appendSlice(allocator, ", ");
        try result.writer(allocator).print("{d}d", .{days});
        first = false;
    }
    if (hours > 0) {
        if (!first) try result.appendSlice(allocator, ", ");
        try result.writer(allocator).print("{d}h", .{hours});
        first = false;
    }
    if (minutes > 0) {
        if (!first) try result.appendSlice(allocator, ", ");
        try result.writer(allocator).print("{d}m", .{minutes});
    }

    return try result.toOwnedSlice(allocator);
}

fn runUpsie(allocator: std.mem.Allocator) !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip program name

    var full_kernel_version = false;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-l")) {
            full_kernel_version = true;
            break;
        }
    }

    var uname_data: UtsName = undefined;
    if (uname(&uname_data) != 0) {
        return error.UnameSystemCallFailed;
    }

    const hostname = trimNullBytes(&uname_data.nodename);
    const kernel_release = trimNullBytes(&uname_data.release);
    const machine_arch = trimNullBytes(&uname_data.machine);

    const uptime_file = try std.fs.openFileAbsolute("/proc/uptime", .{});
    defer uptime_file.close();

    var uptime_buffer: [64]u8 = undefined;
    const bytes_read = try uptime_file.readAll(&uptime_buffer);
    const uptime_content = uptime_buffer[0..bytes_read];

    var iter = std.mem.splitScalar(u8, uptime_content, ' ');
    const uptime_str = iter.next() orelse return error.InvalidUptimeFormat;
    const uptime_seconds = try std.fmt.parseFloat(f64, uptime_str);

    var kernel_version_display: []const u8 = kernel_release;
    var version_buffer: [64]u8 = undefined;

    if (!full_kernel_version) {
        var parts = std.mem.splitScalar(u8, kernel_release, '.');
        if (parts.next()) |major| {
            if (parts.next()) |minor| {
                kernel_version_display = try std.fmt.bufPrint(&version_buffer, "{s}.{s}", .{ major, minor });
            }
        }
    }

    print("{s}{s}{s} @ {s}{s}{s} ({s}{s}{s}) - {s}{s}{s} ", .{
        ColorBold ++ ColorWhite, hostname,                 ColorReset,
        ColorBold ++ ColorRed,   kernel_version_display,   ColorReset,
        ColorBold ++ ColorOrange, machine_arch,            ColorReset,
        ColorBold ++ ColorYellow, "Up:",                   ColorReset,
    });

    const formatted_uptime = try formatUptime(allocator, @as(i64, @intFromFloat(uptime_seconds)));
    defer allocator.free(formatted_uptime);
    print("{s}{s}{s}\n", .{ ColorYellow, formatted_uptime, ColorReset });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    runUpsie(allocator) catch |err| {
        switch (err) {
            error.UnameSystemCallFailed => print("{s}Error: failed to get system information (uname){s}\n", .{ ColorErrorRed, ColorReset }),
            error.FileNotFound => print("{s}Error: failed to open /proc/uptime{s}\n", .{ ColorErrorRed, ColorReset }),
            error.InvalidUptimeFormat => print("{s}Error: failed to parse uptime from /proc/uptime{s}\n", .{ ColorErrorRed, ColorReset }),
            else => print("{s}Error: {any}{s}\n", .{ ColorErrorRed, err, ColorReset }),
        }
        std.process.exit(1);
    };
}

