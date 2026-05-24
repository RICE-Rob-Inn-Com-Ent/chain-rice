import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// High-level queue player with session ducking and optional lock-screen metadata.
final class RiceAudioPlayer {
  RiceAudioPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  bool _pausedByInterruption = false;

  AudioPlayer get player => _player;

  /// Call from `main()` before [runApp] when you want background + OS controls.
  static Future<void> initBackgroundPlayback({
    String? androidNotificationChannelId,
    String androidNotificationChannelName = 'Rice audio',
    bool androidNotificationOngoing = true,
  }) {
    return JustAudioBackground.init(
      androidNotificationChannelId: androidNotificationChannelId,
      androidNotificationChannelName: androidNotificationChannelName,
      androidNotificationOngoing: androidNotificationOngoing,
    );
  }

  Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _interruptionSub?.cancel();
    _interruptionSub = session.interruptionEventStream.listen(_onInterruption);
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await _player.setVolume(_player.volume * 0.35);
          _pausedByInterruption = false;
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_player.playing) {
            await _player.pause();
            _pausedByInterruption = true;
          }
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await _player.setVolume(1.0);
          _pausedByInterruption = false;
        case AudioInterruptionType.pause:
          if (_pausedByInterruption) {
            await _player.play();
          }
          _pausedByInterruption = false;
        case AudioInterruptionType.unknown:
          _pausedByInterruption = false;
      }
    }
  }

  /// Builds a playlist; pass [tags] aligned with [sources] for background metadata.
  Future<void> setQueue(
    List<Uri> sources, {
    List<MediaItem>? tags,
  }) async {
    if (sources.isEmpty) {
      await _player.setAudioSources(const []);
      return;
    }
    final children = <AudioSource>[];
    for (var i = 0; i < sources.length; i++) {
      final uri = sources[i];
      final tag = (tags != null && i < tags.length) ? tags[i] : null;
      children.add(
        tag == null ? AudioSource.uri(uri) : AudioSource.uri(uri, tag: tag),
      );
    }
    await _player.setAudioSources(children);
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _player.dispose();
  }
}
