
/// A function which takes an object, returns a bool.
///
/// Technically a specialised [Transformer].
typedef bool Predicate<T>(T object);
/// A function which takes an object and returns nothing.
typedef void Lambda<T>(T object);
/// A function which takes an object and returns an object of another type.
typedef U Transformer<T,U>(T object);
/// A function which takes two objects and combines them into one.
typedef T Combiner<T>(T first, T second);
/// A function which has no inputs and returns an object.
typedef T Generator<T>();
/// A function which has no inputs and returns nothing.
typedef void Action();

/// A two-type pair.
class Tuple<T,U> {
    T first;
    U second;
    Tuple(T this.first, U this.second);

    @override
    String toString() => "[$first, $second]";
}