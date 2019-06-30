import "dart:html";

/// Base class for web worker main classes
/// Extend this in the worker to automatically handle handshake and message passing
abstract class WorkerBase {
    final DedicatedWorkerGlobalScope self = DedicatedWorkerGlobalScope.instance;

    WorkerBase() {
        self.onMessage.listen(_handleMainThreadMessage);
    }

    void _handleMainThreadMessage(MessageEvent event) {
        if (!(event.data is Map)) { return; }
        final Map<dynamic,dynamic> data = event.data;
        if (data.containsKey("label") && data.containsKey("payload")) {
            final String label = data["label"];
            final dynamic payload = data["payload"];

            handleMainThreadMessage(label, payload);
        }
    }

    void handleMainThreadMessage(String label, dynamic payload);

    /// Send a named data package to the main thread
    /// Make sure the payload is a serializable type or collection thereof - custom complex classes won't survive!
    void sendMainThreadMessage(String label, dynamic payload) {
        final Map<String, dynamic> data = <String, dynamic>{
          "label": label,
          "payload": payload
        };
        self.postMessage(data);
    }
}