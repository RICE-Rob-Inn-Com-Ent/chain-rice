import 'package:just_audio/just_audio.dart';

import 'i_audio_playback_engine.dart';

class JustAudioPlaybackEngine implements IAudioPlaybackEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> disposeEngine() => _player.dispose();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> setUrl(Uri uri) async {
    await _player.setUrl(uri.toString());
  }

  @override
  Future<void> stop() => _player.stop();
}
