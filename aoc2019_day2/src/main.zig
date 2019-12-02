const std = @import("std");

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");

    var noun: u32 = 0;
    var verb: u32 = 0;
    while (true) {
        var iterator = std.mem.tokenize(file_string, ",");
        var data = [_]u32{0} ** 256;
        var i: u32 = 0;
        while (iterator.next()) |token| {
            data[i] = std.fmt.parseUnsigned(u32, token, 10) catch 0;
            i += 1;
        }

        data[1] = noun;
        data[2] = verb;

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

        if (data[0] == 19690720) {
            std.debug.warn("noun: {}, verb: {}", noun, verb);
            break;
        } else if (noun < 99) {
            noun += 1;
        } else if (verb < 99) {
            noun = 0;
            verb += 1;
        } else {
            std.debug.warn("Never found it");
        }
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