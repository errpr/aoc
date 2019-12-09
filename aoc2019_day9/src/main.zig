const std = @import("std");

const RELATIVE_MODE = 2;
const IMMEDIATE_MODE = 1;
const POSITION_MODE = 0;
const RAM_SIZE = 2048;

const ExecutionState = enum {
    Running,
    Suspended,
    Terminated,
};

const Computer = struct {
    id: u8,
    executionState: ExecutionState,
    ram: [RAM_SIZE]i64,
    instructionPtr: u32,
    phase: i32,
    input: *Computer,
    output: i64,
    haveReadPhase: bool,
    haveOutputReady: bool,
    relativeBase: u32,

    pub fn run(self: *Computer) void {
        self.executionState = .Running;
        while(true) {
            if (self.executionState != .Running) break;
            std.debug.warn("{c} :{}: data {} ", self.id, self.instructionPtr, self.ram[self.instructionPtr]);
            switch(extractOpcode(self.ram[self.instructionPtr])) {
                1 => self.add(),
                2 => self.mul(),
                3 => self.in(),
                4 => self.out(),
                5 => self.jmpTrue(),
                6 => self.jmpFalse(),
                7 => self.lessThan(),
                8 => self.equals(),
                9 => self.adjustRelativeBase(),
                99 => self.exit(),
                else => unreachable,
            }
            std.debug.warn("\n");
        }
    }

    fn adjustRelativeBase(self: *Computer) void {
        self.relativeBase = @intCast(u32, @intCast(i64, self.relativeBase) + self.readParam(1));
        self.instructionPtr += 2;
    }

    fn exit(self: *Computer) void {
        self.executionState = .Terminated;
    }

    fn add(self: *Computer) void {
        const a = self.readParam(1);
        const b = self.readParam(2);
        self.writeParam(3, a + b);
        self.instructionPtr += 4;
    }

    fn mul(self: *Computer) void {
        const a = self.readParam(1);
        const b = self.readParam(2);
        self.writeParam(3, a * b);
        self.instructionPtr += 4;
    }

    fn in(self: *Computer) void {
        if (!self.haveReadPhase) {
            self.writeParam(1, self.phase);
            //std.debug.warn("put {} in position {}\n", self.phase, storePosition);
            self.haveReadPhase = true;
        } else if (self.input.haveOutputReady) {
            self.writeParam(1, self.input.output);
            //std.debug.warn("put {} in position {}\n", self.input.output, storePosition);
            self.input.haveOutputReady = false;
        } else {
            self.executionState = .Suspended;
            return;
        }

        self.instructionPtr += 2;
    }

    fn out(self: *Computer) void {
        const outValue = self.readParam(1);

        std.debug.warn(" outputting {}\n", outValue);
        self.output = outValue;
        self.haveOutputReady = true;

        self.instructionPtr += 2;
    }

    fn jmpTrue(self: *Computer) void {
        const condition = self.readParam(1);
        const label = self.readParam(2);

        if (condition != 0) {
            self.instructionPtr = @intCast(u32, label);
        } else {
            self.instructionPtr += 3;
        }
    }

    fn jmpFalse(self: *Computer) void {
        const condition = self.readParam(1);
        const label = self.readParam(2);

        if (condition == 0) {
            self.instructionPtr = @intCast(u32, label);
        } else {
            self.instructionPtr += 3;
        }
    }

    fn lessThan(self: *Computer) void {
        const a = self.readParam(1);
        const b = self.readParam(2);
        self.writeParam(3, if (a < b) 1 else 0);
        self.instructionPtr += 4;
    }

    fn equals(self: *Computer) void {
        const a = self.readParam(1);
        const b = self.readParam(2);
        self.writeParam(3, if (a == b) 1 else 0);
        self.instructionPtr += 4;
    }

    fn readParam(self: *Computer, paramNumber: u32) i64 {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        if (modes[paramNumber - 1] == IMMEDIATE_MODE) {
            const result = self.ram[self.instructionPtr + paramNumber];
            std.debug.warn("i:{} ", result);
            return result;
        } else if (modes[paramNumber - 1] == POSITION_MODE) {
            const result = self.ram[@intCast(u32, self.ram[self.instructionPtr + paramNumber])];
            std.debug.warn("p:{} ", result);
            return result;
        } else if (modes[paramNumber - 1] == RELATIVE_MODE) {
            const result = self.ram[@intCast(u32, @intCast(i64, self.relativeBase) + self.ram[self.instructionPtr + paramNumber])];
            std.debug.warn("r:{} ", result);
            return result;
        }
        
        unreachable;
    }

    fn writeParam(self: *Computer, paramNumber: u32, value: i64) void {
        const modes = extractParameterModes(self.ram[self.instructionPtr]);
        if (modes[paramNumber - 1] == POSITION_MODE) {
            const location = @intCast(u32, self.ram[self.instructionPtr + paramNumber]);
            std.debug.warn("p:{}<-{} ", location, value);
            self.ram[location] = value;
        } else if (modes[paramNumber - 1] == RELATIVE_MODE) {
            const location = @intCast(u32, @intCast(i64, self.relativeBase) + self.ram[self.instructionPtr + paramNumber]);
            std.debug.warn("r:{}<-{} ", location, value);
            self.ram[location] = value;
        } else {
            unreachable;
        }
    }

    fn extractOpcode(instruction: i64) u32 {
        return @intCast(u32, instruction) % 100;
    }

    fn extractParameterModes(instruction: i64) [3]u32 {
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

    fn loadProgram(self: *Computer, string: []const u8) void {
        var iter = std.mem.tokenize(std.mem.trim(u8, string, "\n"), ",");
        var i: u32 = 0;
        while (iter.next()) |token| {
            self.ram[i] = std.fmt.parseInt(i64, token, 10) catch 0;
            i += 1;
        }
    }
};

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const fileString = try std.io.readFileAlloc(allocator, "input.txt");
    // const fileString = "109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99";
    // const fileString = "104,1125899906842624,99";
    // const fileString = "1102,34915192,34915192,7,4,7,99,0";

    var computer: Computer = undefined;
    computer.ram = [1]i64 { 0 } ** RAM_SIZE;
    computer.loadProgram(fileString);
    computer.id = 'A';
    computer.executionState = ExecutionState.Suspended;
    computer.instructionPtr = 0;
    computer.phase = 1;
    computer.output = 0;
    computer.haveReadPhase = false;
    computer.haveOutputReady = false;
    computer.relativeBase = 0;

    computer.run();
    std.debug.warn("final computer output: {}\n", computer.output);
}