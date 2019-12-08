const std = @import("std");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const fileString = try std.io.readFileAlloc(allocator, "input.txt");
    // const fileString = "0222112222120000";

    const height = 6;
    const width = 25;
    const layerCount: u32 = @intCast(u32, fileString.len / (height * width));
    
    //var layers = allocator.alloc([height][width]u8, layerCount);
    var flattened = [1][width]u8 { [1]u8 { 2 } ** width } ** height;
    {
        var stringIndex: u32 = 0;
        var layerIndex: u32 = 0;
        while (layerIndex < layerCount) : (layerIndex += 1) {
            var heightIndex: u32 = 0;
            while (heightIndex < height) : (heightIndex += 1) {
                var widthIndex: u32 = 0;
                while (widthIndex < width) : (widthIndex += 1) {
                    //std.debug.warn("layer: {} height: {} width: {} stringIndex: {}\n", layerIndex, heightIndex, widthIndex, stringIndex);
                    const digit = fileString[stringIndex] - '0';
                    stringIndex += 1;

                    if (flattened[heightIndex][widthIndex] == 2) {
                        flattened[heightIndex][widthIndex] = digit;
                    }
                }
            }
        }
    }

    var i: u32 = 0;
    while (i < height) : (i += 1) {
        var j: u32 = 0;
        while (j < width) : (j += 1) {
            std.debug.warn("{}", flattened[i][j]);
        }
        std.debug.warn("\n");
    }
}
