@JS("WebAssembly")
library WebAssembly;

import "dart:typed_data";

import "package:js/js.dart";

import "bindings.dart";

@JS()
class Module {
    external Module(ByteBuffer bufferSource);
}

@JS("Module")
external Function get type_Module;

@JS()
class Instance {
    external Instance(Module module, [dynamic importObject]);

    external Object get exports;
}

@JS()
class Memory {
    external ByteBuffer get buffer;
}

@JS()
class Table {

}

@JS()
class Global {
    external num get value;
}

@JS()
external Promise<ResultObject> instantiate(ByteBuffer bufferSource, [dynamic imports]);

@JS()
external Promise<ResultObject> instantiateStreaming(dynamic source, [dynamic imports]);

@JS()
external Promise<Module> compile(ByteBuffer bufferSource);

@JS()
external Promise<Module> compileStreaming(dynamic source);

@JS()
@anonymous
abstract class ResultObject {
    external Module get module;
    external Instance get instance;
}