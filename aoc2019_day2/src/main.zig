const std = @import("std");

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");

    var iterator = std.mem.tokenize(file_string, ",");
    var data = [_]u32{0} ** 256;
    var i: u32 = 0;
    while (iterator.next()) |token| {
        data[i] = std.fmt.parseUnsigned(u32, token, 10) catch 0;
        i += 1;
    }

    // "before running the program, replace position 1 with the value 12 and replace position 2 with the value 2"
    // not sure what this means, I guess can't be fucked to provide the correct puzzle input?????????????????????
    data[1] = 12;
    data[2] = 2;

    var opcode_position: u32 = 0;
    while(true) {
        switch(data[opcode_position]) {
            1 => operation_one(&data, opcode_position),
            2 => operation_two(&data, opcode_position),
            99 => break,
            else => unreachable,
        }
        opcode_position += 4;
    }
    
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("Result: ");

    var j: u32 = 0;
    while (j < i) : (j += 1) {
        try stdout.print("{},", data[j]);
    }
}

fn operation_one(data: []u32, opcode_position: u32) void {
    const a_position = data[opcode_position + 1];
    const b_position = data[opcode_position + 2];
    const store_position = data[opcode_position + 3];
    data[store_position] = data[a_position] + data[b_position];
}

fn operation_two(data: []u32, opcode_position: u32) void {
    const a_position = data[opcode_position + 1];
    const b_position = data[opcode_position + 2];
    const store_position = data[opcode_position + 3];
    data[store_position] = data[a_position] * data[b_position];
}