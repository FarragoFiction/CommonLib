import "dart:html";

typedef WorkerMessageListener = void Function(String label, dynamic payload);

/// Provides an interface for a web worker with a main class based on WorkerBase
/// Instantiate a worker and handler with createWebWorker
class WorkerHandler {
    final Worker _worker;
    final Set<WorkerMessageListener> _listeners = <WorkerMessageListener>{};
    Stream<Event> onError;

    WorkerHandler._(Worker this._worker) {
        onError = this._worker.onError;
        _worker.onMessage.listen(_handleMessage);
    }

    void _handleMessage(MessageEvent event) {
        if (!(event.data is Map)) { return; }
        final Map<dynamic,dynamic> data = event.data;
        if (data.containsKey("label") && data.containsKey("payload")) {
            final String label = data["label"];
            final dynamic payload = data["payload"];

            for (final WorkerMessageListener listener in _listeners) {
                listener(label, payload);
            }
        }
    }

    WorkerMessageListener listen(WorkerMessageListener listener) {
        _listeners.add(listener);
        return listener;
    }

    void sendMessage(String label, dynamic payload) {
        final Map<String, dynamic> data = <String, dynamic>{
            "label": label,
            "payload": payload
        };
        _worker.postMessage(data);
    }
}

/// Path should be the file name of the dart worker file
WorkerHandler createWebWorker(String path) {
    final Worker worker = new Worker("$path.js");

    return new WorkerHandler._(worker);
}