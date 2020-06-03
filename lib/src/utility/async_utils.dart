import "dart:async";

import "predicates.dart";

Future<T> awaitify<T>(Lambda<Lambda<T>> wrapper) {
    final Completer<T> completer = new Completer<T>();

    try {
        wrapper(completer.complete);
    } on Exception catch(e) {
        completer.completeError(e);
    }

    return completer.future;
}