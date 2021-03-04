import "dart:html";
import 'package:CommonLib/src/utility/predicates.dart';

class Search {
    static String _stringMapping(String s) => s; // default mapping for when we have strings

    static Set<T>? textSearch<T>(Iterable<T>? items, String termstring, [Mapping<T,String>? mapping]) {
        if (items == null || items.isEmpty || (!(items.first is String) && mapping == null)) {
            return null;
        }

        if (T is String) {
            // doesn't detect this as a valid implicit cast...
            // ignore: avoid_as
            mapping = _stringMapping as Mapping<T,String>;
        }

        if (mapping == null) { return null; }

        final List<SearchTerm> terms = processTerms(termstring);

        // do actual search
        //print(terms);

        final Set<T> results = <T>{};

        String text;
        bool add = false;
        for (final T item in items) {
            text = mapping(item);

            add = true;

            for (final SearchTerm term in terms) {
                if (term.caseSensitive) {
                    if (text.contains(term.term) == term.negative) { // "does this term NOT match"
                        add = false;
                        break;
                    }
                } else {
                    if (text.toLowerCase().contains(term.term.toLowerCase()) == term.negative) { // "does this term NOT match"
                        add = false;
                        break;
                    }
                }
            }

            if (add) {
                results.add(item);
            }
        }

        return results;
    }

    static List<SearchTerm> processTerms(String termstring) {
        final List<String> termwords = termstring.split(" ");
        final List<SearchTerm> terms = <SearchTerm>[];

        for (int i=0; i<termwords.length; i++) {
            String termword = termwords[i];
            if (termword.isEmpty) { continue; }
            bool negative = false;
            if (termword.startsWith("-")) {
                negative = true;
                termword = termword.substring(1);
            }

            if (termword.startsWith('"')) {
                String term = termword.substring(1);

                if (!term.endsWith('"')) {
                    for (int o = i+1; o<termwords.length; o++) {
                        final String nextterm = termwords[o];
                        i++;
                        if (nextterm.endsWith('"')) {
                            term = "$term ${nextterm.substring(0, nextterm.length-1)}";
                            break;
                        } else {
                            term = "$term $nextterm";
                        }
                    }
                } else {
                    term = term.substring(0,term.length-1);
                }

                if (!term.isEmpty) {
                    terms.add(new SearchTerm(term, negative, true));
                }
            } else {
                if (!termword.isEmpty) {
                    terms.add(new SearchTerm(termword, negative));
                }
            }
        }

        return terms;
    }

    static Element createListSearchBox<T>(Generator<List<T>> gatherer, Lambda<Set<T>?> callback, {Mapping<T,String>? mapping, String emptyCaption = "Search..."}) {
        final TextInputElement element = new TextInputElement()
            ..placeholder = emptyCaption;

        void eventcallback(Event e){
            final Set<T>? results = textSearch(gatherer(), element.value ?? "", mapping);
            callback(results);
        }

        element
            ..addEventListener("change", eventcallback)
            ..addEventListener("keyup", eventcallback)
            ..addEventListener("blur", eventcallback);

        return element;
    }
}

class SearchTerm {
    String term;
    bool negative;
    bool caseSensitive;

    SearchTerm(String this.term, [bool this.negative = false, bool this.caseSensitive = false]);

    @override
    String toString() => "${negative? "[N]" : ""}$term";
}