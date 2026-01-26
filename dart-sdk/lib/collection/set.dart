// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base implementations of [Set].
part of dart.collection;

/// Base implementation of [Set].
///
/// This class provides a base implementation of a `Set` that depends only
/// on the abstract members: [add], [contains], [lookup], [remove],
/// [iterator], [length] and [toSet].
///
/// Some of the methods assume that `toSet` creates a modifiable set.
/// If using this base class for an unmodifiable set,
/// where `toSet` should return an unmodifiable set,
/// it's necessary to reimplement
/// [retainAll], [union], [intersection] and [difference].
///
/// Implementations of `Set` using this base should consider also implementing
/// `clear` in constant time. The default implementation works by removing every
/// element.
abstract mixin class SetBase<E> implements Set<E> {
  // This class reimplements all of [IterableMixin].
  // If/when Dart mixins get more powerful, we should just create a single
  // Mixin class from IterableMixin and the new methods of this class.
  const SetBase();

  @override
  bool add(E value);

  @override
  bool contains(Object? element);

  @override
  E? lookup(Object? element);

  @override
  bool remove(Object? value);

  @override
  Iterator<E> get iterator;

  @override
  Set<E> toSet();

  @override
  int get length;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  @override
  Set<R> cast<R>() => Set.castFrom<E, R>(this);
  @override
  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  @override
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  @override
  void clear() {
    removeAll(toList());
  }

  @override
  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      add(element);
    }
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      remove(element);
    }
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    // Create a copy of the set, remove all of elements from the copy,
    // then remove all remaining elements in copy from this.
    Set<E> toRemove = toSet();
    for (Object? o in elements) {
      toRemove.remove(o);
    }
    removeAll(toRemove);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  @override
  void retainWhere(bool Function(E element) test) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (!test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  @override
  bool containsAll(Iterable<Object?> other) {
    for (var o in other) {
      if (!contains(o)) return false;
    }
    return true;
  }

  @override
  Set<E> union(Set<E> other) {
    return toSet()..addAll(other);
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (!other.contains(element)) result.remove(element);
    }
    return result;
  }

  @override
  Set<E> difference(Set<Object?> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (other.contains(element)) result.remove(element);
    }
    return result;
  }

  @override
  List<E> toList({bool growable = true}) =>
      List<E>.of(this, growable: growable);

  @override
  Iterable<T> map<T>(T Function(E element) f) =>
      EfficientLengthMappedIterable<E, T>(this, f);

  @override
  E get single {
    if (length > 1) throw IterableElementError.tooMany();
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    return result;
  }

  @override
  String toString() => setToString(this);

  // Copied from Iterable.
  // Should be inherited if we had multi-level mixins.

  @override
  Iterable<E> where(bool Function(E element) f) => WhereIterable<E>(this, f);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      ExpandIterable<E, T>(this, f);

  @override
  void forEach(void Function(E element) f) {
    for (E element in this) {
      f(element);
    }
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    var value = initialValue;
    for (E element in this) {
      value = combine(value, element);
    }
    return value;
  }

  @override
  bool every(bool Function(E element) f) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  @override
  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    var first = iterator.current.toString();
    if (!iterator.moveNext()) return first;
    var buffer = StringBuffer(first);
    // TODO(51681): Drop null check when de-supporting pre-2.12 code.
    if (separator.isEmpty) {
      do {
        buffer.write(iterator.current);
      } while (iterator.moveNext());
    } else {
      do {
        buffer
          ..write(separator)
          ..write(iterator.current);
      } while (iterator.moveNext());
    }
    return buffer.toString();
  }

  @override
  bool any(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  @override
  Iterable<E> take(int n) {
    return TakeIterable<E>(this, n);
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    return TakeWhileIterable<E>(this, test);
  }

  @override
  Iterable<E> skip(int n) {
    return SkipIterable<E>(this, n);
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) {
    return SkipWhileIterable<E>(this, test);
  }

  @override
  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  @override
  E get last {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = it.current;
    } while (it.moveNext());
    return result;
  }

  @override
  E firstWhere(bool Function(E value) test, {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  E lastWhere(bool Function(E value) test, {E Function()? orElse}) {
    var iterator = this.iterator;
    E result;
    do {
      if (!iterator.moveNext()) {
        if (orElse != null) return orElse();
        throw IterableElementError.noElement();
      }
      result = iterator.current;
    } while (!test(result));
    while (iterator.moveNext()) {
      var current = iterator.current;
      if (test(current)) result = current;
    }
    return result;
  }

  @override
  E singleWhere(bool Function(E value) test, {E Function()? orElse}) {
    var iterator = this.iterator;
    E result;
    do {
      if (!iterator.moveNext()) {
        if (orElse != null) return orElse();
        throw IterableElementError.noElement();
      }
      result = iterator.current;
    } while (!test(result));
    while (iterator.moveNext()) {
      if (test(iterator.current)) throw IterableElementError.tooMany();
    }
    return result;
  }

  @override
  E elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    var iterator = this.iterator;
    var skipCount = index;
    while (iterator.moveNext()) {
      if (skipCount == 0) return iterator.current;
      skipCount--;
    }
    throw IndexError.withLength(
      index,
      index - skipCount,
      indexable: this,
      name: "index",
    );
  }

  /// Converts a [Set] to a [String].
  ///
  /// Converts [set] to a string by converting each element to a string (by
  /// calling [Object.toString]), joining them with ", ", and wrapping the
  /// result in "{" and "}".
  ///
  /// Handles circular references where converting one of the elements
  /// to a string ends up converting [set] to a string again.
  static String setToString(Set set) =>
      IterableBase.iterableToFullString(set, '{', '}');
}

/// Mixin implementation of [Set].
///
/// This class provides a base implementation of a `Set` that depends only
/// on the abstract members: [add], [contains], [lookup], [remove],
/// [iterator], [length] and [toSet].
///
/// Some of the methods assume that `toSet` creates a modifiable set.
/// If using this mixin for an unmodifiable set,
/// where `toSet` should return an unmodifiable set,
/// it's necessary to reimplement
/// [retainAll], [union], [intersection] and [difference].
///
/// Implementations of `Set` using this mixin should consider also implementing
/// `clear` in constant time. The default implementation works by removing every
/// element.
// TODO: @Deprecated("Use SetBase instead")
// Longer term: Deprecate `Set` unnamed constructor, to allow using `Set`
// as skeleton class and replace `SetBase`.
typedef SetMixin<E> = SetBase<E>;

/// Common internal implementation of some [Set] methods.
abstract class _SetBase<E> extends SetBase<E> {
  // The following two methods override the ones in SetBase.
  // It's possible to be more efficient if we have a way to create an empty
  // set of the correct type.
  const _SetBase();

  Set<E> _newSet();

  Set<R> _newSimilarSet<R>();

  @override
  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSimilarSet);

  @override
  Set<E> difference(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  // Subclasses can optimize this further.
  @override
  Set<E> toSet() => _newSet()..addAll(this);
}

mixin _UnmodifiableSetMixin<E> implements Set<E> {
  static Never _throwUnmodifiable() {
    throw UnsupportedError("Cannot change an unmodifiable set");
  }

  /// This operation is not supported by an unmodifiable set.
  @override
  bool add(E value) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void clear() => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void addAll(Iterable<E> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void removeAll(Iterable<Object?> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void retainAll(Iterable<Object?> elements) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void removeWhere(bool Function(E element) test) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  void retainWhere(bool Function(E element) test) => _throwUnmodifiable();

  /// This operation is not supported by an unmodifiable set.
  @override
  bool remove(Object? value) => _throwUnmodifiable();
}

/// Class used to implement const sets.
class _UnmodifiableSet<E> extends _SetBase<E> with _UnmodifiableSetMixin<E> {
  final Map<E, void> _map;

  const _UnmodifiableSet(this._map);

  @override
  Set<E> _newSet() => LinkedHashSet<E>();

  @override
  Set<R> _newSimilarSet<R>() => LinkedHashSet<R>();

  // Lookups use map methods.

  @override
  bool contains(Object? element) => _map.containsKey(element);

  @override
  Iterator<E> get iterator => _map.keys.iterator;

  @override
  int get length => _map.length;

  @override
  E? lookup(Object? element) {
    for (var key in _map.keys) {
      if (key == element) return key;
    }
    return null;
  }
}

/// An unmodifiable [Set] view of another [Set].
///
/// Methods that could change the set, such as [add] and [remove],
/// must not be called.
///
/// ```dart
/// final baseSet = <String>{'Mars', 'Mercury', 'Earth', 'Venus'};
/// final unmodifiableSetView = UnmodifiableSetView(baseSet);
///
/// // Remove an element from the original set.
/// baseSet.remove('Venus');
/// print(unmodifiableSetView); // {Mars, Mercury, Earth}
///
/// unmodifiableSetView.remove('Earth'); // Throws.
/// ```
class UnmodifiableSetView<E> extends SetBase<E> with _UnmodifiableSetMixin<E> {
  final Set<E> _source;

  /// Creates an [UnmodifiableSetView] of [source].
  UnmodifiableSetView(Set<E> source) : _source = source;

  @override
  bool contains(Object? element) => _source.contains(element);

  @override
  E? lookup(Object? element) => _source.lookup(element);

  @override
  int get length => _source.length;

  @override
  Iterator<E> get iterator => _source.iterator;

  @override
  Set<E> toSet() => _source.toSet();
}
