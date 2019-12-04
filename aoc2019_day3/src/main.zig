const std = @import("std");

const GRID_SIZE = std.math.maxInt(u16);
const CENTER_POINT: u32 = GRID_SIZE / 2;

const MASK_WIRE_1: u8 = 0b0000001;
const MASK_WIRE_2: u8 = 0b0000010;
const MASK_WIRE_BOTH: u8 = 0b00000011;

const Grid = struct {
    buf: [][GRID_SIZE]u8,
    nearestCollisionDistance: u64,
    minUD: u16,
    minRL: u16,
    maxUD: u16,
    maxRL: u16,

    pub fn visit(self: *Grid, posUD: u16, posRL: u16, mask: u8) void {
        self.buf[posUD][posRL] |= mask;

        if (self.buf[posUD][posRL] == MASK_WIRE_BOTH) {
            const distance = computeManhattanDistanceFromCenter(posUD, posRL);
            if (distance < self.nearestCollisionDistance) {
                self.nearestCollisionDistance = distance;
            }
        }

        if (posUD < self.minUD) {
            self.minUD = posUD;
        }
        if (posUD > self.maxUD) {
            self.maxUD = posUD;
        }
        if (posRL < self.minRL) {
            self.minRL = posRL;
        }
        if (posRL > self.maxRL) {
            self.maxRL = posRL;
        }
    }

    pub fn printGrid(self: *Grid, stream: *std.fs.File.OutStream.Stream) !void {
        var i: u32 = self.minUD;
        while (i <= self.maxUD) : (i += 1) {
            var j: u32 = self.minRL;
            while (j <= self.maxRL) : (j += 1) {
                const char = self.buf[i][j];
                if (i == CENTER_POINT and j == CENTER_POINT) {
                    try stream.print("#");
                } else if (char == 0) {
                    try stream.print(" ");
                } else if (char == MASK_WIRE_1 or char == MASK_WIRE_2) {
                    try stream.print(".");
                } else {
                    try stream.print("X");
                }
            }
            try stream.print("\n");
        }
    }
};

const Wire = struct {
    posRL: u16,
    posUD: u16,
    mask: u8,

    pub fn performMove(self: *Wire, grid: *Grid, distance: u32, direction: u8) void {
        var i: u32 = 0;
        switch(direction) {
            'R' => {
                while (i < distance) : (i += 1) {
                    self.posRL += 1;
                    grid.visit(self.posUD, self.posRL, self.mask);
                }
            },
            'L' => {
                while (i < distance) : (i += 1) {
                    self.posRL -= 1;
                    grid.visit(self.posUD, self.posRL, self.mask);
                }
            },
            'U' => {
                while (i < distance) : (i += 1) {
                    self.posUD -= 1;
                    grid.visit(self.posUD, self.posRL, self.mask);
                }
            },
            'D' => {
                while (i < distance) : (i += 1) {
                    self.posUD += 1;
                    grid.visit(self.posUD, self.posRL, self.mask);
                }
            },
            else => unreachable,
        }
    }
};

fn computeManhattanDistanceFromCenter(ud: u16, rl: u16) u64 {
    var x: u32 = 0;
    if (ud > CENTER_POINT) {
        x = ud - CENTER_POINT;
    } else {
        x = CENTER_POINT - ud;
    }

    var y: u32 = 0;
    if (rl > CENTER_POINT) {
        y = rl - CENTER_POINT;
    } else {
        y = CENTER_POINT - rl;
    }

    return x + y;
}

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    const input = try std.io.readFileAlloc(allocator, "input.txt");
    // const input = "R8,U5,L5,D3\nU7,R6,D4,L4\n";
    // const input = "R75,D30,R83,U83,L12,D49,R71,U7,L72\nU62,R66,U55,R34,D71,R55,D58,R83\n";
    // const input = "R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51\nU98,R91,D20,R16,D67,R40,U7,R15,U6,R7\n";

    var wire = Wire {
        .posRL = CENTER_POINT,
        .posUD = CENTER_POINT,
        .mask = MASK_WIRE_1,
    };

    var grid = Grid {
        .buf = try allocator.alloc([GRID_SIZE]u8, GRID_SIZE),
        .nearestCollisionDistance = std.math.maxInt(u64),
        .minUD = CENTER_POINT,
        .maxUD = CENTER_POINT,
        .minRL = CENTER_POINT,
        .maxRL = CENTER_POINT,
    };

    {
        // zeroing the grid takes forever where is my calloc
        var i: u32 = 0;
        while (i < GRID_SIZE) : (i += 1) {
            var j: u32 = 0;
            while (j < GRID_SIZE) : (j += 1) {
                grid.buf[i][j] = 0;
            }
        }
    }

    {
        var i: u32 = 0;
        var distanceStartIndex: u32 = 0;
        var currentDirection: u8 = 'R';
        
        while(i < input.len) : (i += 1) {
            switch(input[i]) {
                '1','2','3','4','5','6','7','8','9','0' => {
                    if (distanceStartIndex == 0) {
                        distanceStartIndex = i;
                    }
                },
                'R','L','U','D' => {
                    currentDirection = input[i];
                },
                ',' => {
                    const distance = try std.fmt.parseInt(u32, input[distanceStartIndex..i], 10);
                    wire.performMove(&grid, distance, currentDirection);
                    distanceStartIndex = 0;
                },
                '\n' => {
                    const distance = try std.fmt.parseInt(u32, input[distanceStartIndex..i], 10);
                    wire.performMove(&grid, distance, currentDirection);
                    distanceStartIndex = 0;
                    wire.posRL = CENTER_POINT;
                    wire.posUD = CENTER_POINT;
                    wire.mask = MASK_WIRE_2;
                },
                else => unreachable,
            }
        }
    }
    
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("distance: {}\n", grid.nearestCollisionDistance);
    //try grid.printGrid(stdout);
}
