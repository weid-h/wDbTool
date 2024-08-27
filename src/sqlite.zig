const std = @import("std");
const process = std.process;
const mem = std.mem;
const utils = @import("./utils.zig");
const errors = @import("./errors.zig");

pub fn runMigrateUpSqlite(options: *const utils.MigrationOptions) errors.Error!void {
    const sqlite = @import("sqlite");

    var db = try sqlite.Db.init(.{ .mode = sqlite.Db.Mode{ .File = options.ConnectionString }, .open_flags = .{
        .create = true,
        .write = true,
    }, .threading_mode = .MultiThread });

    var diags = sqlite.Diagnostics{};
    var stmt = db.prepareWithDiags("create table sup (id integer primary key)", .{ .diags = &diags }) catch |err| {
        std.log.err("{}.\nDiagnostics: {s}\n", .{ err, diags });
        return err;
    };

    stmt.exec(.{}, .{}) catch |err| {
        std.log.err("error executing statement: {}\n", .{err});
    };

    defer stmt.deinit();
}
