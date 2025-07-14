const std = @import("std");
const print = std.debug.print;

pub fn GeneralLogger(comptime T: type) type {
    return struct {
        logger_instance: T,
    
        pub fn init(logger: T) @This() {
            return .{ .logger_instance = logger };
        }
    
        pub fn log(self: @This(), message: []const u8) !void {
            try self.logger_instance.log(message);
        }
    };
}

const ConsoleLogger = struct {
    pub fn log(self: @This(), message: []const u8) !void {
        _ = self;
        print("[Console] {s}\n", .{message});
    }
};

const FileLogger = struct {
    file: std.fs.File,

    pub fn init(path: []const u8) !@This() {
        const file = try std.fs.cwd().createFile(path, .{});
        const file_logger = FileLogger{
            .file = file,
        };
        return file_logger;
    }

    pub fn deinit(self: @This()) void {
        self.file.close();
    }

    pub fn log(self: @This(), message: []const u8) !void {
        try self.file.writeAll(message);
        try self.file.writeAll("\n");
    }
};

pub fn main() !void {
    const console_logger = ConsoleLogger{};

    const file_logger = try FileLogger.init("app.log");
    defer file_logger.deinit();

    const logger = GeneralLogger(FileLogger).init(file_logger);
    try logger.log("Hello2");

    const logger2 = GeneralLogger(ConsoleLogger).init(console_logger);
    try logger2.log("Hello1");
}
