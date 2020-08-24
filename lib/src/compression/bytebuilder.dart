import 'dart:math';
import 'dart:typed_data';

/// Builds a compacted [ByteBuffer] of data with syntax similar to [StringBuffer].
class ByteBuilder {
	static const int _bufferBlockSize = 0x8000; // 32k

	/// Internal buffer.
	Uint8List _buffer;
	/// Internal buffer's current position
	int _bufferLength;
	/// Current working byte, bits are appended to this up to 8, then it is added to the buffer.
	int _currentbyte = 0;
	/// Bit position within the current working byte.
	int _position = 0;

	bool bigEndian = true;

	/// Creates a new ByteBuilder with an empty buffer.
	ByteBuilder({int length = _bufferBlockSize, bool this.bigEndian = true}) : super() {
		this._buffer = new Uint8List(length);
		this._bufferLength = 0;
	}

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
			_position = 0; // reset bit position
			_buffer[_bufferLength] = _currentbyte; // put value into buffer
			_bufferLength++; // increment buffer length
			if (_bufferLength >= _buffer.length) { // extend buffer if necessary
				_extend();
			}
			_currentbyte = 0; // reset current bit buffer
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
		_extend(targetLength: _buffer.length + ((bits.length * length) ~/ 8));
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
		_extend(targetLength: _buffer.length + numbers.length);
		for (final int number in numbers) {
			this.appendExpGolomb(number);
		}
	}

	/// Creates a new [ByteBuffer] containing the data in this ByteBuilder.
	ByteBuffer toBuffer([ByteBuffer toExtend]) {
		Uint8List out;
		int outLength = _position > 0 ? _bufferLength + 1 : _bufferLength;
		int start = 0;
		if (toExtend != null) {
			outLength += toExtend.lengthInBytes;
			start = toExtend.lengthInBytes;
		}

		out = new Uint8List(outLength);
		out.setRange(start, out.length + start, _buffer);

		if (toExtend != null) {
			final Uint8List view = toExtend.asUint8List();
			out.setAll(0, view);
		}

		if (_position > 0) {
			out[out.length] = _currentbyte;
		}

		return out.buffer;
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

	/// Extend the internal buffer to accommodate a target length
	void _extend({int targetLength}) {
		targetLength ??= _bufferLength + _bufferBlockSize;
		if (targetLength <= _buffer.length) { return; }
		int newLength = _buffer.length + _bufferBlockSize;
		while (newLength < targetLength) {
			newLength += _bufferBlockSize;
		}

		final Uint8List newBuffer = new Uint8List(newLength);
		newBuffer.setRange(0, _buffer.length, _buffer);
		_buffer = newBuffer;
	}
}

/// Reads a [ByteBuffer] as a stream of bits.
class ByteReader {
	/// Source buffer.
	ByteData _bytes;
	/// Current bit position within the buffer.
	int _position = 0;

	/// Creates a new ByteReader reading from [bytes]. The start position will be offset by [offset] bytes.
	ByteReader(ByteBuffer bytes, [int offset = 0]) {
		this._bytes = bytes.asByteData(offset);
	}

	/// Internal method for reading a bit at a specific position. Use read for getting single bits from the buffer instead.
	bool _read(int position) {
		final int bytepos = (position / 8.0).floor();
		final int bitpos = 7 - (position % 8);

		final int byte = _bytes.getUint8(bytepos);

		return byte & (1 << bitpos) > 0;
	}

	/// Reads the next bit from the buffer.
	bool readBit() {
		final bool val = this._read(this._position);
		_position++;
		return val;
	}

	/// Reads the next [bitcount] bits from the buffer.
	int readBits(int bitcount) {
		if (bitcount > 32) {
			throw new ArgumentError.value(bitcount,"bitcount may not exceed 32");
		}
		int val = 0;

		for (int i=0; i<bitcount; i++) {
			if (readBit()) {
				val |= (1 << ((bitcount-1)-i));
			}
		}

		return val;
	}

	/// Reads the next 8 bits from the buffer.
	int readByte() {
		return readBits(8);
	}

	/// Reads the next [byteCount] bytes to a List.
	Uint8List readBytes(int byteCount) {
		final Uint8List output = new Uint8List(byteCount);

		for (int i=0; i<byteCount; i++) {
			output[i] = readByte();
		}

		return output;
	}

	/// Reads the next 16 bits from the buffer.
	int readShort() {
		return readBits(16);
	}

	/// Reads the next 32 bits from the buffer.
	int readInt32() {
		return readBits(32);
	}

	/// Reads a number encoded with Exponential-Golomb encoding from the buffer.
	///
	/// The bit length read depends upon the encoded number.
	///
	/// [Wikipedia reference](https://en.wikipedia.org/wiki/Exponential-Golomb_coding)
	int readExpGolomb() {
		int bits = 0;

		while (true) {
			if (this.readBit()) {
				this._position--;
				break;
			} else {
				bits++;
			}
		}

		return (this.readBits(bits+1))-1;
	}
}