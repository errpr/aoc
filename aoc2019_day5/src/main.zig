const std = @import("std");

const IMMEDIATE_MODE = 1;
const POSITION_MODE = 0;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    // const file_string = "3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9";
    // const file_string = "3,3,1105,-1,9,1101,0,0,12,4,12,99,1";
    // const file_string = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";

    var iterator = std.mem.tokenize(file_string, ",");

    var data = [_]i32{0} ** 1024;
    var i: u32 = 0;
    while (iterator.next()) |token| {
        data[i] = std.fmt.parseInt(i32, token, 10) catch 0;
        i += 1;
    }

    var instructionPtr: u32 = 0;
    while(true) {
        std.debug.warn("inst {} data {} ", instructionPtr, data[instructionPtr]);
        switch(extractOpcode(data[instructionPtr])) {
            1 => add(&data, &instructionPtr),
            2 => mul(&data, &instructionPtr),
            3 => in(&data, &instructionPtr),
            4 => out(&data, &instructionPtr),
            5 => jmpTrue(&data, &instructionPtr),
            6 => jmpFalse(&data, &instructionPtr),
            7 => lessThan(&data, &instructionPtr),
            8 => equals(&data, &instructionPtr),
            99 => break,
            else => unreachable,
        }
    }
}

fn add(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);

    std.debug.warn("add {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2], 
        "P", data[instructionPtr.* + 3]);

    const a = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];
    const storePosition = @intCast(u32, data[instructionPtr.* + 3]);

    data[storePosition] = a + b;

    instructionPtr.* += 4;
}

fn mul(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);

    std.debug.warn("mul {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2], 
        "P", data[instructionPtr.* + 3]);

    const a = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];
    const storePosition = @intCast(u32, data[instructionPtr.* + 3]);

    data[storePosition] = a * b;

    instructionPtr.* += 4;
}

fn in(data: []i32, instructionPtr: *u32) void {
    std.debug.warn("in P:{}\n", data[instructionPtr.* + 1]);
    const storePosition =  @intCast(u32, data[instructionPtr.* + 1]);

    data[storePosition] = getInput();

    instructionPtr.* += 2;
}

fn out(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);
    std.debug.warn("out {}:{}\n", if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1]);
    const outValue = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];

    output(outValue);

    instructionPtr.* += 2;
}

fn jmpTrue(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);
    std.debug.warn("jmpTrue {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2]);

    const condition = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const label = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];

    if (condition != 0) {
        instructionPtr.* = @intCast(u32, label);
    } else {
        instructionPtr.* += 3;
    }
}

fn jmpFalse(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);
    std.debug.warn("jmpFalse {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2]);

    const condition = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const label = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];

    if (condition == 0) {
        instructionPtr.* = @intCast(u32, label);
    } else {
        instructionPtr.* += 3;
    }
}

fn lessThan(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);
    std.debug.warn("lessThan {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2],
        "P", data[instructionPtr.* + 3]);
    
    const a = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];
    const r = @intCast(u32, data[instructionPtr.* + 3]);

    data[r] = if (a < b) 1 else 0;
    instructionPtr.* += 4;
}

fn equals(data: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(data[instructionPtr.*]);
    std.debug.warn("equals {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", data[instructionPtr.* + 2],
        "P", data[instructionPtr.* + 3]);
    
    const a = if (modes[0] == IMMEDIATE_MODE) data[instructionPtr.* + 1] else data[@intCast(u32, data[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) data[instructionPtr.* + 2] else data[@intCast(u32, data[instructionPtr.* + 2])];
    const r = @intCast(u32, data[instructionPtr.* + 3]);

    data[r] = if (a == b) 1 else 0;
    instructionPtr.* += 4;
}

fn extractOpcode(instruction: i32) u32 {
    return @intCast(u32, instruction) % 100;
}

fn extractParameterModes(instruction: i32) [3]u32 {
    const firstTwoDigits = extractOpcode(instruction);
    var rest = (@intCast(u32, instruction) - firstTwoDigits) / 100;

    const a = rest % 10;
    rest = (rest - a) / 10;
    const b = rest % 10;
    rest = (rest - b) / 10;
    const c = rest % 10;

    return [_]u32 {
        a,
        b,
        c
    };
}

fn output(code: i32) void {
    std.debug.warn(" {}\n", code);
}

fn getInput() i32 {
    return 5;
}