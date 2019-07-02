import "dart:html";

import "workerhandler.dart";

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
        if (data.containsKey(WorkerHandler.commandLabel)) {
            final String command = data[WorkerHandler.commandLabel];

            dynamic payload;
            if (data.containsKey(WorkerHandler.payloadLabel)) {
                payload = data[WorkerHandler.payloadLabel];
            }

            if (data.containsKey(WorkerHandler.idLabel)) {
                final int id = data[WorkerHandler.idLabel];

                dynamic processedPayload;
                dynamic error;
                dynamic trace;

                try {
                    processedPayload = await handleCommand(command, payload);
                }
                // ignore: avoid_catches_without_on_clauses
                catch(e,t) {
                    error = e;
                    trace = t;
                }

                final Map<String,dynamic> reply = <String,dynamic>{
                    WorkerHandler.idLabel: id
                };
                if (error != null) {
                    reply[WorkerHandler.errorLabel] = error.toString();
                    reply[WorkerHandler.traceLabel] = trace.toString();
                }
                else if (processedPayload != null) {
                    reply[WorkerHandler.payloadLabel] = processedPayload;
                }

                workerContext.postMessage(reply);
            } else {
                handleCommand(command, payload);
            }
        }
    }

    Future<dynamic> handleCommand(String command, dynamic payload);
}