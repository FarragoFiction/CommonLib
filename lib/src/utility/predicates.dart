
/// A function which takes an object, returns a bool.
///
/// Technically a specialised [Mapping].
typedef Predicate<T> = bool Function(T object);
/// A function which takes an object and returns nothing.
typedef Lambda<T> = void Function(T object);
/// A function which takes an object and returns an object of another type.
typedef Mapping<T,U> = U Function(T object);
/// A function which takes two objects and combines them into one.
typedef Combiner<T> = T Function(T first, T second);
/// A function which has no inputs and returns an object.
typedef Generator<T> = T Function();
/// A function which has no inputs and returns nothing.
typedef Action = void Function();

/// A two-type pair.
class Tuple<T,U> {
    T first;
    U second;
    Tuple(T this.first, U this.second);

    @override
    String toString() => "[$first, $second]";
}
