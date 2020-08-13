@JS()
library wasmJS;

import "dart:typed_data";

import "package:js/js.dart";

@JS()
external Promise<Response> fetch(String resource);

@JS()
class Response {
    external ByteBuffer arrayBuffer();
}

@JS()
class Promise<T> {}

@JS('Object.keys')
external List<dynamic> objectKeys(Object value);

@JS('Math.clz32')
external int clz32(int value);