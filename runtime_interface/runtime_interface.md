# Runtime Interface

## main.zig
```zig

const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// Vtable - defines the interface contract
pub const ShapeVTable = struct {
    getArea: *const fn (ctx: *anyopaque) f32,
    describe: *const fn (ctx: *anyopaque) []const u8,
    deinit: *const fn (ctx: *anyopaque, allocator: Allocator) void,
};

// Trait Object - interface instance
pub const Shape = struct {
    ctx: *anyopaque,
    vtable: *const ShapeVTable,
    allocator: Allocator,

    pub fn getArea(self: @This()) f32 {
        return self.vtable.getArea(self.ctx);
    }

    pub fn describe(self: @This()) []const u8 {
        return self.vtable.describe(self.ctx);
    }

    pub fn deinit(self: @This()) void {
        self.vtable.deinit(self.ctx, self.allocator);
    }
};

const Circle = struct {
    radius: f32,

    pub fn init(allocator: Allocator, radius: f32) !*Circle {
        const self = try allocator.create(Circle);
        self.radius = radius;
        return self;
    }

    pub fn getAreaImpl(ctx: *anyopaque) f32 {
        const self: *Circle = @ptrCast(@alignCast(ctx));
        return std.math.pi * self.radius * self.radius;
    }

    pub fn describeImpl(ctx: *anyopaque) []const u8 {
        const self: *Circle = @ptrCast(@alignCast(ctx));
        return std.fmt.allocPrint(std.heap.page_allocator, "Circle (radius: {d:.2})", .{self.radius}) catch "Error describing Circle";
    }

    pub fn deinitImpl(ctx: *anyopaque, allocator: Allocator) void {
        const self: *Circle = @ptrCast(@alignCast(ctx));
        allocator.destroy(self);
    }

    const vtable = ShapeVTable{
        .getArea = getAreaImpl,
        .describe = describeImpl,
        .deinit = deinitImpl,
    };

    pub fn asShape(self: *Circle, allocator: Allocator) Shape {
        return Shape{
            .ctx = self,
            .vtable = &vtable,
            .allocator = allocator,
        };
    }
};

const Rectangle = struct {
    width: f32,
    height: f32,

    pub fn init(allocator: Allocator, width: f32, height: f32) !*Rectangle {
        var self = try allocator.create(Rectangle);
        self.width = width;
        self.height = height;
        return self;
    }

    fn getAreaImpl(ctx: *anyopaque) f32 {
        const self: *Rectangle = @ptrCast(@alignCast(ctx));
        return self.width * self.height;
    }

    fn describeImpl(ctx: *anyopaque) []const u8 {
        const self: *Rectangle = @ptrCast(@alignCast(ctx));
        return std.fmt.allocPrint(std.heap.page_allocator, "Rectangle (width: {d:.2}, height: {d:.2})", .{self.width, self.height}) catch "Error describing Rectangle";
    }

    fn deinitImpl(ctx: *anyopaque, allocator: Allocator) void {
        const self: *Rectangle = @ptrCast(@alignCast(ctx));
        allocator.destroy(self);
    }

    const vtable = ShapeVTable{
        .getArea = getAreaImpl,
        .describe = describeImpl,
        .deinit = deinitImpl,
    };

    pub fn asShape(self: *Rectangle, allocator: Allocator) Shape {
        return Shape{ .ctx = self, .vtable = &vtable, .allocator = allocator };
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const circle_instance = try Circle.init(allocator, 5.0);
    const rectangle_instance = try Rectangle.init(allocator, 4.0, 6.0);

    const cirle_shape = circle_instance.asShape(allocator);
    const rectangle_shape = rectangle_instance.asShape(allocator);

    var shapes = std.ArrayList(Shape).init(allocator);
    defer {
        for (shapes.items) |s| {
            s.deinit();
        }
    }

    try shapes.append(cirle_shape);
    try shapes.append(rectangle_shape);

    for (shapes.items) |s| {
        const description = s.describe();
        print("{s}, Area: {d:.2}\n", .{description, s.getArea()});
        allocator.free(description);
    }
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
