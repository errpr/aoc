const std = @import("std");

const IMMEDIATE_MODE = 1;
const POSITION_MODE = 0;
const RAM_SIZE = 1024;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    // const file_string = "3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0";
    // const file_string = "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0";
    // const file_string = "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0";

    var iterator = std.mem.tokenize(file_string, ",");

    var data = [_]i32{0} ** RAM_SIZE;
    {
        var i: u32 = 0;
        while (iterator.next()) |token| {
            data[i] = std.fmt.parseInt(i32, token, 10) catch 0;
            i += 1;
        }
    }

    var workingSet = [_]i32{0} ** RAM_SIZE;
    var permutations = generatePermutations(5, [_]i32 { 0, 1, 2, 3, 4 });
    var maxPermutation = [_]i32 {0,0,0,0,0};
    var maxOutput: i32 = std.math.minInt(i32);
    for (permutations) |permutation| {
        var input: i32 = 0;
        var output: i32 = 0;
        const amplifiers = [5]u8 { 'A', 'B', 'C', 'D', 'E' };
        std.debug.warn(" permutation: {} {} {} {} {}\n", permutation[0], permutation[1], permutation[2], permutation[3], permutation[4]);
        var i: u32 = 0;
        while (i < 5) : (i += 1) {
            std.mem.swap(i32, &input, &output);
            arrayCopy(RAM_SIZE, &data, &workingSet);
            runProgramOnAmplifier(workingSet[0..], permutation[i], &input, &output);
            std.debug.warn("\n amplifier {} output: {}\n", amplifiers[i], output);
        }

        if (output > maxOutput) {
            maxOutput = output;
            arrayCopy(5, &permutation, &maxPermutation);
        }
    }
    std.debug.warn("maxOutput: {}\nmaxPermutation: {} {} {} {} {}", maxOutput, maxPermutation[0], maxPermutation[1], maxPermutation[2], maxPermutation[3], maxPermutation[4]);
}

fn arrayCopy(comptime array_size: comptime_int, source: *const [array_size]i32, dest: *[array_size]i32) void {
    var i: u32 = 0;
    while (i < array_size) : (i += 1) {
        dest.*[i] = source.*[i];
    }
}

fn generatePermutations(comptime n: comptime_int, comptime basePermutation: [n]i32) [factorial(n)][n]i32 {
    var permutations: [factorial(n)][n]i32 = [1][n]i32 { basePermutation } ** factorial(n);
    var indexes: [n]u32 = [1]u32 { 0 } ** n;
    var i: u32 = 0;
    var j: u32 = 0;
    @setEvalBranchQuota(65536);
    while (i < n) {
        if (indexes[i] < i) {
            j += 1;
            arrayCopy(n, &permutations[j - 1], &permutations[j]);
            swapElement(n, &permutations, j, if (i % 2 == 0) 0 else indexes[i], i);
            indexes[i] += 1;
            i = 0;
        } else {
            indexes[i] = 0;
            i += 1;
        }
    }
    return permutations;
}

fn swapElement(comptime size: comptime_int, array: *[factorial(size)][size]i32, i: u32, index1: u32, index2: u32) void {
    const temp = array.*[i][index1];
    array.*[i][index1] = array.*[i][index2];
    array.*[i][index2] = temp;
}

fn factorial(comptime int: comptime_int) comptime_int {
    var copy = int;
    var result: comptime_int = 1;
    while (copy > 0) : (copy -= 1) {
        result *= copy;
    }
    return result;
}

fn runProgramOnAmplifier(ram: []i32, phase: i32, input: *i32, output: *i32) void {
    var instructionPtr: u32 = 0;
    var readPhase = false;
    while(true) {
        std.debug.warn("inst {} data {} ", instructionPtr, ram[instructionPtr]);
        switch(extractOpcode(ram[instructionPtr])) {
            1 => add(ram, &instructionPtr),
            2 => mul(ram, &instructionPtr),
            3 => in(ram, &instructionPtr, input, &readPhase, phase), // this is so bad but whatever
            4 => out(ram, &instructionPtr, output),
            5 => jmpTrue(ram, &instructionPtr),
            6 => jmpFalse(ram, &instructionPtr),
            7 => lessThan(ram, &instructionPtr),
            8 => equals(ram, &instructionPtr),
            99 => break,
            else => unreachable,
        }
    }
}

fn add(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);

    std.debug.warn("add {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2], 
        "P", ram[instructionPtr.* + 3]);

    const a = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];
    const storePosition = @intCast(u32, ram[instructionPtr.* + 3]);

    ram[storePosition] = a + b;

    instructionPtr.* += 4;
}

fn mul(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);

    std.debug.warn("mul {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2], 
        "P", ram[instructionPtr.* + 3]);

    const a = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];
    const storePosition = @intCast(u32, ram[instructionPtr.* + 3]);

    ram[storePosition] = a * b;

    instructionPtr.* += 4;
}

fn in(ram: []i32, instructionPtr: *u32, input: *i32, readPhase: *bool, phase: i32) void {
    std.debug.warn("in P:{}\n", ram[instructionPtr.* + 1]);
    const storePosition =  @intCast(u32, ram[instructionPtr.* + 1]);

    if (!readPhase.*) {
        ram[storePosition] = phase;
        readPhase.* = true;
    } else {
        ram[storePosition] = input.*;
    }

    instructionPtr.* += 2;
}

fn out(ram: []i32, instructionPtr: *u32, output: *i32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);
    std.debug.warn("out {}:{}\n", if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1]);
    const outValue = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];

    std.debug.warn(" outputting {}\n", outValue);
    output.* = outValue;

    instructionPtr.* += 2;
}

fn jmpTrue(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);
    std.debug.warn("jmpTrue {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2]);

    const condition = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const label = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];

    if (condition != 0) {
        instructionPtr.* = @intCast(u32, label);
    } else {
        instructionPtr.* += 3;
    }
}

fn jmpFalse(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);
    std.debug.warn("jmpFalse {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2]);

    const condition = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const label = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];

    if (condition == 0) {
        instructionPtr.* = @intCast(u32, label);
    } else {
        instructionPtr.* += 3;
    }
}

fn lessThan(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);
    std.debug.warn("lessThan {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2],
        "P", ram[instructionPtr.* + 3]);
    
    const a = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];
    const r = @intCast(u32, ram[instructionPtr.* + 3]);

    ram[r] = if (a < b) 1 else 0;
    instructionPtr.* += 4;
}

fn equals(ram: []i32, instructionPtr: *u32) void {
    const modes = extractParameterModes(ram[instructionPtr.*]);
    std.debug.warn("equals {}:{} {}:{} {}:{}\n", 
        if (modes[0] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 1], 
        if (modes[1] == IMMEDIATE_MODE) "I" else "P", ram[instructionPtr.* + 2], 
        "P", ram[instructionPtr.* + 3]);
    
    const a = if (modes[0] == IMMEDIATE_MODE) ram[instructionPtr.* + 1] else ram[@intCast(u32, ram[instructionPtr.* + 1])];
    const b = if (modes[1] == IMMEDIATE_MODE) ram[instructionPtr.* + 2] else ram[@intCast(u32, ram[instructionPtr.* + 2])];
    const r = @intCast(u32, ram[instructionPtr.* + 3]);

    ram[r] = if (a == b) 1 else 0;
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