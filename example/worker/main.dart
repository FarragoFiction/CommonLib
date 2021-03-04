import "dart:async";
import "dart:html";

import "package:CommonLib/Workers.dart";

Element? output = querySelector('#output');
Future<void> main() async {
    print("worker test!");

    final WorkerHandler worker = createWebWorker("worker.worker.dart");

    try {
        await worker.sendCommand("error");
    } on WorkerException catch (e, trace) {
        print("returned error: $e");
        print(trace);
    }
}
