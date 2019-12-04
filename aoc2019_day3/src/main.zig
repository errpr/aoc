const std = @import("std");

const GRID_SIZE = 30000;
const CENTER_POINT: u32 = GRID_SIZE / 2;

const Grid = struct {
    nearestCollisionDistance: u64,
    fewestStepsToCollision: u64,

    buf: [][GRID_SIZE]u32,

    pub fn visit(self: *Grid, wire: *Wire) void {
        if (wire.id == 1) {
            if (self.buf[wire.posUD][wire.posRL] != 0) {
                const distance = computeManhattanDistanceFromCenter(wire.posUD, wire.posRL);
                if (distance < self.nearestCollisionDistance) {
                    self.nearestCollisionDistance = distance;
                }

                const steps = self.buf[wire.posUD][wire.posRL] + wire.stepsTaken;
                if (steps < self.fewestStepsToCollision) {
                    self.fewestStepsToCollision = steps;
                }
            }
        } else {
            self.buf[wire.posUD][wire.posRL] = wire.stepsTaken;
        }
    }
};

const Wire = struct {
    posRL: u16,
    posUD: u16,
    id: u8,
    stepsTaken: u32,

    pub fn performMove(self: *Wire, grid: *Grid, distance: u32, direction: u8) void {
        var i: u32 = 0;
        switch(direction) {
            'R' => {
                while (i < distance) : (i += 1) {
                    self.posRL += 1;
                    self.stepsTaken += 1;
                    grid.visit(self);
                }
            },
            'L' => {
                while (i < distance) : (i += 1) {
                    self.posRL -= 1;
                    self.stepsTaken += 1;
                    grid.visit(self);
                }
            },
            'U' => {
                while (i < distance) : (i += 1) {
                    self.posUD -= 1;
                    self.stepsTaken += 1;
                    grid.visit(self);
                }
            },
            'D' => {
                while (i < distance) : (i += 1) {
                    self.posUD += 1;
                    self.stepsTaken += 1;
                    grid.visit(self);
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
        .id = 0,
        .stepsTaken = 0,
    };

    var grid = Grid {
        .buf = try allocator.alloc([GRID_SIZE]u32, GRID_SIZE),
        .nearestCollisionDistance = std.math.maxInt(u64),
        .fewestStepsToCollision = std.math.maxInt(u32),
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
                    wire.id = 1;
                    wire.stepsTaken = 0;
                },
                else => unreachable,
            }
        }
    }
    
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("distance: {}\n", grid.nearestCollisionDistance);
    try stdout.print("fewest steps: {}\n", grid.fewestStepsToCollision);
}
