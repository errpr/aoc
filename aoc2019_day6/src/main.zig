const std = @import("std");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    // const file_string = "COM)BBB\nBBB)CCC\nCCC)DDD\nDDD)EEE\nEEE)FFF\nBBB)GGG\nGGG)HHH\nDDD)III\nEEE)JJJ\nJJJ)KKK\nKKK)LLL";
    // const file_string = "COM)BBB\nBBB)CCC\nCCC)DDD\nHHH)EEE\nEEE)FFF\nBBB)GGG\nGGG)HHH\nDDD)III\nEEE)JJJ\nJJJ)KKK\nKKK)LLL\nKKK)YOU\nIII)SAN";
    
    var tree = std.StringHashMap([]const u8).init(allocator);

    {
        var it = std.mem.separate(file_string, "\n");
        while (it.next()) |line| {
            const parent = line[0..3];
            const child = line[4..7];
            _ = try tree.put(child, parent);
        }
    }

    var it = tree.iterator();
    var total: u64 = 0;
    while (it.next()) |entry| {
        
        // ascend tree for each item, counting the parents and self
        var i: u32 = 0;
        var key = entry.key;

        while (true) : (i += 1) {
            if (std.mem.eql(u8, key, "COM")) {
                break;
            }
            key = tree.get(key).?.value;
        }

        total += i;
    }

    std.debug.warn("total orbits {}\n", total);

    // find the first common node

    var sanNodes = std.StringHashMap(u32).init(allocator);
    {
        var i: u32 = 0;
        var key = tree.get("SAN").?.value;
        while (true) : (i += 1) {
            _ = try sanNodes.put(key, i);
            if (std.mem.eql(u8, key, "COM")) {
                break;
            }

            key = tree.get(key).?.value;
        }
    }

    var i: u32 = 0;
    var key = tree.get("YOU").?.value;
    var result: u32 = 0;
    while (true) : (i += 1) {
        if (sanNodes.contains(key)) {
            std.debug.warn("first common node: {}\n", key);
            result = i + sanNodes.get(key).?.value;
            break;
        }

        key = tree.get(key).?.value;
    }

    std.debug.warn("shortest path: {}\n", result);
}
