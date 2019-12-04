const std = @import("std");

pub fn main() anyerror!void {
    const rangeStart = 367479;
    const rangeEnd   = 893698;

    var i: u32 = rangeStart;
    var array = [_]u8{ '0','0','0','0','0','0' };
    var string = array[0..array.len];
    var passwordCount: u32 = 0;
    while (i < rangeEnd) : (i += 1) {
        _ = try std.fmt.bufPrint(string, "{}", i);

        var failed = false;
        var foundDouble = false;
        var foundDigit: u8 = 0;
        var ignore: u8 = 0;

        var j: u32 = 1;
        while (j < string.len) : (j += 1) {
            // test ascending
            if (string[j] < string[j - 1]) {
                failed = true;
                break;
            }

            // test double
            if (string[j] == string[j - 1] and string[j] != ignore) {
                if (foundDouble) {
                    // we already have a double
                    if (foundDigit == string[j]) { 
                        // but our double is part of a larger group
                        foundDouble = false;
                        ignore = string[j];
                    }
                } else {
                    foundDouble = true;
                    foundDigit = string[j];
                }
            }
        }
        

        if (failed or !foundDouble) continue;

        std.debug.warn("{}\n", i);
        passwordCount += 1;
    }

    std.debug.warn("password count: {}\n", passwordCount);
}
