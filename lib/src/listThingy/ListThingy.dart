import "dart:html";
import 'Thingy.dart';
//has a list of thingies, prints them out onto the screen as a list
//todo, newsposts, etc.
class ListThingy
{
    List<Thingy> thingies = <Thingy>[];
    String name;
    ListThingy(String this.name, List<Thingy> this.thingies);

    void renderSelf(Element container) {
        final HeadingElement h1 = new HeadingElement.h1();
        h1.text = name;
        container.append(h1);
        final UListElement list = new UListElement();
        container.append(list);
        for(final Thingy t in thingies) {
            t.renderSelf(list);
        }
    }
}



