const std = @import("std");

fn TwoDimensionalSlice(comptime T: type) type {
    return struct {
        const Self = @This();

        buf: []T,
        w: usize,
        h: usize,

        fn get(self: *Self, x: usize, y: usize) T {
            return self.buf[(y * self.w) + x];
        }

        fn set(self: *Self, x: usize, y: usize, value: T) void {
            self.buf[(y * self.w) + x] = value;
        }

        fn init(self: *Self, allocator: *std.mem.Allocator, width: usize, height: usize) !void {
            self.w = width;
            self.h = height;
            self.buf = try allocator.alloc(T, width * height);
        }

        fn deinit(self: *Self, allocator: *std.mem.Allocator) void {
            allocator.free(self.buf);
        }

        fn debugPrint(self: *Self) void {
            var i: usize = 0;
            while (i < self.h) : (i += 1) {
                var j: usize = 0;
                while (j < self.w) : (j += 1) {
                    if (T == bool) {
                        if (self.get(j, i)) {
                            std.debug.warn("#");
                        } else {
                            std.debug.warn(".");
                        }
                    } else {
                        std.debug.warn("{}", self.get(j, i));
                    }
                }
                std.debug.warn("\n");
            }
        }
    };
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const fileString = try std.io.readFileAlloc(allocator, "input.txt");
    // const fileString = ".#..#\n.....\n#####\n....#\n...##\n";
    // const fileString = "......#.#.\n#..#.#....\n..#######.\n.#.#.###..\n.#..#.....\n..#....#.#\n#..#....#.\n.##.#..###\n##...#..#.\n.#....####\n";

    var width: usize = 0;
    var height: usize = 0;
    {
        var it = std.mem.tokenize(fileString, "\r\n");
        while (it.next()) |token| {
            if (height == 0) width = token.len;
            height += 1;
        }
    }
    
    var asteroids: TwoDimensionalSlice(bool) = undefined;
    try asteroids.init(allocator, width, height);

    var workingAsteroids: TwoDimensionalSlice(bool) = undefined;
    try workingAsteroids.init(allocator, width, height);
    
    var asteroidScore: TwoDimensionalSlice(u32) = undefined;
    try asteroidScore.init(allocator, width, height);
    std.mem.secureZero(u32, asteroidScore.buf);

    {
        var it = std.mem.tokenize(fileString, "\n");
        var i: usize = 0;
        while (it.next()) |token| {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                asteroids.set(i, j, token[j] == '#');
            }
            i += 1;
        }
    }

    asteroids.debugPrint();

    var maxScore: u32 = 0;
    {
        var i: usize = 0;
        while (i < height) : (i += 1) {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                if (asteroids.get(j, i)) {
                    std.mem.copy(bool, workingAsteroids.buf, asteroids.buf);
                    const score = try computeScore(i, j, &workingAsteroids, &asteroidScore);
                    if (score > maxScore) maxScore = score;
                }
            }
        }
    }

    asteroidScore.debugPrint();
    std.debug.warn("maxScore: {}\n", maxScore);
}

fn computeScore(startY: usize, startX: usize, asteroids: *TwoDimensionalSlice(bool), asteroidScore: *TwoDimensionalSlice(u32)) !u32 {
    // std.debug.warn("Beginning asteroid at x:{} y:{}\n", startX, startY);
    var score: u32 = 0;
    const sX = @intCast(isize, startX);
    const sY = @intCast(isize, startY);
    var i: usize = 0;
    var x: isize = 0;
    var y: isize = 0;
    var dx: isize = 0;
    var dy: isize = -1;
    const height = @intCast(isize, asteroids.h);
    const width = @intCast(isize, asteroids.w);
    const t: usize = @intCast(usize, std.math.max(height, width));
    const iMax = t * t * 4;
    while (i < iMax) : (i += 1) {    
        const tX: isize = sX + x;
        const tY: isize = sY + y;
        if (!(x == 0 and y == 0) and tX >= 0 and tX < width and tY >= 0 and tY < height) {
            const iX: usize = @intCast(usize, tX);
            const iY: usize = @intCast(usize, tY);
            if (asteroids.get(iX, iY)) {
                // std.debug.warn("Found asteroid in view at x:{} y:{}\n", iX, iY);
                // asteroids.debugPrint();
                score += 1;
                var g: isize = 0;
                var aX: isize = 0;
                var aY: isize = 0;
                if (x != 0 and y != 0) {
                    g = @intCast(isize, gcd(@intCast(usize, try std.math.absInt(x)), @intCast(usize, try std.math.absInt(y))));
                    // std.debug.warn("got gcd:{}\n", g);
                    aX = @divTrunc(x, g);
                    aY = @divTrunc(y, g);
                } else if (x == 0) {
                    aX = 0;
                    aY = if (y > 0) 1 else -1;
                } else if (y == 0) {
                    aY = 0;
                    aX = if (x > 0) 1 else -1;
                }
                // std.debug.warn("aY:{} aX:{}\n", aY, aX);
                var jX = tX;
                var jY = tY;
                while (jX >= 0 and jX < width and jY >= 0 and jY < height) {
                    const wasThere = asteroids.get(@intCast(usize, jX), @intCast(usize, jY));
                    asteroids.set(@intCast(usize, jX), @intCast(usize, jY), false);
                    if (wasThere) {
                        // std.debug.warn("Occluding asteroid at x:{} y:{}\n", jX, jY);
                        // asteroids.debugPrint();
                    }
                    jX += aX;
                    jY += aY;
                }
            }
        }
        if (x == y or (x < 0 and x == -y) or (x > 0 and x == 1 - y)) {
            const temp = dx;
            dx = -dy;
            dy = temp;
        }
        x += dx;
        y += dy;
    }
    asteroidScore.set(startX, startY, score);
    return score;
}

fn gcd(U: usize, V: usize) usize {
    var u = U;
    var v = V;
    var shift: u6 = 0;
    if (u == 0) return v;
    if (v == 0) return u;

    while (((u | v) & 1) == 0) {
        shift += 1;
        u >>= 1;
        v >>= 1;
    }

    while ((u & 1) == 0) {
        u >>= 1;
    }

    while ((v & 1) == 0) {
        v >>= 1;
    }

    if (u > v) {
        var t = v;
        v = u;
        u = t;
    }

    v -= u;

    while (v != 0) {
        while ((v & 1) == 0) {
            v >>= 1;
        }

        if (u > v) {
            var t = v;
            v = u;
            u = t;
        }

        v -= u;
    }

    return u << shift;
}