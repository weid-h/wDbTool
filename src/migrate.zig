const std = @import("std");
const process = std.process;
const mem = std.mem;
const sqlite = @import("./sqlite.zig");
const utils = @import("./utils.zig");
const errors = @import("./errors.zig");

const migrateInstructions =
    \\Usage: wdb migrate [command] [options]
    \\
    \\Commands:
    \\  up  Apply database migrations
    \\  down Reverse database migrations
    \\
    \\General options:
    \\  -h, --help Print command-specific usage
;

const migrateUpInstructions =
    \\Usage: wdb migrate up [options]
    \\
    \\Options:
    \\  -dir [path] REQUIRED  path to database migrations directory
    \\  -cs [connection string] REQUIRED database connection string
    \\  -dbe [database engine]  REQUIRED Database engine, currently supports: SQLite
;

const migrateDownInstructions =
    \\Usage: wdb migrate down [options]
    \\
    \\Options:
    \\  -dir [path]  path to database migrations directory
    \\  -cs [connection string] database connection string
;

pub fn runMigrate(args: []const []const u8, arena: mem.Allocator) errors.Error!void {
    if (args.len == 2) {
        try std.io.getStdOut().writeAll(migrateInstructions);
    } else if (mem.eql(u8, args[2], "up")) {
        try runMigrateUp(args, arena);
    } else if (mem.eql(u8, args[2], "down")) {
        try std.io.getStdOut().writeAll(migrateDownInstructions);
    }
}

fn runMigrateUp(args: []const []const u8, arena: mem.Allocator) errors.Error!void {
    if (args.len != 9) {
        try std.io.getStdOut().writeAll(migrateUpInstructions);
        return;
    }

    const options = try utils.parseMigrationOptions(args, arena);

    switch (options.Engine) {
        utils.DbEngine.SQLite => {
            try sqlite.runMigrateUpSqlite(&options);
        },
    }
}
