import "dart:async";
import "dart:html";

/// Provides an interface for a web worker with a main class based on WorkerBase
/// Instantiate a worker and handler with createWebWorker
class WorkerHandler {
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
        if (data.containsKey("id")) {
            final int id = data["id"];

            if (_pending.containsKey(id)) {
                final Completer<dynamic> completer = _pending[id];

                if (data.containsKey("error")) {
                    completer.completeError(new WorkerException(data["error"]), new StackTrace.fromString(data["trace"]));
                } else if (data.containsKey("payload")) {
                    completer.complete(data["payload"]);
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
            "command": command,
        };

        if (expectReply) {
            completer = new Completer<T>();
            final int id = _commandId;
            _commandId++;

            _pending[id] = completer;
            data["id"] = id;
        }

        if (payload != null) {
            data["payload"] = payload;
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