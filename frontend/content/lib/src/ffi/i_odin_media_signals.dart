/// Hook surface for native Odin modules (video/audio) — swap for FFI bindings later.
abstract class IOdinMediaSignals {
  /// Hardware / OS “blink” cue (e.g. status LED rhythm). Codes are app-defined.
  void signalBlink(int code);

  /// `true` when a dynamic library has been bound successfully.
  bool get isNativeBound;
}

/// Safe default when Odin is not linked (desktop dev, tests).
class StubOdinMediaSignals implements IOdinMediaSignals {
  @override
  bool get isNativeBound => false;

  @override
  void signalBlink(int code) {
    // no-op — replace with FFI `foreign` calls when librice bridge is shipped.
  }
}
