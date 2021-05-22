import "dart:typed_data";

abstract class LZString {
    static String compress(String string) => throw UnsupportedError("Stub");
    static String decompress(String compressed) => throw UnsupportedError("Stub");

    static String compressToUTF16(String string) => throw UnsupportedError("Stub");
    static String decompressFromUTF16(String compressed) => throw UnsupportedError("Stub");

    static Uint8List compressToUint8Array(String string) => throw UnsupportedError("Stub");
    static String decompressFromUint8Array(Uint8List compressed) => throw UnsupportedError("Stub");

    static String compressToEncodedURIComponent(String string) => throw UnsupportedError("Stub");
    static String decompressFromEncodedURIComponent(String compressed) => throw UnsupportedError("Stub");
}