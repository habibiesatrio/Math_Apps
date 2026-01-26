// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// The current system encoding.
///
/// This is used for converting from bytes to and from Strings when
/// communicating on stdin, stdout and stderr.
///
/// On Windows this will use the currently active code page for the conversion.
/// On all other systems it will always use UTF-8.
const SystemEncoding systemEncoding = SystemEncoding();

/// The system encoding is the current code page on Windows and UTF-8 on Linux
/// and Mac.
final class SystemEncoding extends Encoding {
  /// Creates a const SystemEncoding.
  ///
  /// Users should use the top-level constant, [systemEncoding].
  const SystemEncoding();

  @override
  String get name => 'system';

  @override
  List<int> encode(String input) => encoder.convert(input);
  @override
  String decode(List<int> encoded) => decoder.convert(encoded);

  @override
  Converter<String, List<int>> get encoder {
    if (Platform.operatingSystem == "windows") {
      return const _WindowsCodePageEncoder();
    } else {
      return const Utf8Encoder();
    }
  }

  @override
  Converter<List<int>, String> get decoder {
    if (Platform.operatingSystem == "windows") {
      return const _WindowsCodePageDecoder();
    } else {
      return const Utf8Decoder();
    }
  }
}

class _WindowsCodePageEncoder extends Converter<String, List<int>> {
  const _WindowsCodePageEncoder();

  @override
  List<int> convert(String input) {
    List<int> encoded = _encodeString(input);
    return encoded;
  }

  /// Starts a chunked conversion.
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    return _WindowsCodePageEncoderSink(sink);
  }

  external static List<int> _encodeString(String string);
}

class _WindowsCodePageEncoderSink extends StringConversionSink {
  // TODO(floitsch): provide more efficient conversions when the input is
  // not a String.

  final Sink<List<int>> _sink;

  _WindowsCodePageEncoderSink(this._sink);

  @override
  void close() {
    _sink.close();
  }

  @override
  void add(String string) {
    List<int> encoded = _WindowsCodePageEncoder._encodeString(string);
    _sink.add(encoded);
  }

  @override
  void addSlice(String source, int start, int end, bool isLast) {
    if (start != 0 || end != source.length) {
      source = source.substring(start, end);
    }
    add(source);
    if (isLast) close();
  }
}

class _WindowsCodePageDecoder extends Converter<List<int>, String> {
  const _WindowsCodePageDecoder();

  @override
  String convert(List<int> input) {
    return _decodeBytes(input);
  }

  /// Starts a chunked conversion.
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    return _WindowsCodePageDecoderSink(sink);
  }

  external static String _decodeBytes(List<int> bytes);
}

class _WindowsCodePageDecoderSink extends ByteConversionSink {
  // TODO(floitsch): provide more efficient conversions when the input is
  // a slice.

  final Sink<String> _sink;

  _WindowsCodePageDecoderSink(this._sink);

  @override
  void close() {
    _sink.close();
  }

  @override
  void add(List<int> bytes) {
    _sink.add(_WindowsCodePageDecoder._decodeBytes(bytes));
  }
}
