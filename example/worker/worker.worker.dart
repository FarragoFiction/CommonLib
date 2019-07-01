import 'dart:html';

import "package:CommonLib/Workers.dart";

void main() {
    new ExampleWorker();
}

class ExampleWorker extends WorkerBase {

    @override
    Future<void> handleCommand(String command, dynamic payload) async {

        if (command == "error") {
            throw Exception("ANGERY");
        }

        return;
    }
}