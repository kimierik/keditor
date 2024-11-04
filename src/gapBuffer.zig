const std = @import("std");

//TODO:
//add writer() to buffer class

pub fn GapBuffer(T: type) type {
    return struct {
        const Self = @This();

        position: usize,
        gap_size: usize,

        capacity: usize,
        items: []T,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .position = 0,
                .gap_size = 10,
                .capacity = 10,
                .allocator = allocator,
                .items = try allocator.alloc(T, 10),
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        /// grow items
        fn grow(self: *Self) !void {
            var newarra = try self.allocator.alloc(T, self.capacity * 2);

            //newarra[0..position] = items[0..position]
            //+ gap
            //newarra[position+gap ..newarra.len] = items[position..items.len]
            //then nuke old items and set new arra to that

            for (0..self.position) |i| {
                newarra[i] = self.items[i];
            }
            self.gap_size = self.capacity * 2 - self.capacity;
            self.capacity *= 2;

            for (self.position..self.items.len) |i| {
                newarra[i + self.gap_size] = self.items[i];
            }

            self.allocator.free(self.items);
            self.items = newarra;
        }

        /// insert item
        pub fn insert(self: *Self, item: T) !void {
            if (self.position == self.capacity or self.gap_size == 0) {
                try self.grow();
            }

            self.items[self.position] = item;
            self.position += 1;
            self.gap_size -= 1;
        }

        /// deletes an item and moves one to the left
        /// Returns the deleted item. return null if we cannot delete
        pub fn delete(self: *Self) ?T {
            if (self.position == 0)
                return null;

            const tmp = self.items[self.position - 1];
            self.left();
            self.gap_size += 1;
            return tmp;
        }

        pub fn left(self: *Self) void {
            if (self.position == 0)
                return;

            self.position -= 1;
            self.items[self.position + self.gap_size] = self.items[self.position];
            self.items[self.position] = 0; // or whattever we end up defining as the gap character
        }

        pub fn right(self: *Self) void {
            // we should not be able to move r if there is no characters to the right of us aka (self.position+ self.gapsize=self.items.len)
            // i do not know how to program
            if (self.position == self.items.len or self.position + 1 == self.items.len)
                return;

            self.items[self.position] = self.items[self.position + self.gap_size - 1];
            self.items[self.position + self.gap_size - 1] = 0; // or whattever we end up defining as the gap character
            self.position += 1;
        }

        /// gets a caller owned null terminated slice with the gap removed
        /// will get invalidated when something is inserted
        pub fn getList(self: Self, allocator: std.mem.Allocator) ![]T {
            const left_slice = self.items[0..self.position];
            const right_slice = self.items[self.position + self.gap_size .. self.items.len];
            const items = try allocator.alloc(T, left_slice.len + right_slice.len + 1);

            @memcpy(items.ptr, left_slice);
            @memcpy(items.ptr + left_slice.len, right_slice);
            items[left_slice.len + right_slice.len] = '\x00';

            return items;
        }
    };
}

test "insert" {
    var gp = try GapBuffer(u8).init(std.testing.allocator);
    defer gp.deinit();
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    const s = std.mem.sliceTo(gp.items, 170);
    try std.testing.expect(std.mem.eql(u8, s, "abc"));
}

test "insert alot" {
    var gp = try GapBuffer(u8).init(std.testing.allocator);
    defer gp.deinit();
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    const s = std.mem.sliceTo(gp.items, 170);
    try std.testing.expect(std.mem.eql(u8, s, "abcabcabcabc"));
}

test "insert and move left" {
    var gp = try GapBuffer(u8).init(std.testing.allocator);
    defer gp.deinit();
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    try gp.insert('d');
    try gp.insert('e');
    try gp.insert('f');
    try gp.insert('g');
    try gp.insert('h');
    try gp.insert('i');
    gp.left();
    try gp.insert('j');
    try gp.insert('k');
    try gp.insert('l');
    const s = std.mem.sliceTo(gp.items, 170);
    try std.testing.expect(std.mem.eql(u8, s, "abcdefghjkl"));
}

test "insert and move right" {
    var gp = try GapBuffer(u8).init(std.testing.allocator);
    defer gp.deinit();
    try gp.insert('a');
    try gp.insert('b');
    try gp.insert('c');
    try gp.insert('d');
    try gp.insert('e');
    try gp.insert('f');
    try gp.insert('g');
    gp.right();
    try gp.insert('h');
    try gp.insert('i');
    try gp.insert('j');
    try gp.insert('k');
    try gp.insert('l');
    const s = gp.items[0..gp.position];
    try std.testing.expect(std.mem.eql(u8, s, "abcdefg\xAAhijkl"));
}
