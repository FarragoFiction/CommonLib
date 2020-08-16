@JS()
library WASM;

import "dart:async";
import "dart:collection";
import "dart:html";
import "dart:js" as js;
import "dart:math" as Math;
import "dart:typed_data";

import "package:js/js.dart";
import "package:js/js_util.dart";

import "bindings.dart";
import "webassembly.dart" as WebAssembly;

abstract class WasmLoader {
    // Runtime header offsets
    static const int ID_OFFSET = -8;
    static const int SIZE_OFFSET = -4;

    // Runtime ids
    static const int ARRAYBUFFER_ID = 0;
    static const int STRING_ID = 1;

    // Runtime type information
    static const int ARRAYBUFFERVIEW = 1 << 0;
    static const int ARRAY = 1 << 1;
    static const int STATICARRAY = 1 << 2;
    static const int VAL_ALIGN_OFFSET = 6;
    static const int VAL_SIGNED = 1 << 11;
    static const int VAL_FLOAT = 1 << 12;
    static const int VAL_MANAGED = 1 << 14;

    // Array(BufferView) layout
    static const int ARRAYBUFFERVIEW_BUFFER_OFFSET = 0;
    static const int ARRAYBUFFERVIEW_DATASTART_OFFSET = 4;
    static const int ARRAYBUFFERVIEW_DATALENGTH_OFFSET = 8;
    static const int ARRAYBUFFERVIEW_SIZE = 12;
    static const int ARRAY_LENGTH_OFFSET = 12;
    static const int ARRAY_SIZE = 16;

    //const BIGINT = typeof BigUint64Array !== "undefined";
    //const THIS = Symbol();
    static const int CHUNKSIZE = 1024;

    /// Gets a string from an U32 and an U16 view on a memory.
    static String getStringImpl(ByteBuffer buffer, int ptr) {
        final Uint32List U32 = buffer.asUint32List();
        final Uint16List U16 = buffer.asUint16List();

        int length = U32[ptr + SIZE_OFFSET >> 2] >> 1;
        int offset = ptr >> 1;

        if (length <= CHUNKSIZE) {
            return String.fromCharCodes(U16.sublist(offset, offset + length));
        }

        final StringBuffer parts = new StringBuffer();
        do {
            final int last = U16[offset + CHUNKSIZE - 1];
            final int size = last >= 0xD800 && last <= 0xDC00 ? CHUNKSIZE - 1 : CHUNKSIZE;
            parts.write(String.fromCharCodes(U16.sublist(offset, offset += size)));
            length -= size;
        } while (length > CHUNKSIZE);

        parts.write(String.fromCharCodes(U16.sublist(offset, offset + length)));
        return parts.toString();
    }

    /// Prepares the base module prior to instantiation.
    static Map<String,dynamic> preInstantiate(Map<String, dynamic> imports) {
        final Map<String,dynamic> extendedExports = <String,dynamic>{};

        String getString(WebAssembly.Memory memory, int ptr) {
            if (memory == null) { return "<yet unknown>"; }
            return getStringImpl(memory.buffer, ptr);
        }

        // add common imports used by stdlib for convenience
        Map<String,dynamic> env;
        if (imports.containsKey("env")) {
            env = imports["env"];
        } else {
            env = <String,dynamic>{};
            imports["env"] = env;
        }

        if (!env.containsKey("abort")) {
            void abort(int msg, int file, int line, int colm) {
                final WebAssembly.Memory memory = extendedExports.containsKey("memory") ? extendedExports["memory"] : env["memory"];
                throw Exception("abort: ${getString(memory, msg)} at ${getString(memory, file)}:$line:$colm");
            }
            env["abort"] = allowInterop(abort);
        }

        if (!env.containsKey("trace")) {
            void trace(int msg, int n, List<dynamic> args) {
                final WebAssembly.Memory memory = extendedExports.containsKey("memory") ? extendedExports["memory"] : env["memory"];
                print("trace: ${getString(memory, msg)}${n != null ? " ":""}${args.getRange(0, n).join(",")}");
            }
            env["trace"] = allowInterop(trace);
        }

        if (!env.containsKey("seed")) {
            env["seed"] = js.context["Date.now"];
        }
        if (!env.containsKey("Math")) {
            imports["Math"] = js.context["Math"];
        }
        if (!env.containsKey("Date")) {
            imports["Date"] = js.context["Date"];
        }

        return extendedExports;
    }

    /// Prepares the final module once instantiation is complete.
    static Map<String,dynamic> postInstantiate(Map<String,dynamic> extendedExports, WebAssembly.Instance instance) {
        final Map<String,dynamic> exports = <String,dynamic>{};
        for(final String key in objectKeys(instance.exports)) {
            final Object value = getProperty(instance.exports, key);
            exports[key] = value;
        }
        final WebAssembly.Memory memory = exports["memory"];
        final WebAssembly.Table table = exports["table"];
        final Function alloc = exports["__alloc"];
        final Function retain = exports["__retain"];
        final int rttiBase = exports.containsKey("__rtti_base") ? exports["__rtti_base"].value : ~0;

        /// Gets the runtime type info for the given id.
        int getInfo(int id) {
            final Uint32List U32 = memory.buffer.asUint32List();
            final int count = U32[rttiBase >> 2];
            if (id >= count) {
                throw Exception("Invalid id: $id");
            }
            return U32[(rttiBase + 4 >> 2) + id * 2];
        }

        /// Gets and validate runtime type info for the given id for array like objects
        int getArrayInfo(int id) {
            final int info = getInfo(id);
            if ((info & (ARRAYBUFFERVIEW | ARRAY | STATICARRAY)) == 0) {
                throw Exception("Not an array: $id, flags=$info");
            }
            return info;
        }

        /// Gets the runtime base id for the given id.
        int getBase(int id) {
            final Uint32List U32 = memory.buffer.asUint32List();
            final int count = U32[rttiBase >> 2];
            if (id >= count) {
                throw Exception("Invalid id: $id");
            }
            return U32[(rttiBase + 4 >> 2) + id * 2 + 1];
        }

        /// Gets the runtime alignment of a collection's values.
        int getValueAlign(int info) {
            return 31 - clz32((info >> VAL_ALIGN_OFFSET) & 31);
        }

        /// Allocates a new string in the module's memory and returns its retained pointer.
        int __allocString(String string) {
            final Uint16List U16 = memory.buffer.asUint16List();
            final int length = string.length;
            final int ptr = alloc(length << 1, STRING_ID);
            final int p = ptr >> 1;
            for (int i=0; i < length; ++i) {
                U16[p + i] = string.codeUnitAt(i);
            }
            return ptr;
        }
        extendedExports["__allocString"] = allowInterop(__allocString);

        /// Reads a string from the module's memory by its pointer.
        String __getString(int ptr) {
            final Uint32List U32 = memory.buffer.asUint32List();
            final int id = U32[ptr + ID_OFFSET >> 2];
            if (id != STRING_ID) {
                throw Exception("Not a string: $ptr");
            }
            return getStringImpl(memory.buffer, ptr);
        }
        extendedExports["__getString"] = allowInterop(__getString);

        /// Gets the view matching the specified alignment, signedness and floatness.
        List<num> getView(int alignLog2, bool signed, bool isFloat) {
            final ByteBuffer buffer = memory.buffer;
            if (isFloat) {
                switch(alignLog2) {
                    case 2: return buffer.asFloat32List();
                    case 3: return buffer.asFloat64List();
                }
            } else {
                switch(alignLog2) {
                    case 0: return signed ? buffer.asInt8List() : buffer.asUint8List();
                    case 1: return signed ? buffer.asInt16List() : buffer.asUint16List();
                    case 2: return signed ? buffer.asInt32List() : buffer.asUint32List();
                    case 3: return signed ? buffer.asInt64List() : buffer.asUint64List();
                }
            }
            throw Exception("Unsupported alignment: $alignLog2");
        }

        /// Allocates a new array in the module's memory and returns its retained pointer.
        int __allocArray(int id, List<num> values) {
            final int info = getArrayInfo(id);
            final int align = getValueAlign(info);
            final int length = values.length;
            final int buf = alloc(length << align, info & STATICARRAY != 0 ? id : ARRAYBUFFER_ID );

            int result;
            if (info & STATICARRAY != 0) {
                result = buf;
            } else {
                final int arr = alloc(info & ARRAY != 0 ? ARRAY_SIZE : ARRAYBUFFERVIEW_SIZE, id);
                final Uint32List U32 = memory.buffer.asUint32List();
                U32[arr + ARRAYBUFFERVIEW_BUFFER_OFFSET >> 2] = retain(buf);
                U32[arr + ARRAYBUFFERVIEW_DATASTART_OFFSET >> 2] = buf;
                U32[arr + ARRAYBUFFERVIEW_DATALENGTH_OFFSET >> 2] = length << align;
                if (info & ARRAY != 0) {
                    U32[arr + ARRAY_LENGTH_OFFSET >> 2] = length;
                }
                result = arr;
            }
            final List<num> view = getView(align, info & VAL_SIGNED != 0, info & VAL_FLOAT != 0);
            if (info & VAL_MANAGED != 0) {
                for (int i = 0; i<length; ++i) {
                    view[(buf >> align) + i] = retain(values[i]);
                }
            } else {
                view.setAll(buf >> align, values);
            }
            return result;
        }
        extendedExports["__allocArray"] = allowInterop(__allocArray);

        /// Gets a live view on an array's values in the module's memory. Infers the array type from RTTI.
        List<num> __getArrayView(int arr) {
            final Uint32List U32 = memory.buffer.asUint32List();
            final int id = U32[arr + ID_OFFSET >> 2];
            final int info = getArrayInfo(id);
            final int align = getValueAlign(info);
            int buf = info & STATICARRAY != 0
                ? arr
                : U32[arr + ARRAYBUFFERVIEW_DATASTART_OFFSET >> 2];
            final int length = info & ARRAY != 0
                ? U32[arr + ARRAY_LENGTH_OFFSET >> 2]
                : U32[buf + SIZE_OFFSET >> 2] >> align;
            return getView(align, info & VAL_SIGNED != 0, info & VAL_FLOAT != 0).sublist(buf >>= align, buf + length);
        }
        extendedExports["__getArrayView"] = allowInterop(__getArrayView);

        /// Copies an array's values from the module's memory. Infers the array type from RTTI.
        List<num> __getArray(int arr) {
            final List<num> input = __getArrayView(arr);
            final List<num> out = new List<num>.from(input);
            return out;
        }
        extendedExports["__getArray"] = allowInterop(__getArray);

        void __getArrayTo(int arr, List<num> target) {
            final List<num> input = __getArrayView(arr);
            target.setAll(0, input);
        }
        extendedExports["__getArrayTo"] = allowInterop(__getArrayTo);

        /// Gets a live view on a typed array's values in the module's memory.
        T getTypedArrayView<T extends List<num>>(_TypedListInfo<T> info, int ptr) {
            final Uint32List U32 = memory.buffer.asUint32List();
            final int bufPtr = U32[ptr + ARRAYBUFFERVIEW_DATASTART_OFFSET >> 2];
            return info.newList(memory.buffer, bufPtr, U32[bufPtr + SIZE_OFFSET >>2] >> info.align);
        }

        /// Copies a typed array's values from the module's memory.
        T getTypedArray<T extends List<num>>(_TypedListInfo<T> info, int ptr) {
            return info.copyList(getTypedArrayView(info, ptr));
        }

        /// Attach a set of get TypedArray and View functions to the exports.
        void attachTypedArrayFunctions<T extends List<num>>(_TypedListInfo<T> info) {
            extendedExports["__get${info.name}"] = allowInterop((int ptr) => getTypedArray<T>(info, ptr));
            extendedExports["__get${info.name}View"] = allowInterop((int ptr) => getTypedArrayView<T>(info, ptr));
        }

        // not exactly as elegant as the JS version... but it should work

        attachTypedArrayFunctions(new _TypedListInfo<Int8List>("Int8List",
                (ByteBuffer buffer, int offset, int length) => buffer.asInt8List(offset,length),
                (Int8List source) => new Int8List.fromList(source), 0));

        attachTypedArrayFunctions(new _TypedListInfo<Uint8List>("Uint8List",
                (ByteBuffer buffer, int offset, int length) => buffer.asUint8List(offset,length),
                (Uint8List source) => new Uint8List.fromList(source), 0));

        attachTypedArrayFunctions(new _TypedListInfo<Uint8ClampedList>("Uint8ClampedList",
                (ByteBuffer buffer, int offset, int length) => buffer.asUint8ClampedList(offset,length),
                (Uint8ClampedList source) => new Uint8ClampedList.fromList(source), 0));

        attachTypedArrayFunctions(new _TypedListInfo<Int16List>("Int16List",
                (ByteBuffer buffer, int offset, int length) => buffer.asInt16List(offset,length),
                (Int16List source) => new Int16List.fromList(source), 1));

        attachTypedArrayFunctions(new _TypedListInfo<Uint16List>("Uint16List",
                (ByteBuffer buffer, int offset, int length) => buffer.asUint16List(offset,length),
                (Uint16List source) => new Uint16List.fromList(source), 1));

        attachTypedArrayFunctions(new _TypedListInfo<Int32List>("Int32List",
                (ByteBuffer buffer, int offset, int length) => buffer.asInt32List(offset,length),
                (Int32List source) => new Int32List.fromList(source), 2));

        attachTypedArrayFunctions(new _TypedListInfo<Uint32List>("Uint32List",
                (ByteBuffer buffer, int offset, int length) => buffer.asUint32List(offset,length),
                (Uint32List source) => new Uint32List.fromList(source), 2));

        attachTypedArrayFunctions(new _TypedListInfo<Float32List>("Float32List",
                (ByteBuffer buffer, int offset, int length) => buffer.asFloat32List(offset,length),
                (Float32List source) => new Float32List.fromList(source), 2));

        attachTypedArrayFunctions(new _TypedListInfo<Float64List>("Float64List",
                (ByteBuffer buffer, int offset, int length) => buffer.asFloat64List(offset,length),
                (Float64List source) => new Float64List.fromList(source), 3));



        /// Tests whether an object is an instance of the class represented by the specified base id.
        bool __instanceOf(int ptr, int baseId) {
            final Uint32List U32 = memory.buffer.asUint32List();
            int id = U32[ptr + ID_OFFSET >> 2];
            if (id <= U32[rttiBase >> 2]) {
                do {
                    if (id == baseId) {
                        return true;
                    }
                    id = getBase(id);
                } while (id != 0);
            }
            return false;
        }
        extendedExports["__instanceOf"] = allowInterop(__instanceOf);

        // Pull basic exports to extendedExports so code in preInstantiate can use them
        if (!extendedExports.containsKey("memory")) { extendedExports["memory"] = memory; }
        if (!extendedExports.containsKey("table")) { extendedExports["table"] = table; }

        // Demangle exports and provide the usual utility on the prototype
        return demangle(exports, extendedExports);
    }

    static bool isResponse(dynamic src) {
        return src != null && src is Response;
    }

    static bool isModule(dynamic src) {
        return src is WebAssembly.Module;
    }

    /// Asynchronously instantiates an AssemblyScript module from anything that can be instantiated.
    static Future<Program> instantiate(dynamic source, [Map<String,dynamic> imports]) async {
        imports ??= <String,dynamic>{};
    
        source = await source;
        if (isResponse(source)) {
            return instantiateStreaming(source, imports);
        }

        final WebAssembly.Module module = isModule(source) ? source : await promiseToFuture(WebAssembly.compile(source));
        final Map<String,dynamic> extended = preInstantiate(imports);
        final WebAssembly.Instance instance = new WebAssembly.Instance(module, jsify(imports));
        final Map<String,dynamic> exports = postInstantiate(extended, instance);
        
        return new Program(module, instance, exports);
    }

    /// Synchronously instantiates an AssemblyScript module from a WebAssembly.Module or binary buffer.
    static Program instantiateSync(dynamic source, [Map<String,dynamic> imports]) {
        imports ??= <String, dynamic>{};

        final WebAssembly.Module module = isModule(source) ? source : new WebAssembly.Module(source);
        final Map<String,dynamic> extended = preInstantiate(imports);
        final WebAssembly.Instance instance = new WebAssembly.Instance(module, jsify(imports));
        final Map<String,dynamic> exports = postInstantiate(extended, instance);

        return new Program(module, instance, exports);
    }

    /// Asynchronously instantiates an AssemblyScript module from a response, i.e. as obtained by `fetch`.
    static Future<Program> instantiateStreaming(dynamic source, [Map<String,dynamic> imports]) async {
        imports ??= <String, dynamic>{};
        if (WebAssembly.instantiateStreaming == null) {
            source = await source;
            return instantiate(isResponse(source) ? source.arrayBuffer() : source, imports);
        }
        final Map<String,dynamic> extended = preInstantiate(imports);
        final WebAssembly.ResultObject result = await promiseToFuture(WebAssembly.instantiateStreaming(source, jsify(imports)));
        final Map<String,dynamic> exports = postInstantiate(extended, result.instance);

        return new Program(result.module, result.instance, exports);
    }

    static Map<String,dynamic> demangle(Map<String,dynamic> exports, [Map<String,dynamic> extendedExports]) {
        extendedExports ??= <String,dynamic>{};
        final RegExp getSet = new RegExp("^(get|set)");

        void Function(int length) setArgumentsLength;
        if (exports.containsKey("__argumentsLength")) {
            setArgumentsLength = allowInterop((int length) { exports["__argumentsLength"].value = length; });
        } else if (exports.containsKey("__setArgumentsLength")) {
            setArgumentsLength = exports["__setArgumentsLength"];
        } else if (exports.containsKey("__setargc")) {
            setArgumentsLength = exports["__setargc"];
        } else {
            setArgumentsLength = allowInterop((int length) { /* no-op */ });
        }

        for (final String internalName in exports.keys) {
            final dynamic elem = exports[internalName];
            final List<String> parts = internalName.split(".");
            Map<String,dynamic> curr = extendedExports;
            while (parts.length > 1) {
                final String part = parts.removeAt(0);
                if (!curr.containsKey(part)) {
                    curr[part] = <String,dynamic>{};
                }
                curr = curr[part];
            }

            final String name = parts[0];
            final int hash = name.indexOf("#");
            if(hash >= 0) {
                // TODO: class stuff?
            } else {
                if (name.startsWith(getSet)) {
                    //TODO: getset stuff
                    //print("$name is a get/set");
                    //TODO: function wrapping
                } else if (elem is Function) {
                    //print("$name is a function");
                    _injectWrapperFunction();
                    curr[name] = _wrap(elem, allowInterop(setArgumentsLength));
                } else {
                    //print("$name is something else");
                    curr[name] = elem;
                    //print(elem.runtimeType);
                    //js.context["console"].callMethod("log", <dynamic>[elem]);
                }
            }
        }

        return extendedExports;
    }
}

class Program {
    final WebAssembly.Module module;
    final WebAssembly.Instance instance;
    final Map<String,dynamic> exportMap;
    final Exports exports;

    Program(WebAssembly.Module this.module, WebAssembly.Instance this.instance, Map<String,dynamic> this.exportMap) : this.exports = new Exports._(exportMap);
}

class Exports extends MapView<String,dynamic> {
    Exports._(Map<String,dynamic> map) : super(map);

    // global getter
    int global(String name) {
        if (!this.containsKey(name)) {
            throw Exception("Global $name not found");
        }
        final dynamic item = this[name];
        if (!(item is WebAssembly.Global)) {
            throw Exception("$name is not a global");
        }
        return item.value;
    }

    // instance check
    bool instanceOf(int ptr, int id) => this["__instanceOf"](ptr, id);

    // basic memory management functions
    int alloc(int size, int id) => this["__alloc"](size, id);
    int retain(int ptr)         => this["__retain"](ptr);
    void release(int ptr)       => this["__release"](ptr);

    // strings
    int allocString(String string) => this["__allocString"](string);
    String getString(int ptr)      => this["__getString"](ptr);
    
    // basic arrays
    int allocArray<T>(int id, List<T> values)    => this["__allocArray"](id, values);
    List<T> getArray<T>(int ptr)                 => this["__getArray"](ptr);
    void getArrayTo(int ptr, List<num> target)   => this["__getArrayTo"](ptr, target);
    List<T> getArrayView<T extends num>(int ptr) => this["__getArrayView"](ptr);
    
    // specific typed arrays
    Int8List getInt8List(int ptr)       => this["__getInt8List"](ptr);
    Int8List getInt8ListView(int ptr)   => this["__getInt8ListView"](ptr);
    Uint8List getUint8List(int ptr)     => this["__getUint8List"](ptr);
    Uint8List getUint8ListView(int ptr) => this["__getUint8ListView"](ptr);
    Uint8ClampedList getUint8ClampedList(int ptr)     => this["__getUint8ClampedList"](ptr);
    Uint8ClampedList getUint8ClampedListView(int ptr) => this["__getUint8ClampedListView"](ptr);
    
    Int16List getInt16List(int ptr)       => this["__getInt16List"](ptr);
    Int16List getInt16ListView(int ptr)   => this["__getInt16ListView"](ptr);
    Uint16List getUint16List(int ptr)     => this["__getUint16List"](ptr);
    Uint16List getUint16ListView(int ptr) => this["__getUint16ListView"](ptr);

    Int32List getInt32List(int ptr)       => this["__getInt32List"](ptr);
    Int32List getInt32ListView(int ptr)   => this["__getInt32ListView"](ptr);
    Uint32List getUint32List(int ptr)     => this["__getUint32List"](ptr);
    Uint32List getUint32ListView(int ptr) => this["__getUint32ListView"](ptr);

    Int64List getInt64List(int ptr)       => this["__getInt64List"](ptr);
    Int64List getInt64ListView(int ptr)   => this["__getInt64ListView"](ptr);
    Uint64List getUint64List(int ptr)     => this["__getUint64List"](ptr);
    Uint64List getUint64ListView(int ptr) => this["__getUint64ListView"](ptr);

    Float32List getFloat32List(int ptr)     => this["__getFloat32List"](ptr);
    Float32List getFloat32ListView(int ptr) => this["__getFloat32ListView"](ptr);
    Float64List getFloat64List(int ptr)     => this["__getFloat64List"](ptr);
    Float64List getFloat64ListView(int ptr) => this["__getFloat64ListView"](ptr);
    
    // yeah looks like this stuff isn't gonna work because of symbol names
    // needing dart:mirrors which is forbidden in web
    /*@override
    dynamic noSuchMethod(Invocation invocation) {
        print(invocation);
        print(invocation.memberName);
        print("accessor: ${invocation.isAccessor}, getter: ${invocation.isGetter}, setter: ${invocation.isSetter}, method: ${invocation.isMethod}");

        final String name = invocation.memberName. // ???
        if (map.containsKey(name)) {
            if (invocation.isMethod) {
                //return this.map[name](invocation.positionalArguments);
                return _callWithList(this.map[name], invocation.positionalArguments);
            }
        } else {
            super.noSuchMethod(invocation);
        }
    }*/
}

typedef _TypedListMaker<T> = T Function(ByteBuffer buffer, int offset, int length);
typedef _TypedListCopy<T> = T Function(T source);

class _TypedListInfo<T> {
    final String name;
    final _TypedListMaker<T> newList;
    final _TypedListCopy<T> copyList;
    final int align;

    _TypedListInfo(String this.name, _TypedListMaker<T> this.newList, _TypedListCopy<T> this.copyList, int this.align);
}

bool _injected = false;
void _injectWrapperFunction() {
    if (_injected) { return; }
    _injected = true;

    final ScriptElement block = new ScriptElement();
    block.text = """
        function WasmLoaderWrapFunction(f, argsFunc) {
            let wrapped = (...args) => {
                argsFunc(args.length);
                return f(...args);
            };
            wrapped.original = f;
            return wrapped;
        }
    """;
    document.head.append(block);
}

@JS("WasmLoaderWrapFunction")
external dynamic _wrap(Function f, Function argsFunc);
