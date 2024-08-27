const std = @import("std");
const process = std.process;
const mem = std.mem;
const sqlite = @import("./sqlite.zig");
const utils = @import("./utils.zig");
const errors = @import("./errors.zig");
const migrate = @import("./migrate.zig");
const create = @import("./create.zig");

const generalInstructions =
    \\wDbTool v0.0.01
    \\
    \\Usage: wdb [command] [options]
    \\
    \\Commands:
    \\
    \\  migrate    Run database migrations
    \\  create     Create database migration
    \\
    \\General options:
    \\  -h, --help  Print command-specific usage
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allocator = gpa.allocator();

    var arena_instance = std.heap.ArenaAllocator.init(allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const args = try process.argsAlloc(arena);

    runArgs(args, arena) catch |err| {
        std.debug.print("program exited with error: {}", .{err});
    };
}

fn runArgs(args: []const []const u8, arena: mem.Allocator) errors.Error!void {
    if (args.len == 1) {
        try std.io.getStdOut().writeAll(generalInstructions);
    } else if (mem.eql(u8, args[1], "migrate")) {
        try migrate.runMigrate(args, arena);
    } else if (mem.eql(u8, args[1], "create")) {
        if (args.len == 9) {
            const options = try utils.parseMigrationOptions(args, arena);
            try create.CreateMigration(args[2], options.MigrationDir, arena);
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
