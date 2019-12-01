const std = @import("std");
const MINIMUM_MASS_THAT_REQUIRES_FUEL = (1 + 2) * 3;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    var total_fuel: u32 = 0;
    var iterator = std.mem.tokenize(file_string, "\n ");
    
    while (iterator.next()) |token| {
        const mass = std.fmt.parseUnsigned(u32, token, 10) catch continue;
        var new_fuel = @divTrunc(mass, 3) - 2;
        total_fuel += new_fuel;
        
        while (new_fuel > MINIMUM_MASS_THAT_REQUIRES_FUEL) {
            new_fuel = @divTrunc(new_fuel, 3) - 2;
            total_fuel += new_fuel;
        }
    }
    
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("Result: {}!\n", total_fuel);
}