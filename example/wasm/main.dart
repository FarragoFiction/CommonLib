import "dart:async";
import "dart:html";
import "dart:typed_data";

import "package:CommonLib/WebAssembly.dart" as W;

Element output = querySelector('#output');
Future<void> main() async {
    print("wasm test!");

    final W.Program module = await W.WasmLoader.instantiate(window.fetch("recolour.wasm"));
    print(module.exports);
    print(module.exports["add"](1,2));

    final List<int> testNumbers = <int>[1,2,3,4,5,6,7,8,9];
    final W.Exports e = module.exports;

    final int arrayPtr = e.retain(e.allocArray(e.global("Int32Array_ID"), testNumbers));
    final int resultPointer = e["test"](arrayPtr);
    final Int32List result = e.getInt32List(resultPointer);
    e.release(arrayPtr);
    e.release(resultPointer);

    print(result);
}
