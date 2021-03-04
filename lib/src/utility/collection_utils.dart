import "predicates.dart";

U joinCollection<T, U>(Iterable<T> list, {required Mapping<T,U> convert, required Combiner<U> combine, required U initial}) {
    final Iterator<T> iter = list.iterator;

    bool first = true;
    U ret = initial;

    while (iter.moveNext()) {
        if (first) {
            first = false;
            ret = convert(iter.current);
        } else {
            ret = combine(ret, convert(iter.current));
        }
    }

    return ret;
}

String joinMatches(Iterable<Match> matches, [String joiner = ""]) => joinCollection(matches, convert: (Match m) => m.group(0)!, combine: (String p, String e) => "$p$joiner$e", initial: "");
String joinList<T>(Iterable<T> list, [String joiner = ""]) => joinCollection(list, convert: (T e) => e.toString(), combine: (String p, String e) => "$p$joiner$e", initial: "");