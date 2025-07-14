# Allocators

## main.zig
```zig

const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const Person = struct {
    name: []const u8,
    age: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, name: []const u8, age: u32) !*Person {
        const person = try allocator.create(Person);
        person.* = Person{
            .name = name,
            .age = age,
            .allocator = allocator,
        };
        return person;
    }

    pub fn deinit(self: *Person) void {
        self.allocator.destroy(self);
    }

    pub fn print(self: *Person) void {
        std.debug.print("Name: {s}, Age: {d}\n", .{self.name, self.age});
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const person = try Person.init(allocator, "Harry", 23);
    person.print();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);
    const allocator2 = gpa.allocator();

    const person2 = try Person.init(allocator2, "Lloyd", 35);
    defer person2.deinit();
    person2.print();

    const buffer = try allocator2.alloc(u8, 1024);
    defer allocator2.free(buffer);
}

```

## build.zig
```zig

const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}

```
