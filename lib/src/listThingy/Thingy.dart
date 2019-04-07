import 'dart:html';
import 'package:CommonLib/Colours.dart';

class Thingy {
    static Colour red = new Colour(255,0,0);
    static Colour green = new Colour(0,255,0);
    static Colour orange = new Colour(255,100,0);

    String text;
    Colour bgColor;

    Thingy(String this.text, [Colour this.bgColor]){
        bgColor ??= new Colour(0,0,0); //default is black
    }

    void renderSelf(Element container) {
        final LIElement me = new LIElement();
        container.append(me);
        me.text = text;
        me.style.color = bgColor.toStyleString();
    }
}