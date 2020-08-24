void runTestSync(String name, void Function() func, int times) {
    final DateTime start = new DateTime.now();
    for (int i=0; i<times; i++) {
        func();
    }
    final int duration = new DateTime.now().difference(start).inMicroseconds;
    final String readable = (duration / 1000).toStringAsFixed(2);
    final int per = duration ~/ times;
    final String readablePer = (per / 1000).toStringAsFixed(2);
    print("$name: $times iterations in ${readable}ms, ${readablePer}ms per iteration");
}

Future<void> runTestAsync(String name, Future<void> Function() func, int times) async {
    final DateTime start = new DateTime.now();
    for (int i=0; i<times; i++) {
        await func();
    }
    final int duration = new DateTime.now().difference(start).inMicroseconds;
    final String readable = (duration / 1000).toStringAsFixed(2);
    final int per = duration ~/ times;
    final String readablePer = (per / 1000).toStringAsFixed(2);
    print("$name: $times iterations in ${readable}ms, ${readablePer}ms per iteration");
}