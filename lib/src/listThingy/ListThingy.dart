import "package:CommonLib/Colours.dart";
import "dart:html";
import 'package:CommonLib/src/listThingy/Thingy.dart';
//has a list of thingies, prints them out onto the screen as a list
//todo, newsposts, etc.
class ListThingy
{
    List<Thingy> thingies = new List<Thingy>();
    String name;
    ListThingy(String this.name, List<Thingy> this.thingies);

    void renderSelf(Element container) {
        HeadingElement h1 = new HeadingElement.h1();
        h1.text = name;
        container.append(h1);
        UListElement list = new UListElement();
        container.append(list);
        for(Thingy t in thingies) {
            t.renderSelf(list);
        }
    }
}



