import "dart:math";
import "dart:typed_data";

import "bytebuilder.dart";

class LegacyByteBuilder extends ByteBuilder {
    /// Internal buffer.
    final StringBuffer _data = new StringBuffer();
    /// Current working byte, bits are appended to this up to 8, then it is added to the buffer.
    int _currentbyte = 0;
    /// Bit position within the current working byte.
    int _position = 0;

    bool bigEndian = true;

    /// Creates a new ByteBuilder with an empty buffer.
    LegacyByteBuilder();

    /// Appends a single bit to the buffer.
    void appendBit(bool bit) {
        if (bit) {
            if (bigEndian) {
                _currentbyte |= (1 << (7 - _position));
            } else {
                _currentbyte |= (1 << _position);
            }
        }
        _position++;
        if (_position >= 8) {
            _position = 0;
            _data.writeCharCode(_currentbyte);
            _currentbyte = 0;
        }
    }

    /// Appends [length] bits of [bits] to the buffer.
    void appendBits(int bits, int length) {
        for (int i=0; i<length; i++) {
            if (bigEndian) {
                appendBit(bits & (1 << ((length - 1) - i)) > 0);
            } else {
                appendBit(bits & (1 << i) > 0);
            }
        }
    }

    /// Appends 8 bits of [byte] to the buffer.
    void appendByte(int byte) {
        appendBits(byte, 8);
    }

    /// Appends 16 bits of [i] to the buffer.
    void appendShort(int i) {
        appendBits(i, 16);
    }

    /// Appends 32 bits of [i] to the buffer.
    void appendInt32(int i) {
        appendBits(i, 32);
    }

    /// Appends [i] to the buffer using Exponential-Golomb encoding.
    ///
    /// [Wikipedia reference](https://en.wikipedia.org/wiki/Exponential-Golomb_coding)
    void appendExpGolomb(int i) {
        i++;

        final int bits = log(i)~/ln2;

        for (int i=0; i<bits; i++) {
            this.appendBit(false);
        }

        this.appendBits(i, bits+1);
    }

    /// Appends all numbers in [bits] to the buffer as [length] bit long segments.
    void appendAllBits(List<int> bits, int length) {
        for (final int number in bits) {
            this.appendBits(number, length);
        }
    }

    /// Appends all numbers in [bytes] as bytes.
    void appendAllBytes(List<int> bytes) {
        this.appendAllBits(bytes, 8);
    }

    /// Appends all numbers in [numbers] using Exponential-Golomb encoding.
    void appendAllExpGolomb(List<int> numbers) {
        for (final int number in numbers) {
            this.appendExpGolomb(number);
        }
    }

    /// Creates a new [ByteBuffer] containing the data in this ByteBuilder.
    ByteBuffer toBuffer([ByteBuffer? toExtend]) {
        int length = _position > 0 ? _data.length+1 : _data.length;
        int offset = 0;

        ////print(this._data.toString());
        if (toExtend != null) {
            length += toExtend.lengthInBytes;
            offset = toExtend.lengthInBytes;
        }

        final Uint8List list = new Uint8List(length);

        if (toExtend != null) {
            final Uint8List view = new Uint8List.view(toExtend);
            for (int i=0; i<view.length; i++) {
                list[i] = view[i];
            }
        }

        final String data = _data.toString();

        for (int i=0; i<data.length; i++) {
            list[i+offset] = data.codeUnitAt(i);
        }
        if (_position > 0) {
            list[data.length+offset] = _currentbyte;
        }

        return list.buffer;
    }

    /// Convenience function for pretty-printing a [ByteBuffer].
    static void prettyPrintByteBuffer(ByteBuffer buffer) {
        final Uint8List list = new Uint8List.view(buffer);

        final StringBuffer sb = new StringBuffer("Bytes: ${buffer.lengthInBytes} [");

        for (int i=0; i<list.length; i++) {
            sb.write("0x${list[i].toRadixString(16).padLeft(2,"0").toUpperCase()}");
            if (i < list.length-1) {
                sb.write(", ");
            }
        }

        sb.write("]");

        print(sb.toString());
    }
}