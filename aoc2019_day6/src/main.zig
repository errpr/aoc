const std = @import("std");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    const file_string = try std.io.readFileAlloc(allocator, "input.txt");
    // const file_string = "COM)BBB\nBBB)CCC\nCCC)DDD\nDDD)EEE\nEEE)FFF\nBBB)GGG\nGGG)HHH\nDDD)III\nEEE)JJJ\nJJJ)KKK\nKKK)LLL";
    
    var map = std.StringHashMap([]const u8).init(allocator);

    {
        var it = std.mem.separate(file_string, "\n");
        while (it.next()) |line| {
            const parent = line[0..3];
            const child = line[4..7];
            _ = try map.put(child, parent);
        }
    }

    var it = map.iterator();
    var total: u64 = 0;
    while (it.next()) |entry| {
        std.debug.warn("entry k: {} v: {}\n", entry.key, entry.value);
        
        // ascend tree for each item, counting the parents and self
        var i: u32 = 0;
        var key = entry.key;

        while (true) : (i += 1) {
            if (std.mem.eql(u8, key, "COM")) {
                break;
            }
            key = map.get(key).?.value;
        }

        total += i;
    }

    std.debug.warn("{}", total);
}
