@TestOn("chrome")

import 'package:CommonLib/src/utility/jsonhandler.dart';
import 'package:test/test.dart';

void main() {
    group("is literally anything happening?", ()
    {
        JsonHandler jsonHandler;
        List<int>? seadwellerBodies;

        setUp(() {
            jsonHandler = simulatedDollData();
            seadwellerBodies = jsonHandler.getArray<int>("Lamia.seaDwellerBodies");
        });

        test("String.split() splits the string on the delimiter", () {
            const String string = "foo.bar.baz";
            expect(string.split("."), equals(<String>["foo", "bar", "baz"]));
        });

        test("Lamia seadweller bodies ", () {
            expect(seadwellerBodies, equals(<int>[7, 8, 9, 12, 13, 27, 28, 29, 34, 35, 39, 40, 46, 50, 51, 52, 60, 61]));
        });
    });
}


JsonHandler simulatedDollData() {
    final Map<String,dynamic> json = <String,dynamic>{};
    json["Lamia"] = <String, dynamic>{};
    json["Lamia"]["seaDwellerBodies"] = <int>[7,8,9,12,13,27,28,29,34,35,39,40,46,50,51,52,60,61];
    json["Lamia"]["layers"] = <String,int>{"Body": 77};
    return new JsonHandler(json);
}