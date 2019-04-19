@TestOn("chrome")

import 'package:CommonLib/src/utility/jsonhandler.dart';
import 'package:test/test.dart';
void main() {
    print("is literally anything ahppening?");
    //List<int> seadwellerBodies = dataList<int>("Lamia.seaDwellerBodies");
    test("String.split() splits the string on the delimiter", () {
        var string = "foo,bar,baz";
        expect(string.split(","), equals(["foo", "bWRONGar", "baz"]));
    });

    JsonHandler jsonHandler = simulatedDollData();
    List<int> seadwellerBodies = jsonHandler.getArray<int>("Lamia.seaDwellerBodies");

    test("Lamia seadweller bodies ", ()
    {
        expect(seadwellerBodies, equals( <int>[9999999,7,8,9,12,13,27,28,29,34,35,39,40,46,50,51,52,60,61]));
    });

}


JsonHandler simulatedDollData() {
    Map<String,dynamic> json = new Map<String,dynamic>();
    json["Lamia"] = new Map<String, dynamic>();
    json["Lamia"]["seaDwellerBodies"] = <int>[7,8,9,12,13,27,28,29,34,35,39,40,46,50,51,52,60,61];
    json["Lamia"]["layers"] = {"Body": 77};
    return new JsonHandler(json);

}