import 'dart:collection';
import '../utility/predicates.dart';

typedef WeightFunction<T> = double Function(T item, double weight);

/// Used as a basis to [WeightedList] to allow Random.pick and similar to use weights.
abstract class WeightedIterable<T> implements Iterable<T> {
    WeightFunction<T>? initialWeightSetter;
    T get(double position) {
        final double totalWeight = getTotalWeight();

        final double weightPosition = position.clamp(0.0,1.0) * totalWeight;
        double runningTotal = 0.0;

        for (final WeightPair<T> pair in pairs) {
            runningTotal += _getWeight(pair);
            if (weightPosition <= runningTotal) {
                return pair.item;
            }
        }

        throw Exception("Somehow a weighted iterable ran out of weights. This shouldn't happen!");
    }

    Iterable<WeightPair<T>> get pairs;

    double getTotalWeight() {
        double totalWeight = 0.0;
        for (final WeightPair<T> pair in pairs) {
            totalWeight += _getWeight(pair);
        }
        return totalWeight;
    }

    WeightPair<T> _createPair(T item, [double weight = 1.0]) {
        return new WeightPair<T>(item, _getInitialWeight(item, weight));
    }

    double _getInitialWeight(T item, double weight) {
        if (initialWeightSetter != null) {
            return initialWeightSetter!(item, weight);
        }
        return weight;
    }

    double _getWeight(WeightPair<T> pair) {
        return pair.weight;
    }

    @override
    String toString() => pairs.toString();

    @override
    Iterable<T> where(Predicate<T> test) => new WeightedWhereIterable<T>(this, test);

    @override
    Iterable<T> take(int count) => new WeightedTakeIterable<T>(this, count);

    @override
    Iterable<T> takeWhile(Predicate<T> test) => new WeightedTakeWhileIterable<T>(this, test);

    @override
    Iterable<U> map<U>(Mapping<T,U> mapping) => new WeightedMappedIterable<T,U>(this, mapping);

    @override
    List<T> toList({bool growable = true}) => new WeightedList<T>.from(this, growable: growable);
}

// seriously? ListMixin isn't a mixin? jeez guys get it together
// ignore: prefer_mixin
class WeightedList<T> extends WeightedIterable<T> with ListMixin<T> {

    late List<WeightPair<T>?> _list;

    WeightedList({int? length, WeightFunction<T>? initialWeightSetter}) {
        this.initialWeightSetter = initialWeightSetter;
        if (length == null) {
            this._list = <WeightPair<T>>[];
        } else {
            this._list = new List<WeightPair<T>?>.filled(length, null);
        }
    }

    factory WeightedList.from(Iterable<dynamic> other, {bool growable = true, WeightFunction<T>? initialWeightSetter, bool copyPairs = false}) {
        WeightedList<T> list;
        if (growable == true) {
            list = new WeightedList<T>(initialWeightSetter: initialWeightSetter)..length = other.length;
        } else {
            list = new WeightedList<T>(length: other.length, initialWeightSetter: initialWeightSetter);
        }
        if (other is Iterable<T>) {
            if (other is WeightedIterable<T>) {
                int i=0;
                for (final WeightPair<T> pair in other.pairs) {
                    if (copyPairs) {
                        list._list[i] = new WeightPair<T>.from(pair);
                    }else{
                        list._list[i] = pair;
                    }
                    i++;
                }
            } else {
                int i=0;
                for (final T item in other) {
                    list[i] = item;
                    i++;
                }
            }
        } else {
            int i=0;
            for (final dynamic entry in other) {
                if (entry is T) {
                    list[i] = entry;
                } else if (entry is WeightPair<T>) {
                    if (copyPairs) {
                        list._list[i] = new WeightPair<T>.from(entry);
                    } else {
                        list._list[i] = entry;
                    }
                } else {
                    throw Exception("Invalid entry type ${entry.runtimeType} for WeightedList<$T>. Should be $T or WeightPair<$T>.");
                }
                i++;
            }
        }
        return list;
    }

    factory WeightedList.fromMap(Map<T, double> mapping, {bool growable = true, WeightFunction<T>? initialWeightSetter}) {
        WeightedList<T> list;
        if (growable == true) {
            list = new WeightedList<T>(initialWeightSetter: initialWeightSetter)..length = mapping.length;
        } else {
            list = new WeightedList<T>(length: mapping.length, initialWeightSetter: initialWeightSetter);
        }

        int i=0;
        for (final T value in mapping.keys) {
            list.setPair(i, new WeightPair<T>(value, mapping[value]!));
            i++;
        }

        return list;
    }

    @override
    T get(double position) {
        final double totalWeight = getTotalWeight();

        final double weightPosition = position.clamp(0.0,1.0) * totalWeight;
        double runningTotal = 0.0;

        for (final WeightPair<T>? pair in _list) {
            if (pair == null) { continue; }
            runningTotal += _getWeight(pair);
            if (weightPosition <= runningTotal) {
                return pair.item;
            }
        }

        throw Exception("Somehow a weighted list ran out of weights. This shouldn't happen if it's filled correctly!");
    }

    WeightPair<T>? getPair(int index) {
        return _list[index];
    }

    void setPair(int index, WeightPair<T> pair) {
        _list[index] = pair;
    }

    /// Merges multiple pairs with the same item into single pairs with summed weight.
    ///
    /// WARNING: This will DISCARD any special conditional weightings!
    /// Resulting pairs will be static weights.
    void collateWeights() {
        final Map<T, double> totals = <T, double>{};

        for (final WeightPair<T>? pair in _list) {
            if (pair == null) { continue; }
            if (!totals.containsKey(pair.item)) {
                totals[pair.item] = 0.0;
            }

            totals[pair.item] = totals[pair.item]! + pair.weight;
        }

        _list.clear();
        this.addAllMap(totals);
    }

    void sortByWeight([bool descending = false]) {
        if (descending) {
            this._list.sort((WeightPair<T>? a, WeightPair<T>? b) => b!.weight.compareTo(a!.weight));
        } else {
            this._list.sort((WeightPair<T>? a, WeightPair<T>? b) => a!.weight.compareTo(b!.weight));
        }
    }

    @override
    Iterable<WeightPair<T>> get pairs => _list.whereType();

    // ##########################################
    // Add single

    @override
    void add(T element, [num weight = 1.0]) {
        _list.add(_createPair(element, weight.toDouble()));
    }

    void addPair(WeightPair<T> pair) {
        _list.add(pair);
    }

    void addConditional(T item, Generator<double> weightFunction) {
        this.addPair(new FunctionWeightPair<T>(item, weightFunction));
    }

    // ##########################################
    // Add multiple

    @override
    void addAll(Iterable<T> iterable) {
        if (iterable is WeightedList<T>) {
            _list.addAll(iterable.pairs);
        } else {
            _list.addAll(iterable.map(_createPair).cast());
        }
    }

    void addAllIterables(Iterable<T> items, Iterable<double> weights) {
        int index = _list.length;
        _list.length += items.length;

        final Iterator<T> item_iter = items.iterator;
        final Iterator<double> weight_iter = weights.iterator;

        while(item_iter.moveNext()) {
            final double weight = weight_iter.moveNext() ? weight_iter.current : 1.0;
            _list[index] = _createPair(item_iter.current, weight);
            index++;
        }
    }

    void addAllGenerative(Iterable<T> items, double Function(T input) generator) {
        _list.addAll(items.map((T item) => _createPair(item, generator(item))));
    }

    void addAllMap(Map<T, double> map) {
        this.addAllIterables(map.keys, map.values);
    }

    // ##########################################
    // overrides

    @override
    void retainWhere(Predicate<T> test) => _list.retainWhere((WeightPair<T>? pair) => test(pair!.item));

    @override
    void removeWhere(Predicate<T> test) => _list.removeWhere((WeightPair<T>? pair) => test(pair!.item));

    @override
    T operator [](int index) => _list[index]!.item;

    @override
    void operator []=(int index, T value){
        _list[index] = _createPair(value);
    }

    @override
    int get length => _list.length;

    @override
    set length(int val) => _list.length = val;

    @override
    String toString() => _list.toString();

    // it's bullshit that I have to re-override these but hey it's the simplest way...

    @override
    Iterable<T> where(Predicate<T> test) => new WeightedWhereIterable<T>(this, test);

    @override
    Iterable<T> take(int count) => new WeightedTakeIterable<T>(this, count);

    @override
    Iterable<T> takeWhile(Predicate<T> test) => new WeightedTakeWhileIterable<T>(this, test);

    @override
    Iterable<U> map<U>(Mapping<T,U> f) => new WeightedMappedIterable<T,U>(this, f);

    @override
    List<T> toList({bool growable = true}) => new WeightedList<T>.from(this, growable: growable);
}

class WeightPair<T> {
    T item;
    double weight;

    WeightPair(T this.item, double this.weight);

    factory WeightPair.from(WeightPair<T> other) {
        return new WeightPair<T>(other.item, other.weight);
    }

    @override
    String toString() => "($item @ $weight)";
}

class FunctionWeightPair<T> extends WeightPair<T> {
    Generator<double> weightFunction;

    FunctionWeightPair(T item, Generator<double> this.weightFunction) : super(item, weightFunction());

    @override
    double get weight => weightFunction();
}

// same here... why is the provided library mixin not using their own mixin syntax?
// ignore: prefer_mixin
abstract class WrappedWeightedIterable<T> extends WeightedIterable<T> with IterableMixin<T> {
    final Iterable<WeightPair<T>> source;

    WrappedWeightedIterable(Iterable<WeightPair<T>> this.source);

    @override
    Iterable<WeightPair<T>> get pairs => source;

    @override
    Iterator<T> get iterator => new WeightPairIterator<T>(this);

    @override
    int get length => source.length;

    // it's bullshit that I have to re-override these but hey it's the simplest way...

    @override
    String toString() => pairs.toString();

    @override
    Iterable<T> where(Predicate<T> f) => new WeightedWhereIterable<T>(this, f);

    @override
    Iterable<T> take(int count) => new WeightedTakeIterable<T>(this, count);

    @override
    Iterable<T> takeWhile(Predicate<T> test) => new WeightedTakeWhileIterable<T>(this, test);

    @override
    Iterable<U> map<U>(Mapping<T,U> f) => new WeightedMappedIterable<T,U>(this, f);

    @override
    List<T> toList({bool growable = true}) => new WeightedList<T>.from(this, growable: growable);
}

class WeightPairIterator<T> extends Iterator<T> {
    late Iterator<WeightPair<T>> _iter;

    WeightPairIterator(WeightedIterable<T> iterable) {
        this._iter = iterable.pairs.iterator;
    }

    @override
    T get current => _iter.current.item;

    @override
    bool moveNext() => _iter.moveNext();
}

class WeightedWhereIterable<T> extends WrappedWeightedIterable<T> {
    WeightedWhereIterable(WeightedIterable<T> source, Predicate<T> predicate):super(source.pairs.where((WeightPair<T> pair) => predicate(pair.item)));
}

class WeightedTakeIterable<T> extends WrappedWeightedIterable<T> {
    WeightedTakeIterable(WeightedIterable<T> source, int count):super(source.pairs.take(count));
}

class WeightedTakeWhileIterable<T> extends WrappedWeightedIterable<T> {
    WeightedTakeWhileIterable(WeightedIterable<T> source, Predicate<T> predicate):super(source.pairs.takeWhile((WeightPair<T> pair) => predicate(pair.item)));
}

class WeightedMappedIterable<T, U> extends WrappedWeightedIterable<U> {
    WeightedMappedIterable(WeightedIterable<T> source, Mapping<T, U> mapping) :super(source.pairs.map((WeightPair<T> pair) => new WeightPair<U>(mapping(pair.item), pair.weight)));
}

class SubTypeWeightedIterable<T extends U, U> extends WrappedWeightedIterable<T> {
    SubTypeWeightedIterable(Iterable<WeightPair<U>> source) : super(source.where((WeightPair<U> pair) => pair.item is T).map((WeightPair<U> pair) {
        // ignore: avoid_as
        return new WeightPair<T>(pair.item as T, pair.weight);
    }));
}


