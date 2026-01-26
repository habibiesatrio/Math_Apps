// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._interceptors;

/// Holds cached RTI objects for JS Array instances.
final _arrayRtiSymbol = JS<Object>('', 'Symbol("arrayRti")');

/// The interceptor class for [List]. The compiler recognizes this
/// class as an interceptor, and changes references to [:this:] to
/// actually use the receiver of the method, which is generated as an extra
/// argument added to each member.
@JsPeerInterface(name: 'Array')
class JSArray<E> extends JavaScriptObject
    implements List<E>, JSIndexable<E>, TrustedGetRuntimeType {
  const JSArray();

  /// Constructor for adding type parameters to an existing JavaScript
  /// Array. Used for creating literal lists.
  factory JSArray.of(@notNull Object list) {
    // TODO(sra): Move this to core.List for better readability.
    JS('', '#.# = #', list, _arrayRtiSymbol, JS_RTI_PARAMETER());
    return JS('-dynamic', '#', list);
  }

  // TODO(jmesserly): consider a fixed array subclass instead.
  factory JSArray.fixed(@notNull Object list) {
    JS('', r'#.fixed$length = Array', list);
    JS('', '#.# = #', list, _arrayRtiSymbol, JS_RTI_PARAMETER());
    return JS('-dynamic', '#', list);
  }

  factory JSArray.unmodifiable(@notNull Object list) {
    JS('', r'#.fixed$length = Array', list);
    JS('', r'#.immutable$list = Array', list);
    JS('', '#.# = #', list, _arrayRtiSymbol, JS_RTI_PARAMETER());
    return JS('-dynamic', '#', list);
  }

  /// Provides the Rti object for this.
  ///
  /// Default-initialized to JSArray<dynamic>.
  /// Only intended for use by the dart:_rti library.
  ///
  /// NOTE: The name of this getter is directly tied to the result of compiling
  /// `JS_EMBEDDED_GLOBAL('', ARRAY_RTI_PROPERTY)`.
  Object get arrayRti => JS<Object>(
    '',
    '#.# || #',
    this,
    _arrayRtiSymbol,
    TYPE_REF<JSArray<dynamic>>(),
  );

  /// Unsupported action, only provided here to help diagnosis of an accidental
  /// attempt to set the value manually.
  ///
  /// NOTE: The name of this setter is directly tied to the result of compiling
  /// `JS_EMBEDDED_GLOBAL('', ARRAY_RTI_PROPERTY)`.
  set arrayRti(_) =>
      throw UnsupportedError('Setting arrayRti is not supported in DDC.');

  static void markFixedList(list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('', r'#.fixed$length = Array', list);
  }

  static void markUnmodifiableList(list) {
    // Functions are stored in the hidden class and not as properties in
    // the object. We never actually look at the value, but only want
    // to know if the property exists.
    JS('', r'#.fixed$length = Array', list);
    JS('', r'#.immutable$list = Array', list);
  }

  checkMutable(reason) {
    if (JS<bool>('!', r'#.immutable$list', this)) {
      throw UnsupportedError(reason);
    }
  }

  checkGrowable(reason) {
    if (JS<bool>('!', r'#.fixed$length', this)) {
      throw UnsupportedError(reason);
    }
  }

  @override
  List<R> cast<R>() => List.castFrom<E, R>(this);
  @override
  void add(E value) {
    checkGrowable('add');
    JS('void', r'#.push(#)', this, value);
  }

  @override
  E removeAt(@nullCheck int index) {
    checkGrowable('removeAt');
    if (index < 0 || index >= length) {
      throw RangeError.value(index);
    }
    return JS('-dynamic', r'#.splice(#, 1)[0]', this, index);
  }

  @override
  void insert(@nullCheck int index, E value) {
    checkGrowable('insert');
    if (index < 0 || index > length) {
      throw RangeError.value(index);
    }
    JS('void', r'#.splice(#, 0, #)', this, index, value);
  }

  @override
  void insertAll(@nullCheck int index, Iterable<E> iterable) {
    checkGrowable('insertAll');
    RangeError.checkValueInInterval(index, 0, length, "index");
    if (iterable is! EfficientLengthIterable) {
      iterable = iterable.toList();
    }
    @nullCheck
    int insertionLength = iterable.length;
    _setLengthUnsafe(length + insertionLength);
    int end = index + insertionLength;
    setRange(end, length, this, index);
    setRange(index, end, iterable);
  }

  @override
  void setAll(@nullCheck int index, Iterable<E> iterable) {
    checkMutable('setAll');
    RangeError.checkValueInInterval(index, 0, length, "index");
    for (var element in iterable) {
      this[index++] = element;
    }
  }

  @override
  E removeLast() {
    checkGrowable('removeLast');
    if (length == 0) throw diagnoseIndexError(this, -1);
    return JS('var', r'#.pop()', this);
  }

  @override
  bool remove(Object? element) {
    checkGrowable('remove');
    var length = this.length;
    for (int i = 0; i < length; i++) {
      if (this[i] == element) {
        JS('var', r'#.splice(#, 1)', this, i);
        return true;
      }
    }
    return false;
  }

  /// Removes elements matching [test] from this [JSArray].
  @override
  void removeWhere(bool Function(E) test) {
    checkGrowable('removeWhere');
    _removeWhere(test, true);
  }

  @override
  void retainWhere(bool Function(E) test) {
    checkGrowable('retainWhere');
    _removeWhere(test, false);
  }

  void _removeWhere(bool Function(E) test, bool removeMatching) {
    // Performed in two steps, to avoid exposing an inconsistent state
    // to the [test] function. First the elements to retain are found, and then
    // the original list is updated to contain those elements.

    // TODO(sra): Replace this algorithm with one that retains a list of ranges
    // to be removed.  Most real uses remove 0, 1 or a few clustered elements.

    List retained = [];
    int end = this.length;
    for (int i = 0; i < end; i++) {
      var element = JS<E>('', '#[#]', this, i);
      // !test() ensures bool conversion in checked mode.
      if (!test(element) == removeMatching) {
        // Unsafe add here to avoid extra casts and growable checks enforced by
        // the exposed add method.
        JS('', '#.push(#)', retained, element);
      }
      if (this.length != end) throw ConcurrentModificationError(this);
    }
    if (retained.length == end) return;
    this.length = retained.length;
    @nullCheck
    var length = retained.length;
    for (int i = 0; i < length; i++) {
      JS('', '#[#] = #[#]', this, i, retained, i);
    }
  }

  @override
  Iterable<E> where(bool Function(E) f) {
    return WhereIterable<E>(this, f);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) {
    return ExpandIterable<E, T>(this, f);
  }

  @override
  void addAll(Iterable<E> collection) {
    int i = length;
    checkGrowable('addAll');
    for (E e in collection) {
      assert(i == length || (throw ConcurrentModificationError(this)));
      i++;
      JS('void', r'#.push(#)', this, e);
    }
  }

  @override
  void clear() {
    length = 0;
  }

  @override
  void forEach(void Function(E) f) {
    int end = length;
    for (int i = 0; i < end; i++) {
      var element = JS<E>('', '#[#]', this, i);
      f(element);
      if (length != end) throw ConcurrentModificationError(this);
    }
  }

  @override
  Iterable<T> map<T>(T Function(E) f) {
    return MappedListIterable<E, T>(this, f);
  }

  @override
  String join([String separator = ""]) {
    var length = this.length;
    var list = List<String>.filled(length, "");
    for (int i = 0; i < length; i++) {
      list[i] = "${this[i]}";
    }
    return JS<String>('!', "#.join(#)", list, separator);
  }

  @override
  Iterable<E> take(int n) {
    return SubListIterable<E>(this, 0, checkNotNullable(n, "count"));
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    return TakeWhileIterable<E>(this, test);
  }

  @override
  Iterable<E> skip(int n) {
    return SubListIterable<E>(this, n, null);
  }

  @override
  Iterable<E> skipWhile(bool Function(E) test) {
    return SkipWhileIterable<E>(this, test);
  }

  @override
  E reduce(E Function(E previousValue, E element) combine) {
    int length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    E value = this[0];
    for (int i = 1; i < length; i++) {
      var element = JS<E>('', '#[#]', this, i);
      value = combine(value, element);
      if (length != this.length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    var value = initialValue;
    int length = this.length;
    for (int i = 0; i < length; i++) {
      var element = JS<E>('', '#[#]', this, i);
      value = combine(value, element);
      if (this.length != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) {
    int end = length;
    for (int i = 0; i < end; ++i) {
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return element;
      if (length != end) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) {
    int length = this.length;
    for (int i = length - 1; i >= 0; i--) {
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return element;
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) {
    int length = this.length;
    E? match;
    bool matchFound = false;
    for (int i = 0; i < length; i++) {
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (length != this.length) {
        throw ConcurrentModificationError(this);
      }
    }
    if (matchFound) return match as E;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  E elementAt(int index) {
    return this[index];
  }

  @override
  List<E> sublist(@nullCheck int start, [int? end]) {
    if (start < 0 || start > length) {
      throw RangeError.range(start, 0, length, "start");
    }
    if (end == null) {
      end = length;
    } else {
      @notNull
      var end0 = end;
      if (end0 < start || end0 > length) {
        throw RangeError.range(end, start, length, "end");
      }
    }
    if (start == end) return <E>[];
    return JSArray<E>.of(JS('', r'#.slice(#, #)', this, start, end));
  }

  @override
  Iterable<E> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    return SubListIterable<E>(this, start, end);
  }

  @override
  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  @override
  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  @override
  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  @override
  void removeRange(@nullCheck int start, @nullCheck int end) {
    checkGrowable('removeRange');
    RangeError.checkValidRange(start, end, length);
    int deleteCount = end - start;
    JS('', '#.splice(#, #)', this, start, deleteCount);
  }

  @override
  void setRange(
    @nullCheck int start,
    @nullCheck int end,
    Iterable<E> iterable, [
    @nullCheck int skipCount = 0,
  ]) {
    checkMutable('set range');

    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");

    var otherList = <E>[];
    int otherStart = 0;
    // TODO(floitsch): Make this accept more.
    if (iterable is List<E>) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + length > otherList.length) {
      throw IterableElementError.tooFew();
    }
    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      // TODO(sra): If [from] is the same Array as [this], we can copy without
      // type annotation checks on the stores.
      for (int i = length - 1; i >= 0; i--) {
        // Use JS to avoid bounds check (the bounds check elimination
        // optimization is too weak). The 'E' type annotation is a store type
        // check - we can't rely on iterable, it could be List<dynamic>.
        var element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    } else {
      for (int i = 0; i < length; i++) {
        var element = otherList[otherStart + i];
        JS('', '#[#] = #', this, start + i, element);
      }
    }
  }

  @override
  void fillRange(@nullCheck int start, @nullCheck int end, [E? fillValue]) {
    checkMutable('fill range');
    RangeError.checkValidRange(start, end, length);
    E checkedFillValue = fillValue as E;
    for (int i = start; i < end; i++) {
      JS('', '#[#] = #', this, i, checkedFillValue);
    }
  }

  @override
  void replaceRange(
    @nullCheck int start,
    @nullCheck int end,
    Iterable<E> replacement,
  ) {
    checkGrowable('replace range');
    RangeError.checkValidRange(start, end, length);
    if (replacement is! EfficientLengthIterable) {
      replacement = replacement.toList();
    }
    int removeLength = end - start;
    @nullCheck
    int insertLength = replacement.length;
    if (removeLength >= insertLength) {
      int delta = removeLength - insertLength;
      int insertEnd = start + insertLength;
      int newLength = length - delta;
      setRange(start, insertEnd, replacement);
      if (delta != 0) {
        setRange(insertEnd, newLength, this, end);
        length = newLength;
      }
    } else {
      int delta = insertLength - removeLength;
      int newLength = length + delta;
      int insertEnd = start + insertLength; // aka. end + delta.
      _setLengthUnsafe(newLength);
      setRange(insertEnd, newLength, this, end);
      setRange(start, insertEnd, replacement);
    }
  }

  @override
  bool any(bool Function(E) test) {
    int end = length;
    for (int i = 0; i < end; i++) {
      var element = JS<E>('', '#[#]', this, i);
      if (test(element)) return true;
      if (length != end) throw ConcurrentModificationError(this);
    }
    return false;
  }

  @override
  bool every(bool Function(E) test) {
    int end = length;
    for (int i = 0; i < end; i++) {
      var element = JS<E>('', '#[#]', this, i);
      if (!test(element)) return false;
      if (length != end) throw ConcurrentModificationError(this);
    }
    return true;
  }

  @override
  Iterable<E> get reversed => ReversedListIterable<E>(this);

  @override
  void sort([int Function(E, E)? compare]) {
    checkMutable('sort');
    if (compare == null) {
      Sort.sort(
        this,
        (a, b) => Comparable.compare(a as Comparable, b as Comparable),
      );
    } else {
      Sort.sort(this, compare);
    }
  }

  @override
  void shuffle([Random? random]) {
    checkMutable('shuffle');
    random ??= Random();
    int length = this.length;
    while (length > 1) {
      int pos = random.nextInt(length);
      length -= 1;
      var tmp = this[length];
      this[length] = this[pos];
      this[pos] = tmp;
    }
  }

  @override
  int indexOf(Object? element, [@nullCheck int start = 0]) {
    int length = this.length;
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (int i = start; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  int lastIndexOf(Object? element, [int? startIndex]) {
    @notNull
    int start = startIndex ?? length - 1;
    if (start >= length) {
      start = length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  bool contains(Object? other) {
    var length = this.length;
    for (int i = 0; i < length; i++) {
      var element = JS<E>('', '#[#]', this, i);
      if (element == other) return true;
    }
    return false;
  }

  @override
  @notNull
  bool get isEmpty => length == 0;

  @override
  @notNull
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => ListBase.listToString(this);

  @override
  List<E> toList({@nullCheck bool growable = true}) {
    var list = JS<Object>('', '#.slice()', this);
    if (!growable) markFixedList(list);
    return JSArray<E>.of(list);
  }

  @override
  Set<E> toSet() => Set<E>.from(this);

  @override
  Iterator<E> get iterator => ArrayIterator<E>(this);

  @override
  int get hashCode => identityHashCode(this);

  @override
  @notNull
  bool operator ==(other) => identical(this, other);

  @override
  @notNull
  int get length => JS<int>('!', r'#.length', this);

  @override
  set length(@nullCheck int newLength) {
    checkGrowable('set length');
    // TODO(sra): Remove this test and let JavaScript throw an error.
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, null, 'newLength');
    }

    // Verify that element type is nullable.
    if (newLength > length) null as E;

    // JavaScript with throw a RangeError for numbers that are too big. The
    // message does not contain the value.
    JS('void', r'#.length = #', this, newLength);
  }

  /// Unsafe alternative to the [length] setter that skips the check and will
  /// not fail when increasing the size of a list of non-nullable elements.
  ///
  /// To ensure null safe soundness this should only be called when every new
  /// index will be filled before returning.
  ///
  /// Should only be called when the list is already known to be growable.
  void _setLengthUnsafe(int newLength) {
    // TODO(sra): Remove this test and let JavaScript throw an error.
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, null, 'newLength');
    }
    // JavaScript with throw a RangeError for numbers that are too big. The
    // message does not contain the value.
    JS('void', r'#.length = #', this, newLength);
  }

  @override
  E operator [](int index) {
    // Suppress redundant null checks via JS.
    if (JS<bool>('!', '!(# >= 0 && # < #.length)', index, index, this)) {
      throw diagnoseIndexError(this, index);
    }
    return JS<E>('', '#[#]', this, index);
  }

  @override
  void operator []=(int index, E value) {
    checkMutable('indexed set');
    if (JS<bool>('!', '!(# >= 0 && # < #.length)', index, index, this)) {
      throw diagnoseIndexError(this, index);
    }
    JS('void', r'#[#] = #', this, index, value);
  }

  @override
  Map<int, E> asMap() {
    return ListMapView<E>(this);
  }

  @override
  Type get runtimeType => List<E>;

  @override
  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  @override
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  @override
  List<E> operator +(List<E> other) => [...this, ...other];

  @override
  int indexWhere(bool Function(E) test, [int start = 0]) {
    if (start >= length) return -1;
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  @override
  int lastIndexWhere(bool Function(E) test, [int? start]) {
    start ??= length - 1;
    if (start < 0) return -1;
    for (int i = start; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  @override
  set first(E element) {
    if (isEmpty) throw IndexError.withLength(0, length, indexable: this);
    this[0] = element;
  }

  @override
  set last(E element) {
    if (isEmpty) throw IndexError.withLength(0, length, indexable: this);
    this[length - 1] = element;
  }
}

/// Dummy subclasses that allow the backend to track more precise
/// information about arrays through their type. The CPA type inference
/// relies on the fact that these classes do not override [] nor []=.
///
/// These classes are really a fiction, and can have no methods, since
/// getInterceptor always returns JSArray.  We should consider pushing the
/// 'isGrowable' and 'isMutable' checks into the getInterceptor implementation
/// so these classes can have specialized implementations. Doing so will
/// challenge many assumptions in the JS backend.
abstract class JSMutableArray<E> extends JSArray<E>
    implements JSMutableIndexable<E> {}

final class JSFixedArray<E> extends JSMutableArray<E> {}

final class JSExtendableArray<E> extends JSMutableArray<E> {}

final class JSUnmodifiableArray<E>
    extends JSArray<E> {} // Already is JSIndexable.

/// An [Iterator] that iterates a JSArray.
///
class ArrayIterator<E> implements Iterator<E> {
  final JSArray<E> _iterable;
  @notNull
  final int _length;
  @notNull
  int _index;
  E? _current;

  ArrayIterator(JSArray<E> iterable)
    : _iterable = iterable,
      _length = iterable.length,
      _index = 0;

  @override
  E get current => _current as E;

  @override
  bool moveNext() {
    @notNull
    int length = _iterable.length;

    // We have to do the length check even on fixed length Arrays.  If we can
    // inline moveNext() we might be able to GVN the length and eliminate this
    // check on known fixed length JSArray.
    if (_length != length) {
      throw throwConcurrentModificationError(_iterable);
    }

    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable[_index];
    _index++;
    return true;
  }
}
