library lzw;

abstract class LZW {
    /// Compresses pixels using LZW.
    static List<int> compress(List<int> pixels, int colorBits) {
        final LZWCodeBook book = new LZWCodeBook(colorBits);
        final LZWCodeBuffer buf = new LZWCodeBuffer(book);

        buf.add(book.clearCode);
        if (pixels.isEmpty) {
            buf.add(book.endCode);
            return buf.finish();
        }

        int code = pixels[0];
        for (final int px in pixels.sublist(1)) {
            final int? newCode = book.codeAfterAppend(code, px);
            if (newCode == null) {
                buf.add(code);
                book.define(code, px);
                code = px;
            } else {
                code = newCode;
            }
        }
        buf.add(code);
        buf.add(book.endCode);
        return buf.finish();
    }

    // The highest code that can be defined in the CodeBook.
    static const int maxCode = (1 << 12) - 1;
}

/// A CodeBook contains codes defined during LZW compression. It's a mapping from a string
/// of pixels to the code that represents it. The codes are stored in a trie which is
/// represented as a map. Codes may be up to 12 bits. The size of the codebook is always
/// the minimum power of 2 needed to represent all the codes and automatically increases
/// as new codes are defined.
class LZWCodeBook {
    late int colorBits;
    // The "clear" code which resets the table.
    late int clearCode;
    // The "end of data" code.
    late int endCode;

    // A mapping from (c1, pixel) -> c2 that returns the new code for the pixel string
    // formed by appending a pixel to the end of c1's pixel string. (In addition, the
    // codes for single pixels are stored in the map with c1 set to 0.)
    // The key is encoded by shifting c1 to the left by eight bits and adding the pixel,
    // forming a 20-bit number.
    late Map<int, int> _codeAfterAppend;

    // Codes from this value and above are not yet defined.
    late int nextUnused;

    // The number of bits required to represent every code.
    late int bitsPerCode;

    // The current size of the codebook.
    late int size;

    LZWCodeBook(this.colorBits) {
        if (colorBits < 2) {
            colorBits = 2;
        }
        assert(colorBits <= 8);
        clearCode = 1 << colorBits;
        endCode = clearCode + 1;
        clear();
    }

    void clear() {
        _codeAfterAppend = <int, int>{};
        nextUnused = endCode + 1;
        bitsPerCode = colorBits + 1;
        size = 1 << bitsPerCode;
    }

    /// Returns the new code after appending a pixel to the pixel string represented by the previous code,
    /// or null if the code isn't in the table.
    int? codeAfterAppend(int code, int pixelIndex) {
        return _codeAfterAppend[(code << 8) | pixelIndex];
    }

    /// Defines a new code to be the pixel string of a previous code with one pixel appended.
    /// Returns true if defined, or false if there's no more room in the table.
    bool define(int code, int pixelIndex) {
        if (nextUnused == LZW.maxCode) {
            return false;
        }
        _codeAfterAppend[(code << 8) | pixelIndex] = nextUnused++;
        if (nextUnused > size) {
            bitsPerCode++;
            size = 1 << bitsPerCode;
        }
        return true;
    }
}

/// Writes a sequence of integers using a variable number of bits, for LZW compression.
class LZWCodeBuffer {
    final LZWCodeBook book;
    final List<int> finishedBytes = <int>[];
    // A buffer containing bits not yet added to finishedBytes.
    int buf = 0;
    // Number of bits in the buffer.
    int bits = 0;

    LZWCodeBuffer(this.book);

    void add(int code) {
        assert(code >= 0 && code < book.size);
        buf |= (code << bits);
        bits += book.bitsPerCode;
        while (bits >= 8) {
            finishedBytes.add(buf & 0xFF);
            buf = buf >> 8;
            bits -= 8;
        }
    }

    List<int> finish() {
        // Add the remaining bits. (Unused bits are set to zero.)
        if (bits > 0) {
            finishedBytes.add(buf);
        }

        // The final result starts withe the number of color bits.
        final List<int> dest = <int>[];
        dest.add(book.colorBits);

        // Divide it up into blocks with a size in front of each block.
        final int len = finishedBytes.length;
        for (int i = 0; i < len;) {
            if (len - i >= 255) {
                dest.add(255);
                dest.addAll(finishedBytes.sublist(i, i + 255));
                i += 255;
            } else {
                dest.add(len - i);
                dest.addAll(finishedBytes.sublist(i, len));
                i = len;
            }
        }
        dest.add(0);
        return dest;
    }
}