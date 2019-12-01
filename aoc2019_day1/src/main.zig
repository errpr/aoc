const std = @import("std");

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    var result: u128 = 0;
    var iterator = std.mem.tokenize(file_string, "\n ");
    
    while (iterator.next()) |token| {
        const mass = std.fmt.parseUnsigned(u32, token, 10) catch continue;
        const fuel = @divTrunc(mass, 3) - 2;
        result += fuel;
    }
    
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("Result: {}!\n", result);
}