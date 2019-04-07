/*
    should be a wrapper for a map.
    new JsonObject.fromJsonString(json); should be implemented.
 */
import 'dart:collection';
import 'dart:convert';

// WHY DART, WHY?!
// ignore: prefer_mixin
class JSONObject extends Object with MapMixin<String,String>{
    Map<String, dynamic> json = <String,dynamic>{};
    JSONObject();

    JSONObject.fromJSONString(String j){
        //print("trying to make a json object from $j ");
        //okay. that's not working. what if i do it opposite to see what a encoded object looks like
        //final JSONObject test = new JSONObject();
        //test["HELLO"] = "WORLD ";
        //test["GOODBYE"] = "WORLD BUT A SECOND TIME ";
        //print("Encoded: ${JSON.encode(test)}");
        //print("String: ${test}");

        json.addAll(jsonDecode(j));
    }

    static Set<int> jsonStringToIntSet(String str) {
        if(str == null) return <int>{};
        //print("str is $str");
        str = str.replaceAll("{", "");
        str = str.replaceAll("}", "");
        str = str.replaceAll(" ", "");

        final List<String> tmp = str.split(",");
        final Set<int> ret = <int>{};
        for(final String s in tmp) {
            //print("s is $s");
            try {
                final int i = int.parse(s);
                //print("adding $i");
                ret.add(i);
            } on Exception {
                //oh well. probably a bracket or a space or something
            }
        }
        return ret;
    }

    static List<int> jsonStringToIntArray(String str) {
        if(str == null) return <int>[];
        //;
        str = str.replaceAll("[", "");
        str = str.replaceAll("]", "");
        str = str.replaceAll(" ", "");

        final List<String> tmp = str.split(",");
        final List<int> ret = <int>[];
        for(final String s in tmp) {
            //;
            try {
                final int i = int.parse(s);
                //;
                ret.add(i);
            } on Exception {
                //oh well. probably a bracket or a space or something
            }
        }
        return ret;
    }

    static Set<String> jsonStringToStringSet(String str) {
        if(str == null) return <String>{};
        //print("str is $str");
        str = str.replaceAll("{", "");
        str = str.replaceAll("}", "");
        str = str.replaceAll(" ", "");

        final List<String> tmp = str.split(",");
        final Set<String> ret = <String>{};
        for(final String s in tmp) {
            //print("s is $s");
            try {
                //print("adding $i");
                ret.add(s);
            } on Exception {
                //oh well. probably a bracket or a space or something
            }
        }
        return ret;
    }

    static List<String> jsonStringToStringArray(String str) {
        if(str == null) return <String>[];
        //;
        str = str.replaceAll("[", "");
        str = str.replaceAll("]", "");
        str = str.replaceAll(" ", "");

        final List<String> tmp = str.split(",");
        return tmp;
    }

    @override
    String toString() {
        return jsonEncode(json);
    }

    @override
    String operator [](Object key) {
        final String obj = json[key];
        return obj;
    }

    @override
    void operator []=(String key, String value) {
        json[key] = value;
    }

    @override
    void clear() {
        json.clear();
    }

    @override
    Iterable<String> get keys => json.keys;

    @override
    String remove(Object key) {
        return json.remove(key);
    }
}