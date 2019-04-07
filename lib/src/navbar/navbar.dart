import 'dart:html';

import 'package:CommonLib/src/utility/path_utils.dart';


String simulatedParamsGlobalVar = "";


//just loads the navbar.text into the appropriate div.
void loadNavbar() {
    HttpRequest.getString(PathUtils.adjusted("navbar.txt")).then(onNavbarLoaded);
}

void onNavbarLoaded(String data) {
    // PL: oh boy fixing those urls
    final int subdirs = PathUtils.getPathDepth();
    data = data.replaceAllMapped(new RegExp("(href|src) ?= ?([\"'])(?!https?:)"), (Match m) => "${m.group(1)} = ${m.group(2)}${"../"*subdirs}");

    querySelector("#navbar").appendHtml(data, treeSanitizer: NodeTreeSanitizer.trusted);
}




String getParamStringMinusParam(String name) {
    String params = window.location.href.substring(window.location.href.indexOf("?") + 1);
    if (params == window.location.href) params = "";
    final String value = getParameterByName(name);
    final String replaceString = "$name=$value";
    //print("inside navbar params are $params, name is $name and value is $value, replaceString is $replaceString");
    if(value != null) {
        params = params.replaceAll(replaceString, "");
    }
    //print("params are returning $params");
    return params;
}

//http://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
//simulatedParamsGlobalVar is the simulated global vars.
String getParameterByName(String name, [String url]) {
    Uri uri = Uri.base;
    String tmp;
    if (url != null) {
        uri = Uri.parse(url);
        // //print("uri is $uri");
        tmp = (uri.queryParameters[name]); //doesn't need decoded, guess it was auto decoded with the parse?
        if(tmp != null) return tmp;
    } else {
        ////print("uri is $uri");
        tmp = (uri.queryParameters[name]);
        if (tmp != null) tmp = Uri.decodeComponent(tmp);
        if(tmp != null) return tmp;
    }
    ////print("gonna check simulated params");

    //one last shot with simulatedParamsGlobalVar;//lets me use existing framework to parse simulated params for tourney
    if(tmp == null && simulatedParamsGlobalVar.isNotEmpty) {
        //print ("Debugging tourney: can't find param $name, so going to check $simulatedParamsGlobalVar");
        final String params =  window.location.href.substring(window.location.href.indexOf("?") + 1);
        final String base = window.location.href.replaceAll("?$params","");
        final String tmpurl = "$base?$simulatedParamsGlobalVar";
        ////print("Debugging tourney: base is $base, tmpurl is $tmpurl");
        uri = Uri.parse(tmpurl);
        final String tmp = (uri.queryParameters[name]);
        //if(tmp != null) print ("Debugging tourney: found param $name, it was $tmp!");
        return tmp;
    }

    return tmp;
}

String getRawParameterByName(String name, String url) {
    Uri uri = Uri.base;
    if (url != null) {
        uri = new Uri.file(url); //TODO is there no built in way to parse a string as a URI? need for virtual parameters like ocDataSTrings from selfInsertOC=true
    }
    return uri.queryParameters[name];
}

void toggleVoid() {
    querySelector('body').style.backgroundColor = "#f8c858";
    querySelector('body').style.backgroundImage = "url(images/pen15_bg1.png)"; //can not unsee the dics now.
    //querySelectorAll(".void").forEach((Element e) => WHAT SHOULD I DO HEAR for DISPLAY:none);
    final List<Element> voidElements = querySelectorAll(".void");
    for (final Element v in voidElements) {
        toggle(v);
    }
}

//work around for dart not having this jquery function except for classes apparently
void toggle(Element v) {
    final String display = v.style.display;
    ////print("display is $display");
    if (display == "none" || display.isEmpty) {
        show(v);
    } else {
        hide(v);
    }
}

void show(Element v) {
    if(v == null) {
        //print("ERROR: trying to show a null element");
        return;
    }
    ////print("showing ${v.id}");
    v.style.display = "block";
}

void hide(Element v) {
    if(v == null) {
        //print("ERROR: trying to hide a null element");
        return;
    }
    v.style.display = "none";
}
