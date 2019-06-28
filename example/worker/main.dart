import "dart:async";
import "dart:html";


Element output = querySelector('#output');
Future<void> main() async {
    print("worker test!");
    final Worker worker = new Worker("worker.worker.dart.js");
    //final Worker worker = new Worker("jsworker.js");

    final MessageChannel channel = new MessageChannel();

    worker.postMessage(<String,dynamic>{"port": channel.port1}, <Object>[channel.port1]);

    channel.port2.onMessage.listen((MessageEvent e) => print("message: ${e.data}"));
}
