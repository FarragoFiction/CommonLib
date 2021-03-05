import "dart:async";
import "dart:html";

import "package:CommonLib/Collection.dart";

Element? output = querySelector('#output');
Future<void> main() async {
    final WeightedList<String> list = new WeightedList<String>();

    list.addAll(<String>["blah", "blah", "blah"]);
}