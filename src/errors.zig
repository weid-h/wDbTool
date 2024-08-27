const std = @import("std");
const utils = @import("./utils.zig");
const sqlite = @import("sqlite");

pub const WriteError = std.posix.WriteError;

pub const InvalidMigrationFileName = std.fmt.ParseIntError;

pub const MigrationError = error{
    GeneralError,
};

pub const SqliteError = sqlite.Error || sqlite.Db.InitError || sqlite.DynamicStatement.PrepareError;

pub const FilesystemError = std.fs.File.OpenError || std.fs.Dir.RealPathAllocError;

pub const AllocatorError = std.mem.Allocator.Error;

pub const Error = WriteError || MigrationError || utils.OptionError || SqliteError || FilesystemError || AllocatorError || InvalidMigrationFileName;
