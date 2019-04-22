import "dart:typed_data";

import "package:CommonLib/Compression.dart";
import "package:test/test.dart";

void main() {
    group("ByteBuilder", ()
    {
        setUp(() {

        });

        test("Big Endian", () {
            final ByteBuilder builder = new ByteBuilder();

            builder.appendShort(100);

            final ByteBuffer buffer = builder.toBuffer();
            final Uint8List bytes = buffer.asUint8List();

            expect(bytes, equals(<int>[0x00,0x64]));
        });

        test("Little Endian", () {
            final ByteBuilder builder = new ByteBuilder()..bigEndian=false;

            builder.appendShort(100);

            final ByteBuffer buffer = builder.toBuffer();
            final Uint8List bytes = buffer.asUint8List();

            expect(bytes, equals(<int>[0x64,0x00]));
        });
    });
}