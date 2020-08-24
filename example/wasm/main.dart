import "dart:async";
import "dart:html";
import 'dart:math';
import "dart:typed_data";

import "package:CommonLib/Compression.dart";
import "package:CommonLib/Utility.dart";
import "package:CommonLib/WebAssembly.dart" as W;

Element output = querySelector('#output');
Future<void> main() async {
    //wasmTest();
    builderTest();
}

Future<void> wasmTest() async {
    print("wasm test!");

    final W.Program module = await W.WasmLoader.instantiate(window.fetch("recolour.wasm"));
    print(module.exports);
    print(module.exports["add"](1,2));

    //final List<int> testNumbers = <int>[1,2,3,4,5,6,7,8,9];
    final List<int> testNumbers = new List<int>.generate(200000, (int i) => i+1);
    final W.Exports e = module.exports;

    final int arrayPtr = e.retain(e.allocArray(e.global("Uint32Array_ID"), testNumbers));
    final int resultPointer = e["test"](arrayPtr);
    final Uint32List result = e.getUint32List(resultPointer);
    e.release(arrayPtr);
    e.release(resultPointer);

    print(result);
}

Future<void> builderTest() async {

    const int iterations = 1;

    final Random rand = new Random(1);

    final List<int> bytes1 = new List<int>.generate(200000, (int i) => rand.nextInt(256));
    final List<int> bytes2 = new List<int>.generate(1000, (int i) => rand.nextInt(256));
    final List<int> bytes3 = new List<int>.generate(1000, (int i) => rand.nextInt(256));

    final List<int> test = new List<int>.filled(1632, 1);

    void testString() {
        final ByteBuilder builder = new LegacyByteBuilder();
        /*builder.appendBits(0x8, 4);
        builder.appendAllBytes(bytes1);
        builder.appendAllBytes(bytes2);
        builder.appendAllBytes(bytes3);*/
        for (int i=0; i<720; i++) {
            builder.appendByte(1);
            builder.appendAllBytes(test);
        }

        final ByteBuffer out = builder.toBuffer();
    }

    void testBuffer() {
        final ByteBuilder builder = new ByteBuilder();//length: (408+1)*720*(4+1));
        /*builder.appendBits(0x8, 4);
        builder.appendAllBytes(bytes1);
        builder.appendAllBytes(bytes2);
        builder.appendAllBytes(bytes3);*/
        for (int i=0; i<720; i++) {
            builder.appendByte(1);
            builder.appendAllBytes(test);
        }
        final ByteBuffer out = builder.toBuffer();
    }

    runTestSync("string", testString, iterations);
    runTestSync("buffer", testBuffer, iterations);
    runTestSync("string", testString, iterations);
    runTestSync("buffer", testBuffer, iterations);
    runTestSync("string", testString, iterations);
    runTestSync("buffer", testBuffer, iterations);
    runTestSync("string", testString, iterations);
    runTestSync("buffer", testBuffer, iterations);
    runTestSync("string", testString, iterations);
    runTestSync("buffer", testBuffer, iterations);
}