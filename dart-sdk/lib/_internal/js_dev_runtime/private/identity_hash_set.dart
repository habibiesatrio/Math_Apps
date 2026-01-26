// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

base class IdentitySet<E> extends InternalSet<E> {
  /// The backing store for this set.
  @override
  @notNull
  final _map = JS('', 'new Set()');

  @override
  @notNull
  int _modifications = 0;

  IdentitySet();

  @override
  Set<E> _newSet() => IdentitySet<E>();

  @override
  Set<R> _newSimilarSet<R>() => IdentitySet<R>();

  @override
  bool contains(Object? element) {
    return JS<bool>('!', '#.has(#)', _map, element);
  }

  @override
  E? lookup(Object? element) {
    return element is E && JS<bool>('!', '#.has(#)', _map, element)
        ? element
        : null;
  }

  @override
  bool add(E element) {
    var map = _map;
    if (JS<bool>('!', '#.has(#)', map, element)) return false;
    JS('', '#.add(#)', map, element);
    _modifications = (_modifications + 1) & 0x3fffffff;
    return true;
  }

  @override
  void addAll(Iterable<E> objects) {
    var map = _map;
    int length = JS('', '#.size', map);
    for (E key in objects) {
      JS('', '#.add(#)', map, key);
    }
    if (length != JS<int>('!', '#.size', map)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }

  @override
  bool remove(Object? element) {
    if (JS<bool>('!', '#.delete(#)', _map, element)) {
      _modifications = (_modifications + 1) & 0x3fffffff;
      return true;
    }
    return false;
  }

  @override
  void clear() {
    var map = _map;
    if (JS<int>('!', '#.size', map) > 0) {
      JS('', '#.clear()', map);
      _modifications = (_modifications + 1) & 0x3fffffff;
    }
  }
}
