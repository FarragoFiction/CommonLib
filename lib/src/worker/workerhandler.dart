import "dart:async";
import "dart:html";

/// Provides an interface for a web worker with a main class based on WorkerBase
/// Instantiate a worker and handler with createWebWorker
class WorkerHandler {
    static const String idLabel = "id";
    static const String payloadLabel = "payload";
    static const String errorLabel = "error";
    static const String traceLabel = "trace";
    static const String commandLabel = "command";

    final Worker _worker;
    Stream<Event> onError;

    final Map<int, Completer<dynamic>> _pending = <int, Completer<dynamic>>{};
    int _commandId = 0;

    WorkerHandler._(Worker this._worker) {
        onError = this._worker.onError;
        _worker.onMessage.listen(_handleMessage);
    }

    void _handleMessage(MessageEvent event) {
        if (!(event.data is Map)) { return; }
        final Map<dynamic,dynamic> data = event.data;
        if (data.containsKey(idLabel)) {
            final int id = data[idLabel];

            if (_pending.containsKey(id)) {
                final Completer<dynamic> completer = _pending[id];

                if (data.containsKey(errorLabel)) {
                    completer.completeError(new WorkerException(data[errorLabel]), new StackTrace.fromString(data[traceLabel]));
                } else if (data.containsKey(payloadLabel)) {
                    completer.complete(data[payloadLabel]);
                } else {
                    completer.complete(null);
                }
                _pending.remove(id);
            }
        }
    }

    Future<T> sendCommand<T>(String command, {dynamic payload, bool expectReply = true}) async {
        Completer<T> completer;

        final Map<String,dynamic> data = <String,dynamic>{
            commandLabel: command,
        };

        if (expectReply) {
            completer = new Completer<T>();
            final int id = _commandId;
            _commandId++;

            _pending[id] = completer;
            data[idLabel] = id;
        }

        if (payload != null) {
            data[payloadLabel] = payload;
        }

        _worker.postMessage(data);

        if (expectReply) { return completer.future; }

        return null;
    }

    void sendInstantCommand(String command, [dynamic payload]) => sendCommand(command, payload: payload, expectReply: false);
}

/// Path should be the file name of the dart worker file
WorkerHandler createWebWorker(String path) {
    final Worker worker = new Worker("$path.js");

    return new WorkerHandler._(worker);
}

class WorkerException implements Exception {
    String message;
    WorkerException(String this.message);

    @override
    String toString() => "WorkerException: $message";
}