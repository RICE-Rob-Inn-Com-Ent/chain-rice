/// Lightweight audio lane — `just_audio` today, can be swapped for hardware sink.
abstract class IAudioPlaybackEngine {
  Future<void> setUrl(Uri uri);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> disposeEngine();
}
