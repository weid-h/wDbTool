const std = @import("std");
const process = std.process;
const mem = std.mem;

pub const DbEngine = enum(usize) {
    SQLite = 0,

    pub const NameTable = [@typeInfo(DbEngine).Enum.fields.len][:0]const u8{"SQLite"};

    pub fn str(self: DbEngine) [:0]const u8 {
        return NameTable[@intFromEnum(self)];
    }
};

pub const MigrationOptions = struct {
    MigrationDir: []const u8,
    ConnectionString: [:0]const u8,
    Engine: DbEngine,
};

pub const OptionError = error{
    ParsingError,
    OutOfMemory,
};

pub fn parseMigrationOptions(args: []const []const u8, arena: mem.Allocator) OptionError!MigrationOptions {
    if (args.len <= 6) {
        const err = std.io.getStdOut().writeAll("parsing migration options requires a minimum of 6 args \n");
        if (@TypeOf(err) != void) {
            return OptionError.ParsingError;
        }
        return OptionError.ParsingError;
    }

    var options = MigrationOptions{
        .ConnectionString = "",
        .Engine = DbEngine.SQLite,
        .MigrationDir = "",
    };

    var hasDir = false;
    var hasCs = false;
    var hasDbe = false;

    for (args, 0..) |arg, index| {
        if (mem.eql(u8, arg, "-dir")) {
            const strlen = args[index + 1].len + 1;
            const str: []u8 = try arena.alloc(u8, strlen);
            str[strlen - 1] = 0;

            mem.copyForwards(u8, str, args[index + 1]);

            options.MigrationDir = str;
            hasDir = true;
            continue;
        }

        if (mem.eql(u8, arg, "-cs")) {
            const strlen = args[index + 1].len + 1;
            const str: []u8 = try arena.alloc(u8, strlen);
            str[strlen - 1] = 0;

            mem.copyForwards(u8, str, args[index + 1]);

            options.ConnectionString = str[0 .. strlen - 1 :0];
            hasCs = true;
            continue;
        }

        if (mem.eql(u8, arg, "-dbe")) {
            if (mem.eql(u8, args[index + 1], "sqlite")) {
                options.Engine = DbEngine.SQLite;
                hasDbe = true;
            }
            continue;
        }
    }

    if (!(hasDir and hasCs and hasDbe)) {
        const err = std.io.getStdOut().writeAll("missing required option \n");
        if (@TypeOf(err) != void) {
            return OptionError.ParsingError;
        }
        return OptionError.ParsingError;
    }

    std.log.info("Parsed options:\n    Connection string: {s}\n    Migration dir: {s}\n    Engine: {s}\n\n", .{ options.ConnectionString, options.MigrationDir, options.Engine.str() });

    return options;
}
