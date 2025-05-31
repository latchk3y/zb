const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try printHelp(std.io.getStdErr().writer());
        std.process.exit(1);
    }

    const cmd = args[1];
    const is_flag = cmd.len > 0 and cmd[0] == '-';

    if (is_flag) {
        if (std.mem.eql(u8, cmd, "-a")) {
            try handleAdd(allocator, args);
        } else if (std.mem.eql(u8, cmd, "-r")) {
            try handleRemove(allocator, args, false);
        } else if (std.mem.eql(u8, cmd, "-R")) {
            try handleRemove(allocator, args, true);
        } else if (std.mem.eql(u8, cmd, "-l")) {
            try handleList(allocator);
        } else if (std.mem.eql(u8, cmd, "-p")) {
            try handlePrune(allocator);
        } else if (std.mem.eql(u8, cmd, "-h")) {
            try printHelp(std.io.getStdOut().writer());
        } else {
            std.debug.print("error: unknown flag '{s}'\n", .{cmd});
            try printHelp(std.io.getStdErr().writer());
            std.process.exit(1);
        }
    } else {
        try handleJump(allocator, cmd);
    }
}

fn getBookmarksPath(allocator: std.mem.Allocator) ![]const u8 {
    const home = if (builtin.os.tag == .windows)
        std.process.getEnvVarOwned(allocator, "USERPROFILE") catch return error.HomeNotFound
    else
        std.process.getEnvVarOwned(allocator, "HOME") catch return error.HomeNotFound;
    defer allocator.free(home);

    return if (builtin.os.tag == .windows)
        try std.fs.path.join(allocator, &[_][]const u8{ home, "zb_bookmarks" })
    else
        try std.fs.path.join(allocator, &[_][]const u8{ home, ".config", ".zb_bookmarks" });
}

fn readBookmarks(allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    const path = try getBookmarksPath(allocator);
    defer allocator.free(path);

    var bookmarks = std.StringHashMap([]const u8).init(allocator);
    const file = std.fs.openFileAbsolute(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return bookmarks,
        else => return err,
    };
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var line_buf: [4096]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len == 0) continue;
        if (std.mem.indexOfScalar(u8, line, ':')) |idx| {
            const name = line[0..idx];
            const value = line[idx + 1 ..];
            try bookmarks.put(try allocator.dupe(u8, name), try allocator.dupe(u8, value));
        }
    }

    return bookmarks;
}

fn writeBookmarks(allocator: std.mem.Allocator, bookmarks: *std.StringHashMap([]const u8)) !void {
    const path = try getBookmarksPath(allocator);
    defer allocator.free(path);

    // Ensure config directory exists
    const dir_path = std.fs.path.dirname(path) orelse return error.NoParentDir;
    std.fs.cwd().makePath(dir_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const file = try std.fs.createFileAbsolute(path, .{});
    defer file.close();

    var writer = file.writer();
    var it = bookmarks.iterator();
    while (it.next()) |entry| {
        try writer.print("{s}:{s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

fn printHelp(writer: anytype) !void {
    try writer.writeAll(
        \\zb - Directory Bookmark Manager
        \\
        \\Usage:
        \\  zb [options] [bookmark|path]
        \\
        \\Options:
        \\  -a <name> [path]   Add bookmark (current dir if path omitted)
        \\  -r <name>          Remove bookmark
        \\  -R                 Remove all bookmarks
        \\  -l                 List bookmarks
        \\  -p                 Prune invalid bookmarks
        \\  -h                 Show this help
        \\
        \\Without options:
        \\  <bookmark>    Jump to bookmarked directory
        \\  <path>        Jump to specified directory
        \\
        \\Bookmarks are stored at: ~/.config/.zb_bookmarks
        \\
    );
}

fn handleAdd(allocator: std.mem.Allocator, args: [][:0]u8) !void {
    if (args.len < 3) {
        std.debug.print("error: missing bookmark name\n", .{});
        try printHelp(std.io.getStdErr().writer());
        std.process.exit(1);
    }

    var bookmarks = try readBookmarks(allocator);
    defer {
        var mutable_bookmarks = bookmarks;
        mutable_bookmarks.deinit();
    }

    const name = args[2];
    const path = if (args.len > 3) args[3] else try std.process.getCwdAlloc(allocator);

    const resolved_path = try std.fs.path.resolve(allocator, &.{path});
    if (std.fs.accessAbsolute(resolved_path, .{})) {
        _ = bookmarks.remove(name);
        try bookmarks.put(try allocator.dupe(u8, name), resolved_path);
        try writeBookmarks(allocator, &bookmarks);
    } else |err| {
        std.debug.print("error: path '{s}' not accessible ({s})\n", .{ resolved_path, @errorName(err) });
        std.process.exit(1);
    }
}

fn handleRemove(allocator: std.mem.Allocator, args: [][:0]u8, remove_all: bool) !void {
    var bookmarks = try readBookmarks(allocator);
    defer {
        var mutable_bookmarks = bookmarks;
        mutable_bookmarks.deinit();
    }

    if (remove_all) {
        bookmarks.clearAndFree();
    } else {
        if (args.len < 3) {
            std.debug.print("error: missing bookmark name\n", .{});
            try printHelp(std.io.getStdErr().writer());
            std.process.exit(1);
        }
        _ = bookmarks.remove(args[2]);
    }

    try writeBookmarks(allocator, &bookmarks);
}

fn handleList(allocator: std.mem.Allocator) !void {
    var bookmarks = try readBookmarks(allocator);
    defer {
        var mutable_bookmarks = bookmarks;
        mutable_bookmarks.deinit();
    }

    const stdout = std.io.getStdOut().writer();
    var it = bookmarks.iterator();
    while (it.next()) |entry| {
        const exists = blk: {
            std.fs.accessAbsolute(entry.value_ptr.*, .{}) catch break :blk false;
            break :blk true;
        };
        try stdout.print("{s}: {s} {s}\n", .{
            entry.key_ptr.*,
            entry.value_ptr.*,
            if (exists) "[OK]" else "[MISSING]",
        });
    }
}

fn handlePrune(allocator: std.mem.Allocator) !void {
    var bookmarks = try readBookmarks(allocator);
    defer {
        var mutable_bookmarks = bookmarks;
        mutable_bookmarks.deinit();
    }

    var to_remove = std.ArrayList([]const u8).init(allocator);
    defer to_remove.deinit();

    var it = bookmarks.iterator();
    while (it.next()) |entry| {
        const exists = blk: {
            std.fs.accessAbsolute(entry.value_ptr.*, .{}) catch break :blk false;
            break :blk true;
        };
        if (!exists) {
            try to_remove.append(entry.key_ptr.*);
        }
    }

    for (to_remove.items) |key| {
        _ = bookmarks.remove(key);
    }

    try writeBookmarks(allocator, &bookmarks);
}

fn handleJump(allocator: std.mem.Allocator, target: [:0]const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const is_windows = builtin.os.tag == .windows;

    // First check if target is a local directory in current working directory
    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd);

    // Create candidate path: current directory + target
    const candidate = try std.fs.path.join(allocator, &[_][]const u8{ cwd, target });
    defer allocator.free(candidate);

    // Check if candidate exists and is accessible
    if (std.fs.accessAbsolute(candidate, .{})) {
        try stdout.print("{s}\n", .{candidate});
        return;
    } else |_| {} // Ignore errors, we'll try other options

    // Then check if target is a bookmark
    var bookmarks = try readBookmarks(allocator);
    defer {
        var mutable_bookmarks = bookmarks;
        mutable_bookmarks.deinit();
    }

    if (bookmarks.get(target)) |path| {
        if (is_windows) {
            // Windows - just return the path, let the shell handle cd
            try stdout.print("{s}\n", .{path});
            return;
        } else {
            // Unix - verify path exists
            if (std.fs.accessAbsolute(path, .{})) {
                try stdout.print("{s}\n", .{path});
                return;
            } else |_| {
                std.debug.print("error: bookmarked path '{s}' no longer exists\n", .{path});
                std.process.exit(1);
            }
        }
    }

    // Finally check if target is a valid path (absolute or relative)
    const resolved_path = try std.fs.path.resolve(allocator, &.{target});

    if (is_windows) {
        // Windows - return the resolved path
        try stdout.print("{s}\n", .{resolved_path});
        return;
    } else {
        // Unix - verify path is absolute and accessible
        if (std.fs.path.isAbsolute(resolved_path)) {
            if (std.fs.accessAbsolute(resolved_path, .{})) {
                try stdout.print("{s}\n", .{resolved_path});
                return;
            } else |err| {
                std.debug.print("error: path '{s}' not accessible ({s})\n", .{ resolved_path, @errorName(err) });
            }
        } else {
            std.debug.print("error: resolved path is not absolute: '{s}'\n", .{resolved_path});
        }
    }

    // If nothing worked, show help
    try printHelp(std.io.getStdErr().writer());
    std.process.exit(1);
}
