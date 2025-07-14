const std = @import("std");
const print = std.debug.print;

const Circle = struct {
    x: f32,
    y: f32,
    radius: f32,
};

const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

const DrawingElement = union(enum) {
    circle: Circle,
    rectangle: Rectangle,
};

pub fn getArea(element: DrawingElement) f32 {
    return switch (element) {
        .circle => |c| std.math.pi * c.radius * c.radius,
        .rectangle => |r| r.width * r.height,
    };
}

pub fn draw(element: DrawingElement) void {
    switch (element) {
        .circle => |c| {
            print(
                "Drawing Circle at ({d:.1}, {d:.1}) with radius {d:.1}\n",
                .{c.x, c.y, c.radius}
            );
        },
        .rectangle => |r| {
            print(
                "Drawing Rectangle at ({d:.1}, {d:.1}) with width {d:.1}, " ++
                "height {d:.1}\n",
                .{r.x, r.y, r.width, r.height}
            );
        },
    }
}

pub fn moveElement(element: *DrawingElement, dx: f32, dy: f32) void {
    switch (element.*) {
        .circle => |*c| {
            c.x += dx;
            c.y += dy;
        },
        .rectangle => |*r| {
            r.x += dx;
            r.y += dy;
        },
    }
}

pub fn main() !void {
    const my_circle = Circle{
        .x = 10.0,
        .y = 20.0,
        .radius = 5.0,
    };
    const my_rectangle = Rectangle{
        .x = 30.0,
        .y = 40.0,
        .width = 10.0,
        .height = 8.0,
    };

    var elements = std.ArrayList(DrawingElement).init(std.heap.page_allocator);
    defer elements.deinit();

    try elements.append(.{ .circle = my_circle });
    try elements.append(.{ .rectangle = my_rectangle });

    print("--- Initial Drawing Elements -----------------------------\n", .{});
    for (elements.items) |element| {
        draw(element);
        print("  Area: {d:.2}\n", .{getArea(element)});
    }
    print("--------------------------------------------------------\n\n", .{});

    print("--- Moving Elements --------------------------------------\n", .{});
    moveElement(&elements.items[0], 5.0, -2.0);
    moveElement(&elements.items[1], -10.0, 15.0);

    print("--- Elements After Move ----------------------------------\n", .{});
    for (elements.items) |element| {
        draw(element);
        print("  Area: {d:.2}\n", .{getArea(element)});
    }
    print("----------------------------------------------------------\n", .{});
}
