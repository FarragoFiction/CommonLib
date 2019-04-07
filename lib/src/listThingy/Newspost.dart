import 'dart:html';
import 'package:CommonLib/src/listThingy/Thingy.dart';

class Newspost extends Thingy {
    String dateText;
    Newspost(String this.dateText, String text) : super(text);

    @override
    void renderSelf(Element container) {
        final UListElement me = new UListElement();
        container.append(me);
        me.text = "$dateText: $text";
        me.style.color = bgColor.toStyleString();
    }


}