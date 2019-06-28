import 'dart:html';

void main() {
    new ExampleWorker();
}

class ExampleWorker {
    DedicatedWorkerGlobalScope scope = DedicatedWorkerGlobalScope.instance;

    ExampleWorker() {
        print("work work");

        scope.onMessage.listen((MessageEvent e){
            print(e.data);
            print(e.data.runtimeType);
            MessagePort port = e.data["port"];
            print(port);
            port.postMessage("port working");
        });
    }
}