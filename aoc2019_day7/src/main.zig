const std = @import("std");

const IMMEDIATE_MODE = 1;
const POSITION_MODE = 0;
const RAM_SIZE = 1024;
const ExecutionState = enum {
    Running,
    Suspended,
    Terminated,
};

const Computer = struct {
    id: u8,
    executionState: ExecutionState,
    ram: [RAM_SIZE]i32,
    instructionPtr: u32,
    phase: i32,
    input: *Computer,
    output: i32,
    haveReadPhase: bool,
    haveOutputReady: bool,

    pub fn run(self: *Computer) void {
        self.executionState = .Running;
        while(true) {
            if (self.executionState != .Running) break;
            //std.debug.warn("{c} :: inst {} data {} ", self.id, self.instructionPtr, self.ram[self.instructionPtr]);
            switch(extractOpcode(self.ram[self.instructionPtr])) {
                1 => self.add(),
                2 => self.mul(),
                3 => self.in(),
                4 => self.out(),
                5 => self.jmpTrue(),
                6 => self.jmpFalse(),
                7 => self.lessThan(),
                8 => self.equals(),
                99 => self.exit(),
                else => unreachable,
            }
        }
    }

    fn exit(self: *Computer) void {
        //std.debug.warn("exit\n");
        self.executionState = .Terminated;
    }

    fn add(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);

        // std.debug.warn("add {}:{} {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2], 
        //     "P", self.ram[self.instructionPtr + 3]);

        const a = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const b = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];
        const storePosition = @intCast(u32, self.ram[self.instructionPtr + 3]);

        self.ram[storePosition] = a + b;
        //std.debug.warn("put {} in position {}\n", a + b, storePosition);

        self.instructionPtr += 4;
    }

    fn mul(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);

        // std.debug.warn("mul {}:{} {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2], 
        //     "P", self.ram[self.instructionPtr + 3]);

        const a = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const b = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];
        const storePosition = @intCast(u32, self.ram[self.instructionPtr + 3]);

        self.ram[storePosition] = a * b;
        //std.debug.warn("put {} in position {}\n", a * b, storePosition);

        self.instructionPtr += 4;
    }

    fn in(self: *Computer) void {
        // std.debug.warn("in P:{}\n", self.ram[self.instructionPtr + 1]);
        const storePosition =  @intCast(u32, self.ram[self.instructionPtr + 1]);
        
        if (!self.haveReadPhase) {
            self.ram[storePosition] = self.phase;
            //std.debug.warn("put {} in position {}\n", self.phase, storePosition);
            self.haveReadPhase = true;
        } else if (self.input.haveOutputReady) {
            self.ram[storePosition] = self.input.output;
            //std.debug.warn("put {} in position {}\n", self.input.output, storePosition);
            self.input.haveOutputReady = false;
        } else {
            self.executionState = .Suspended;
            return;
        }

        self.instructionPtr += 2;
    }

    fn out(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        // std.debug.warn("out {}:{}\n", if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1]);
        const outValue = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];

        std.debug.warn(" outputting {}\n", outValue);
        self.output = outValue;
        self.haveOutputReady = true;

        self.instructionPtr += 2;
    }

    fn jmpTrue(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        // std.debug.warn("jmpTrue {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2]);

        const condition = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const label = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];

        if (condition != 0) {
            self.instructionPtr = @intCast(u32, label);
            //std.debug.warn("jumped to {}\n", label);
        } else {
            self.instructionPtr += 3;
            //std.debug.warn("did not jump\n");
        }
    }

    fn jmpFalse(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        // std.debug.warn("jmpFalse {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2]);

        const condition = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const label = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];

        if (condition == 0) {
            self.instructionPtr = @intCast(u32, label);
            //std.debug.warn("jumped to {}\n", label);
        } else {
            self.instructionPtr += 3;
            //std.debug.warn("did not jump\n");
        }
    }

    fn lessThan(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        // std.debug.warn("lessThan {}:{} {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2],
        //     "P", self.ram[self.instructionPtr + 3]);
        
        const a = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const b = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];
        const r = @intCast(u32, self.ram[self.instructionPtr + 3]);

        self.ram[r] = if (a < b) 1 else 0;
        //std.debug.warn("put {} in position {}\n", self.ram[r], r);
        self.instructionPtr += 4;
    }

    fn equals(self: *Computer) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        // std.debug.warn("equals {}:{} {}:{} {}:{}\n", 
        //     if (modes[0] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 1], 
        //     if (modes[1] == IMMEDIATE_MODE) "I" else "P", self.ram[self.instructionPtr + 2], 
        //     "P", self.ram[self.instructionPtr + 3]);
        
        const a = if (modes[0] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 1] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 1])];
        const b = if (modes[1] == IMMEDIATE_MODE) self.ram[self.instructionPtr + 2] else self.ram[@intCast(u32, self.ram[self.instructionPtr + 2])];
        const r = @intCast(u32, self.ram[self.instructionPtr + 3]);

        self.ram[r] = if (a == b) 1 else 0;
        //std.debug.warn("put {} in position {}\n", self.ram[r], r);
        self.instructionPtr += 4;
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
};

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    // const file_string = "3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5";
    // const file_string = "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10";

    var iterator = std.mem.tokenize(file_string, ",");

    var data = [_]i32{0} ** RAM_SIZE;
    {
        var i: u32 = 0;
        while (iterator.next()) |token| {
            data[i] = std.fmt.parseInt(i32, token, 10) catch 0;
            i += 1;
        }
    }

    var amplifiers = try allocator.alloc(Computer, 5);
    var permutations = generatePermutations(5, [_]i32 { 5, 6, 7, 8, 9 });
    var maxPermutation = [_]i32 {0,0,0,0,0};
    var maxOutput: i32 = std.math.minInt(i32);

    var two = false;

    for (permutations) |permutation| {
        std.debug.warn(" permutation: {} {} {} {} {}\n", permutation[0], permutation[1], permutation[2], permutation[3], permutation[4]);
        
        {   // set up amplifiers once for each permutation
            var i: u32 = 0;
            while (i < amplifiers.len) : (i += 1) {
                amplifiers[i].id = @intCast(u8, i) + 'A';
                arrayCopy(RAM_SIZE, &data, &amplifiers[i].ram);
                amplifiers[i].instructionPtr = 0;
                amplifiers[i].phase = permutation[i];
                amplifiers[i].output = 0;
                if (i == 0) {
                    amplifiers[i].input = &amplifiers[4];
                } else {
                    amplifiers[i].input = &amplifiers[i - 1];
                }
                amplifiers[i].executionState = .Suspended;
                amplifiers[i].haveReadPhase = false;
                amplifiers[i].haveOutputReady = (i == 4);
            }
        }

        var i: u32 = 0;
        while (true) : ({i += 1; i %= 5;}) {
            if (amplifiers[i].executionState != .Terminated) {
                amplifiers[i].run();
            } else if (i == 4) {
                break;
            }
        }

        if (amplifiers[4].output > maxOutput) {
            maxOutput = amplifiers[4].output;
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

