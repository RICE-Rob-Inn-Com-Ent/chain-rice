import 'dart:ffi' as ffi;
import 'dart:io' show File, Platform;

import 'package:ffi/ffi.dart';

typedef RicePushFrameNative = ffi.Void Function(
  ffi.Pointer<ffi.Uint8>,
  ffi.Size,
);
typedef RicePushFrameDart = void Function(ffi.Pointer<ffi.Uint8>, int);

/// Opens a desktop dynamic library and exposes typed lookups for Odin/C shims.
final class RiceFfiBridge {
  RiceFfiBridge._(this.library);

  /// Opens [path] as a dynamic library (absolute path or platform search path).
  factory RiceFfiBridge.open(String path) {
    return RiceFfiBridge._(ffi.DynamicLibrary.open(path));
  }

  final ffi.DynamicLibrary library;

  RicePushFrameDart? _pushFrame;

  /// Example binding: `void rice_push_frame(uint8_t* data, size_t len);`
  RicePushFrameDart? loadPushFrame() {
    if (_pushFrame != null) {
      return _pushFrame;
    }
    try {
      _pushFrame = library
          .lookup<ffi.NativeFunction<RicePushFrameNative>>('rice_push_frame')
          .asFunction();
    } catch (_) {
      _pushFrame = null;
    }
    return _pushFrame;
  }

  /// Copies [bytes] into native memory and calls `rice_push_frame` when present.
  void sendFrameBytes(List<int> bytes) {
    final fn = loadPushFrame();
    if (fn == null) {
      throw StateError('Native symbol rice_push_frame is not exported by this library.');
    }
    final len = bytes.length;
    final ptr = calloc<ffi.Uint8>(len);
    try {
      for (var i = 0; i < len; i++) {
        ptr[i] = bytes[i];
      }
      fn(ptr, len);
    } finally {
      calloc.free(ptr);
    }
  }

  static bool nativeLibExists(String path) => File(path).existsSync();

  static bool get ffiSupported =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}
