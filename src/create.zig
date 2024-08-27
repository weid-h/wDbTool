const std = @import("std");
const errors = @import("./errors.zig");
const fs = std.fs;
const utils = @import("./utils.zig");

const MigrationDirection = enum {
    Up,
    Down,
};

const MigrationFile = struct {
    Number: u16,
    Name: []const u8,
    Direction: MigrationDirection,
    FileName: []const u8,
};

const createMigrationInstructions =
    \\Usage: wdb create [migration_name]
    \\
    \\Options:
    \\  -dir [path] REQUIRED  path to database migrations directory
    \\  -cs [connection string] REQUIRED database connection string
    \\  -dbe [database engine]  REQUIRED Database engine, currently supports: SQLite
;

pub fn RunCreate(args: []const []const u8, arena: std.mem.Allocator) errors.Error!void {
    if (args.len == 9) {
        const options = try utils.parseMigrationOptions(args, arena);
        try CreateMigration(args[2], options.MigrationDir, arena);
    } else {
        try std.io.getStdOut().writeAll(createMigrationInstructions);
    }
}

fn ParseFileName(name: []const u8) errors.InvalidMigrationFileName!MigrationFile {
    var numberEnd: usize = 0;
    var foundNumberEnd = false;

    var lastDash: usize = 0;
    var lastDot: usize = 0;

    for (name, 0..) |char, index| {
        if (char == '_') {
            lastDash = index + 1;

            if (!foundNumberEnd) {
                numberEnd = index;
                foundNumberEnd = true;
            }
        }
        if (char == '.') {
            lastDot = index;
        }
    }

    const number = try std.fmt.parseInt(u16, name[0..numberEnd], 10);

    var dir = MigrationDirection.Down;

    if (std.mem.eql(u8, name[lastDash..lastDot], "up")) {
        dir = MigrationDirection.Up;
    }

    std.debug.print("parsed migration file: number: {d}, direction: {s}, name: {s}, filename: {s}\n", .{ number, name[lastDash..lastDot], name[numberEnd + 1 .. lastDash - 1], name });

    return MigrationFile{
        .Direction = dir,
        .Name = name[numberEnd + 1 .. lastDash - 1],
        .Number = number,
        .FileName = name,
    };
}

fn CreateMigration(name: []const u8, migrationDirPath: []const u8, arena: std.mem.Allocator) errors.Error!void {
    const cwd = fs.cwd();

    const migrationDir = try cwd.openDir(migrationDirPath, .{ .iterate = true });

    var miter = migrationDir.iterate();

    var fileList = std.ArrayList(MigrationFile).init(arena);

    var lastNumber: u16 = 0;

    while (try miter.next()) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        const file = try ParseFileName(entry.name);

        if (file.Number > lastNumber) {
            lastNumber = file.Number;
        }

        try fileList.append(try ParseFileName(entry.name));
    }

    const upName = try std.fmt.allocPrint(arena, "{d}_{s}_up.sql", .{ lastNumber + 1, name });
    const downName = try std.fmt.allocPrint(arena, "{d}_{s}_down.sql", .{ lastNumber + 1, name });

    std.log.info("Creating upfile: {s}\n", .{upName});
    const upFile = try migrationDir.createFile(upName, .{});
    upFile.close();

    const downFile = try migrationDir.createFile(downName, .{});
    downFile.close();
}
