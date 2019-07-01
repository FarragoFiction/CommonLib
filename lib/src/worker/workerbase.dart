import "dart:html";

/// Base class for web worker main classes
/// Extend this in the worker to automatically handle handshake and message passing
abstract class WorkerBase {
    final DedicatedWorkerGlobalScope workerContext = DedicatedWorkerGlobalScope.instance;

    WorkerBase() {
        workerContext.onMessage.listen(_handleMessage);
    }

    Future<void> _handleMessage(MessageEvent event) async {
        if (!(event.data is Map)) { return; }
        final Map<dynamic,dynamic> data = event.data;
        if (data.containsKey("command")) {
            final String command = data["command"];

            dynamic payload;
            if (data.containsKey("payload")) {
                payload = data["payload"];
            }

            if (data.containsKey("id")) {
                final int id = data["id"];

                dynamic processedPayload;
                dynamic error;

                try {
                    processedPayload = await handleCommand(command, payload);
                }
                // ignore: avoid_catches_without_on_clauses
                catch(e) {
                    error = e;
                }

                final Map<String,dynamic> reply = <String,dynamic>{
                    "id": id
                };
                if (error != null) {
                    reply["error"] = error;
                }
                else if (processedPayload != null) {
                    reply["payload"] = processedPayload;
                }

                workerContext.postMessage(reply);
            } else {
                handleCommand(command, payload);
            }
        }
    }

    Future<dynamic> handleCommand(String command, dynamic payload);
}