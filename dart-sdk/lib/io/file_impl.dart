// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Read the file in blocks of size 64k.
const int _blockSize = 64 * 1024;

// The maximum number of bytes to read in a single call to `read`.
//
// On Windows and macOS, it is an error to call
// `read/_read(fildes, buf, nbyte)` with `nbyte >= INT_MAX`.
//
// The POSIX specification states that the behavior of `read` is
// implementation-defined if `nbyte > SSIZE_MAX`. On Linux, the `read` will
// transfer at most 0x7ffff000 bytes and return the number of bytes actually.
// transfered.
//
// A smaller value has the advantage of:
// 1. making vm-service clients (e.g. debugger) more responsive
// 2. reducing memory overhead (since `readInto` copies memory)
//
// A bigger value reduces the number of system calls.
const int _maxReadSize = 16 * 1024 * 1024; // 16MB.

class _FileStream extends Stream<List<int>> {
  // Stream controller.
  late StreamController<Uint8List> _controller;

  // Information about the underlying file.
  String? _path;
  RandomAccessFile? _openedFile;
  int _position;
  int? _end;
  final Completer _closeCompleter = Completer();

  // Has the stream been paused or unsubscribed?
  bool _unsubscribed = false;

  // Is there a read currently in progress?
  bool _readInProgress = true;
  bool _closed = false;

  bool _atEnd = false;

  _FileStream(this._path, int? position, this._end) : _position = position ?? 0;

  _FileStream.forStdin() : _position = 0;

  _FileStream.forRandomAccessFile(RandomAccessFile f)
    : _position = 0,
      _openedFile = f;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _controller = StreamController<Uint8List>(
      sync: true,
      onListen: _start,
      onResume: _readBlock,
      onCancel: () {
        _unsubscribed = true;
        return _closeFile();
      },
    );
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future _closeFile() {
    if (_readInProgress || _closed) {
      return _closeCompleter.future;
    }
    _closed = true;

    void done() {
      _closeCompleter.complete();
      _controller.close();
    }

    _openedFile!.close().catchError(_controller.addError).whenComplete(done);
    return _closeCompleter.future;
  }

  void _readBlock() {
    // Don't start a new read if one is already in progress.
    if (_readInProgress) return;
    if (_atEnd) {
      _closeFile();
      return;
    }
    _readInProgress = true;
    int readBytes = _blockSize;
    final end = _end;
    if (end != null) {
      readBytes = min(readBytes, end - _position);
      if (readBytes < 0) {
        _readInProgress = false;
        if (!_unsubscribed) {
          _controller.addError(RangeError("Bad end position: $end"));
          _closeFile();
          _unsubscribed = true;
        }
        return;
      }
    }
    _openedFile!
        .read(readBytes)
        .then((block) {
          _readInProgress = false;
          if (_unsubscribed) {
            _closeFile();
            return;
          }
          _position += block.length;
          // read() may return less than `readBytes` if `_openFile` is a pipe or
          // terminal or if a signal is received. Only a empty return indicates
          // that the write side of the pipe is closed or that we are at the end
          // of a file.
          // See https://man7.org/linux/man-pages/man2/read.2.html
          if (block.isEmpty || (_end != null && _position == _end)) {
            _atEnd = true;
          }
          if (!_atEnd && !_controller.isPaused) {
            _readBlock();
          }
          if (block.isNotEmpty) {
            _controller.add(block);
          }
          if (_atEnd) {
            _closeFile();
          }
        })
        .catchError((e, s) {
          if (!_unsubscribed) {
            _controller.addError(e, s);
            _closeFile();
            _unsubscribed = true;
          }
        });
  }

  void _start() {
    if (_position < 0) {
      _controller.addError(RangeError("Bad start position: $_position"));
      _controller.close();
      _closeCompleter.complete();
      return;
    }

    void onReady(RandomAccessFile file) {
      _openedFile = file;
      _readInProgress = false;
      _readBlock();
    }

    void onOpenFile(RandomAccessFile file) {
      if (_position > 0) {
        file
            .setPosition(_position)
            .then(
              onReady,
              onError: (e, s) {
                _controller.addError(e, s);
                _readInProgress = false;
                _closeFile();
              },
            );
      } else {
        onReady(file);
      }
    }

    void openFailed(error, stackTrace) {
      _controller.addError(error, stackTrace);
      _controller.close();
      _closeCompleter.complete();
    }

    final path = _path;
    final openedFile = _openedFile;
    if (openedFile != null) {
      onOpenFile(openedFile);
    } else if (path != null) {
      File(
        path,
      ).open(mode: FileMode.read).then(onOpenFile, onError: openFailed);
    } else {
      try {
        onOpenFile(_File._openStdioSync(0));
      } catch (e, s) {
        openFailed(e, s);
      }
    }
  }
}

class _FileStreamConsumer implements StreamConsumer<List<int>> {
  File? _file;
  final Future<RandomAccessFile> _openFuture;

  _FileStreamConsumer(File file, FileMode mode)
    : _file = file,
      _openFuture = file.open(mode: mode);

  _FileStreamConsumer._fromStdio(int fd)
    : _openFuture = Future.value(_File._openStdioSync(fd));

  _FileStreamConsumer.fromRandomAccessFile(RandomAccessFile f)
    : _openFuture = Future.value(f);

  @override
  Future<File?> addStream(Stream<List<int>> stream) {
    Completer<File?> completer = Completer<File?>.sync();
    _openFuture
        .then((openedFile) {
          late StreamSubscription<List<int>> subscription;
          void error(e, StackTrace stackTrace) {
            subscription.cancel();
            openedFile.close();
            completer.completeError(e, stackTrace);
          }

          subscription = stream.listen(
            (d) {
              subscription.pause();
              try {
                openedFile
                    .writeFrom(d, 0, d.length)
                    .then((_) => subscription.resume(), onError: error);
              } catch (e, stackTrace) {
                error(e, stackTrace);
              }
            },
            onDone: () {
              completer.complete(_file);
            },
            onError: error,
            cancelOnError: true,
          );
        })
        .catchError(completer.completeError);
    return completer.future;
  }

  @override
  Future<File?> close() =>
      _openFuture.then((openedFile) => openedFile.close()).then((_) => _file);
}

// Class for encapsulating the native implementation of files.
class _File extends FileSystemEntity implements File {
  @override
  final String _path;
  @override
  final Uint8List _rawPath;

  _File(String path)
    : _path = _checkNotNull(path, "path"),
      _rawPath = FileSystemEntity._toUtf8Array(path);

  _File.fromRawPath(Uint8List rawPath)
    : _rawPath = FileSystemEntity._toNullTerminatedUtf8Array(
        _checkNotNull(rawPath, "rawPath"),
      ),
      _path = FileSystemEntity._toStringFromUtf8Array(rawPath);

  @override
  String get path => _path;

  // WARNING:
  // Calling this function will increase the reference count on the native
  // namespace object. It should only be called to pass the pointer to the
  // IOService, which will decrement the reference count when it is finished
  // with it.
  static int _namespacePointer() => _Namespace._namespacePointer;

  static Future<Object?> _dispatchWithNamespace(int request, List data) {
    data[0] = _namespacePointer();
    return _IOService._dispatch(request, data);
  }

  @override
  Future<bool> exists() {
    return _dispatchWithNamespace(_IOService.fileExists, [null, _rawPath]).then(
      (response) {
        _checkForErrorResponse(response, "Cannot check existence", path);
        return response as bool;
      },
    );
  }

  external static _exists(_Namespace namespace, Uint8List rawPath);

  @override
  bool existsSync() {
    var result = _exists(_Namespace._namespace, _rawPath);
    throwIfError(result, "Cannot check existence of file", path);
    return result;
  }

  @override
  File get absolute => File(_absolutePath);

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) {
    var result = recursive
        ? parent.create(recursive: true)
        : Future.value(null);
    return result
        .then(
          (_) => _dispatchWithNamespace(_IOService.fileCreate, [
            null,
            _rawPath,
            exclusive,
          ]),
        )
        .then((response) {
          _checkForErrorResponse(response, "Cannot create file", path);
          return this;
        });
  }

  external static _create(
    _Namespace namespace,
    Uint8List rawPath,
    bool exclusive,
  );

  external static _createLink(
    _Namespace namespace,
    Uint8List rawPath,
    String target,
  );

  external static List<dynamic> _createPipe(_Namespace namespace);

  external static _linkTarget(_Namespace namespace, Uint8List rawPath);

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    if (recursive) {
      parent.createSync(recursive: true);
    }
    var result = _create(_Namespace._namespace, _rawPath, exclusive);
    throwIfError(result, "Cannot create file", path);
  }

  @override
  Future<File> _delete({bool recursive = false}) {
    if (recursive) {
      return Directory(path).delete(recursive: true).then((_) => this);
    }
    return _dispatchWithNamespace(_IOService.fileDelete, [null, _rawPath]).then(
      (response) {
        _checkForErrorResponse(response, "Cannot delete file", path);
        return this;
      },
    );
  }

  external static _deleteNative(_Namespace namespace, Uint8List rawPath);

  external static _deleteLinkNative(_Namespace namespace, Uint8List rawPath);

  @override
  void _deleteSync({bool recursive = false}) {
    if (recursive) {
      return Directory.fromRawPath(_rawPath).deleteSync(recursive: true);
    }
    var result = _deleteNative(_Namespace._namespace, _rawPath);
    throwIfError(result, "Cannot delete file", path);
  }

  @override
  Future<File> rename(String newPath) {
    return _dispatchWithNamespace(_IOService.fileRename, [
      null,
      _rawPath,
      newPath,
    ]).then((response) {
      _checkForErrorResponse(
        response,
        "Cannot rename file to '$newPath'",
        path,
      );
      return File(newPath);
    });
  }

  external static _rename(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );

  external static _renameLink(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );

  @override
  File renameSync(String newPath) {
    var result = _rename(_Namespace._namespace, _rawPath, newPath);
    throwIfError(result, "Cannot rename file to '$newPath'", path);
    return File(newPath);
  }

  @override
  Future<File> copy(String newPath) {
    return _dispatchWithNamespace(_IOService.fileCopy, [
      null,
      _rawPath,
      newPath,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot copy file to '$newPath'", path);
      return File(newPath);
    });
  }

  external static _copy(
    _Namespace namespace,
    Uint8List oldPath,
    String newPath,
  );

  @override
  File copySync(String newPath) {
    var result = _copy(_Namespace._namespace, _rawPath, newPath);
    throwIfError(result, "Cannot copy file to '$newPath'", path);
    return File(newPath);
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    if (mode != FileMode.read &&
        mode != FileMode.write &&
        mode != FileMode.append &&
        mode != FileMode.writeOnly &&
        mode != FileMode.writeOnlyAppend) {
      return Future.error(
        ArgumentError('Invalid file mode for this operation'),
      );
    }
    return _dispatchWithNamespace(_IOService.fileOpen, [
      null,
      _rawPath,
      mode._mode,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot open file", path);
      return _RandomAccessFile(response as int, path);
    });
  }

  @override
  Future<int> length() {
    return _dispatchWithNamespace(_IOService.fileLengthFromPath, [
      null,
      _rawPath,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot retrieve length of file", path);
      return response as int;
    });
  }

  external static _lengthFromPath(_Namespace namespace, Uint8List rawPath);

  @override
  int lengthSync() {
    var result = _lengthFromPath(_Namespace._namespace, _rawPath);
    throwIfError(result, "Cannot retrieve length of file", path);
    return result;
  }

  @override
  Future<DateTime> lastAccessed() {
    return _dispatchWithNamespace(_IOService.fileLastAccessed, [
      null,
      _rawPath,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot retrieve access time", path);
      return DateTime.fromMillisecondsSinceEpoch(response as int);
    });
  }

  external static _lastAccessed(_Namespace namespace, Uint8List rawPath);

  @override
  DateTime lastAccessedSync() {
    var ms = _lastAccessed(_Namespace._namespace, _rawPath);
    throwIfError(ms, "Cannot retrieve access time", path);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future setLastAccessed(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    return _dispatchWithNamespace(_IOService.fileSetLastAccessed, [
      null,
      _rawPath,
      millis,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot set access time", path);
      return null;
    });
  }

  external static _setLastAccessed(
    _Namespace namespace,
    Uint8List rawPath,
    int millis,
  );

  @override
  void setLastAccessedSync(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    var result = _setLastAccessed(_Namespace._namespace, _rawPath, millis);
    if (result is OSError) {
      throw FileSystemException(
        "Failed to set file access time",
        path,
        result,
      );
    }
  }

  @override
  Future<DateTime> lastModified() {
    return _dispatchWithNamespace(_IOService.fileLastModified, [
      null,
      _rawPath,
    ]).then((response) {
      _checkForErrorResponse(
        response,
        "Cannot retrieve modification time",
        path,
      );
      return DateTime.fromMillisecondsSinceEpoch(response as int);
    });
  }

  external static _lastModified(_Namespace namespace, Uint8List rawPath);

  @override
  DateTime lastModifiedSync() {
    var ms = _lastModified(_Namespace._namespace, _rawPath);
    throwIfError(ms, "Cannot retrieve modification time", path);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future setLastModified(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    return _dispatchWithNamespace(_IOService.fileSetLastModified, [
      null,
      _rawPath,
      millis,
    ]).then((response) {
      _checkForErrorResponse(response, "Cannot set modification time", path);
      return null;
    });
  }

  external static _setLastModified(
    _Namespace namespace,
    Uint8List rawPath,
    int millis,
  );

  @override
  void setLastModifiedSync(DateTime time) {
    int millis = time.millisecondsSinceEpoch;
    var result = _setLastModified(_Namespace._namespace, _rawPath, millis);
    if (result is OSError) {
      throw FileSystemException(
        "Failed to set file modification time",
        path,
        result,
      );
    }
  }

  external static _open(_Namespace namespace, Uint8List rawPath, int mode);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    if (mode != FileMode.read &&
        mode != FileMode.write &&
        mode != FileMode.append &&
        mode != FileMode.writeOnly &&
        mode != FileMode.writeOnlyAppend) {
      throw ArgumentError('Invalid file mode for this operation');
    }
    var id = _open(_Namespace._namespace, _rawPath, mode._mode);
    throwIfError(id, "Cannot open file", path);
    return _RandomAccessFile(id, _path);
  }

  external static int _openStdio(int fd);

  static RandomAccessFile _openStdioSync(int fd) {
    var id = _openStdio(fd);
    if (id == 0) {
      throw FileSystemException("Cannot open stdio file for: $fd");
    }
    return _RandomAccessFile(id, "");
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    return _FileStream(path, start, end);
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    if (mode != FileMode.write &&
        mode != FileMode.append &&
        mode != FileMode.writeOnly &&
        mode != FileMode.writeOnlyAppend) {
      throw ArgumentError('Invalid file mode for this operation');
    }
    var consumer = _FileStreamConsumer(this, mode);
    return IOSink(consumer, encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    Future<Uint8List> readUnsized(RandomAccessFile file) {
      var builder = BytesBuilder(copy: false);
      var completer = Completer<Uint8List>();
      void read() {
        file.read(_blockSize).then((data) {
          if (data.isNotEmpty) {
            builder.add(data);
            read();
          } else {
            completer.complete(builder.takeBytes());
          }
        }, onError: completer.completeError);
      }

      read();
      return completer.future;
    }

    Future<Uint8List> readSized(RandomAccessFile file, int length) {
      var data = Uint8List(length);
      var offset = 0;
      var completer = Completer<Uint8List>();
      void read() {
        file.readInto(data, offset, min(offset + _maxReadSize, length)).then((
          readSize,
        ) {
          if (readSize > 0) {
            offset += readSize;
            read();
          } else {
            assert(readSize == 0);
            if (offset < length) {
              data = Uint8List.sublistView(data, 0, offset);
            }
            completer.complete(data);
          }
        }, onError: completer.completeError);
      }

      read();
      return completer.future;
    }

    return open().then((file) {
      return file
          .length()
          .then((length) {
            if (length == 0) {
              // May be character device, try to read it in chunks.
              return readUnsized(file);
            }
            return readSized(file, length);
          })
          .whenComplete(file.close);
    });
  }

  @override
  Uint8List readAsBytesSync() {
    var opened = openSync();
    try {
      Uint8List data;
      var length = opened.lengthSync();
      if (length == 0) {
        // May be character device, try to read it in chunks.
        var builder = BytesBuilder(copy: false);
        do {
          data = opened.readSync(_blockSize);
          if (data.isNotEmpty) {
            builder.add(data);
          }
        } while (data.isNotEmpty);
        data = builder.takeBytes();
      } else {
        data = Uint8List(length);
        var offset = 0;

        while (offset < length) {
          final readSize = opened.readIntoSync(
            data,
            offset,
            min(offset + _maxReadSize, length),
          );
          if (readSize == 0) {
            break;
          }
          offset += readSize;
        }

        if (offset < length) {
          data = Uint8List.view(data.buffer, 0, offset);
        }
      }
      return data;
    } finally {
      opened.closeSync();
    }
  }

  String _tryDecode(List<int> bytes, Encoding encoding) {
    try {
      return encoding.decode(bytes);
    } catch (_) {
      throw FileSystemException(
        "Failed to decode data using encoding '${encoding.name}'",
        path,
      );
    }
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      _tryDecode(await readAsBytes(), encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _tryDecode(readAsBytesSync(), encoding);

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      readAsString(encoding: encoding).then(const LineSplitter().convert);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      const LineSplitter().convert(readAsStringSync(encoding: encoding));

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    return open(mode: mode).then((file) {
      return file
          .writeFrom(bytes, 0, bytes.length)
          .then<File>((_) {
            if (flush) return file.flush().then((_) => this);
            return this;
          })
          .whenComplete(file.close);
    });
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    RandomAccessFile opened = openSync(mode: mode);
    try {
      opened.writeFromSync(bytes, 0, bytes.length);
      if (flush) opened.flushSync();
    } finally {
      opened.closeSync();
    }
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    try {
      return writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);
  }

  @override
  String toString() => "File: '$path'";

  static throwIfError(Object result, String msg, String path) {
    if (result is OSError) {
      throw FileSystemException._fromOSError(result, msg, path);
    }
  }

  // TODO(40614): Remove once non-nullability is sound.
  static T _checkNotNull<T>(T t, String name) {
    ArgumentError.checkNotNull(t, name);
    return t;
  }
}

abstract class _RandomAccessFileOps {
  external factory _RandomAccessFileOps._(int pointer);

  int _getPointer();
  int get fd;
  int close();
  readByte();
  read(int bytes);
  readInto(List<int> buffer, int start, int? end);
  writeByte(int value);
  writeFrom(List<int> buffer, int start, int? end);
  position();
  setPosition(int position);
  truncate(int length);
  length();
  flush();
  lock(int lock, int start, int end);
}

@pragma("vm:entry-point")
class _RandomAccessFile implements RandomAccessFile {
  static bool _connectedResourceHandler = false;

  @override
  final String path;

  bool _asyncDispatched = false;

  late _FileResourceInfo _resourceInfo;
  final _RandomAccessFileOps _ops;

  @pragma("vm:entry-point")
  _RandomAccessFile(int pointer, this.path)
    : _ops = _RandomAccessFileOps._(pointer) {
    _resourceInfo = _FileResourceInfo(this);
    _maybeConnectHandler();
  }

  void _maybePerformCleanup() {
    if (closed) {
      _FileResourceInfo.fileClosed(_resourceInfo);
    }
  }

  _maybeConnectHandler() {
    if (!const bool.fromEnvironment("dart.vm.product") &&
        !_connectedResourceHandler) {
      // TODO(ricow): We probably need to set these in some initialization code.
      // We need to make sure that these are always available from the
      // observatory even if no files (or sockets for the socket ones) are
      // open.
      registerExtension(
        'ext.dart.io.getOpenFiles',
        _FileResourceInfo.getOpenFiles,
      );
      registerExtension(
        'ext.dart.io.getOpenFileById',
        _FileResourceInfo.getOpenFileInfoMapByID,
      );
      _connectedResourceHandler = true;
    }
  }

  @override
  Future<void> close() {
    return _dispatch(_IOService.fileClose, [null], markClosed: true).then((
      result,
    ) {
      if (result == -1) {
        throw FileSystemException("Cannot close file", path);
      }
      closed = closed || (result == 0);
      _maybePerformCleanup();
    });
  }

  @override
  void closeSync() {
    _checkAvailable();
    var id = _ops.close();
    if (id == -1) {
      throw FileSystemException("Cannot close file", path);
    }
    closed = closed || (id == 0);
    _maybePerformCleanup();
  }

  @override
  Future<int> readByte() {
    return _dispatch(_IOService.fileReadByte, [null]).then((response) {
      _checkForErrorResponse(response, "readByte failed", path);
      _resourceInfo.addRead(1);
      return response as int;
    });
  }

  @override
  int readByteSync() {
    _checkAvailable();
    var result = _ops.readByte();
    if (result is OSError) {
      throw FileSystemException("readByte failed", path, result);
    }
    _resourceInfo.addRead(1);
    return result;
  }

  @override
  Future<Uint8List> read(int bytes) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(bytes, "bytes");
    return _dispatch(_IOService.fileRead, [null, bytes]).then((response) {
      _checkForErrorResponse(response, "read failed", path);
      var result = (response as List<Object?>)[1] as Uint8List;
      _resourceInfo.addRead(result.length);
      return result;
    });
  }

  @override
  Uint8List readSync(int bytes) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(bytes, "bytes");
    _checkAvailable();
    var result = _ops.read(bytes);
    if (result is! Uint8List) {
      throw FileSystemException("readSync failed", path, result as OSError);
    }
    _resourceInfo.addRead(result.length);
    return result;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return Future.value(0);
    }
    int length = end - start;
    return _dispatch(_IOService.fileReadInto, [null, length]).then((response) {
      _checkForErrorResponse(response, "readInto failed", path);
      var responseList = response as List<Object?>;
      var read = responseList[1] as int;
      var data = responseList[2] as List<int>;
      buffer.setRange(start, start + read, data);
      _resourceInfo.addRead(read);
      return read;
    });
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    _checkAvailable();
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return 0;
    }
    var result = _ops.readInto(buffer, start, end);
    if (result is OSError) {
      throw FileSystemException("readInto failed", path, result);
    }
    _resourceInfo.addRead(result);
    return result;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(value, "value");
    return _dispatch(_IOService.fileWriteByte, [null, value]).then((response) {
      _checkForErrorResponse(response, "writeByte failed", path);
      _resourceInfo.addWrite(1);
      return this;
    });
  }

  @override
  int writeByteSync(int value) {
    _checkAvailable();
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(value, "value");
    var result = _ops.writeByte(value);
    if (result is OSError) {
      throw FileSystemException("writeByte failed", path, result);
    }
    _resourceInfo.addWrite(1);
    return result;
  }

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    ArgumentError.checkNotNull(start, "start");
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return Future.value(this);
    }
    _BufferAndStart result;
    try {
      result = _ensureFastAndSerializableByteData(buffer, start, end);
    } catch (e) {
      return Future.error(e);
    }

    List request = List<dynamic>.filled(4, null);
    request[0] = null;
    request[1] = result.buffer;
    request[2] = result.start;
    request[3] = end - (start - result.start);
    return _dispatch(_IOService.fileWriteFrom, request).then((response) {
      _checkForErrorResponse(response, "writeFrom failed", path);
      _resourceInfo.addWrite(end! - (start - result.start));
      return this;
    });
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _checkAvailable();
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(buffer, "buffer");
    ArgumentError.checkNotNull(start, "start");
    end = RangeError.checkValidRange(start, end, buffer.length);
    if (end == start) {
      return;
    }
    _BufferAndStart bufferAndStart = _ensureFastAndSerializableByteData(
      buffer,
      start,
      end,
    );
    var result = _ops.writeFrom(
      bufferAndStart.buffer,
      bufferAndStart.start,
      end - (start - bufferAndStart.start),
    );
    if (result is OSError) {
      throw FileSystemException("writeFrom failed", path, result);
    }
    _resourceInfo.addWrite(end - (start - bufferAndStart.start));
  }

  @override
  Future<RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(encoding, "encoding");
    var data = encoding.encode(string);
    return writeFrom(data, 0, data.length);
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(encoding, "encoding");
    var data = encoding.encode(string);
    writeFromSync(data, 0, data.length);
  }

  @override
  Future<int> position() {
    return _dispatch(_IOService.filePosition, [null]).then((response) {
      _checkForErrorResponse(response, "position failed", path);
      return response as int;
    });
  }

  @override
  int positionSync() {
    _checkAvailable();
    var result = _ops.position();
    if (result is OSError) {
      throw FileSystemException("position failed", path, result);
    }
    return result;
  }

  @override
  Future<RandomAccessFile> setPosition(int position) {
    return _dispatch(_IOService.fileSetPosition, [null, position]).then((
      response,
    ) {
      _checkForErrorResponse(response, "setPosition failed", path);
      return this;
    });
  }

  @override
  void setPositionSync(int position) {
    _checkAvailable();
    var result = _ops.setPosition(position);
    if (result is OSError) {
      throw FileSystemException("setPosition failed", path, result);
    }
  }

  @override
  Future<RandomAccessFile> truncate(int length) {
    return _dispatch(_IOService.fileTruncate, [null, length]).then((response) {
      _checkForErrorResponse(response, "truncate failed", path);
      return this;
    });
  }

  @override
  void truncateSync(int length) {
    _checkAvailable();
    var result = _ops.truncate(length);
    if (result is OSError) {
      throw FileSystemException("truncate failed", path, result);
    }
  }

  @override
  Future<int> length() {
    return _dispatch(_IOService.fileLength, [null]).then((response) {
      _checkForErrorResponse(response, "length failed", path);
      return response as int;
    });
  }

  @override
  int lengthSync() {
    _checkAvailable();
    var result = _ops.length();
    if (result is OSError) {
      throw FileSystemException("length failed", path, result);
    }
    return result;
  }

  @override
  Future<RandomAccessFile> flush() {
    return _dispatch(_IOService.fileFlush, [null]).then((response) {
      _checkForErrorResponse(response, "flush failed", path);
      return this;
    });
  }

  @override
  void flushSync() {
    _checkAvailable();
    var result = _ops.flush();
    if (result is OSError) {
      throw FileSystemException("flush failed", path, result);
    }
  }

  static const int lockUnlock = 0;
  // static const int lockShared = 1;
  // static const int lockExclusive = 2;
  // static const int lockBlockingShared = 3;
  // static const int lockBlockingExclusive = 4;

  int _fileLockValue(FileLock fl) => fl._type;

  @override
  Future<RandomAccessFile> lock([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(mode, "mode");
    ArgumentError.checkNotNull(start, "start");
    ArgumentError.checkNotNull(end, "end");
    if ((start < 0) || (end < -1) || ((end != -1) && (start >= end))) {
      throw ArgumentError();
    }
    int lock = _fileLockValue(mode);
    return _dispatch(_IOService.fileLock, [null, lock, start, end]).then((
      response,
    ) {
      _checkForErrorResponse(response, 'lock failed', path);
      return this;
    });
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(start, "start");
    ArgumentError.checkNotNull(end, "end");
    if (start == end) {
      throw ArgumentError();
    }
    return _dispatch(_IOService.fileLock, [null, lockUnlock, start, end]).then((
      response,
    ) {
      _checkForErrorResponse(response, 'unlock failed', path);
      return this;
    });
  }

  @override
  void lockSync([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    _checkAvailable();
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(mode, "mode");
    ArgumentError.checkNotNull(start, "start");
    ArgumentError.checkNotNull(end, "end");
    if ((start < 0) || (end < -1) || ((end != -1) && (start >= end))) {
      throw ArgumentError();
    }
    int lock = _fileLockValue(mode);
    var result = _ops.lock(lock, start, end);
    if (result is OSError) {
      throw FileSystemException('lock failed', path, result);
    }
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _checkAvailable();
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(start, "start");
    ArgumentError.checkNotNull(end, "end");
    if (start == end) {
      throw ArgumentError();
    }
    var result = _ops.lock(lockUnlock, start, end);
    if (result is OSError) {
      throw FileSystemException('unlock failed', path, result);
    }
  }

  bool closed = false;

  int get fd => _ops.fd;

  // WARNING:
  // Calling this function will increase the reference count on the native
  // object that implements the file operations. It should only be called to
  // pass the pointer to the IO Service, which will decrement the reference
  // count when it is finished with it.
  int _pointer() => _ops._getPointer();

  Future<Object?> _dispatch(int request, List data, {bool markClosed = false}) {
    if (closed) {
      return Future.error(FileSystemException("File closed", path));
    }
    if (_asyncDispatched) {
      var msg = "An async operation is currently pending";
      return Future.error(FileSystemException(msg, path));
    }
    if (markClosed) {
      // Set closed to true to ensure that no more async requests can be issued
      // for this file.
      closed = true;
    }
    _asyncDispatched = true;
    data[0] = _pointer();
    return _IOService._dispatch(request, data).whenComplete(() {
      _asyncDispatched = false;
    });
  }

  void _checkAvailable() {
    if (_asyncDispatched) {
      throw FileSystemException(
        "An async operation is currently pending",
        path,
      );
    }
    if (closed) {
      throw FileSystemException("File closed", path);
    }
  }
}

class _ReadPipe extends _FileStream implements ReadPipe {
  _ReadPipe(RandomAccessFile file) : super.forRandomAccessFile(file);
}

class _WritePipe extends _IOSinkImpl implements WritePipe {
  final RandomAccessFile _file;
  _WritePipe(file)
    : _file = file,
      super(_FileStreamConsumer.fromRandomAccessFile(file), utf8);
}

class _Pipe implements Pipe {
  final ReadPipe _readPipe;
  final WritePipe _writePipe;

  @override
  ReadPipe get read => _readPipe;
  @override
  WritePipe get write => _writePipe;

  _Pipe(this._readPipe, this._writePipe);

  static Future<_Pipe> create() {
    final completer = Completer<_Pipe>.sync();

    _File._dispatchWithNamespace(_IOService.fileCreatePipe, [null]).then((
      response,
    ) {
      final filePointers = (response as List).cast<int>();
      completer.complete(
        _Pipe(
          _ReadPipe(_RandomAccessFile(filePointers[0], '')),
          _WritePipe(_RandomAccessFile(filePointers[1], '')),
        ),
      );
    });
    return completer.future;
  }

  factory _Pipe.createSync() {
    final filePointers = _File._createPipe(_Namespace._namespace);
    return _Pipe(
      _ReadPipe(_RandomAccessFile(filePointers[0] as int, '')),
      _WritePipe(_RandomAccessFile(filePointers[1] as int, '')),
    );
  }
}
