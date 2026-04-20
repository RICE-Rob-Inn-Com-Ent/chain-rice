import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'i_media_controller.dart';

/// Default [IMediaController] built on MediaKit (GPU-friendly, desktop + mobile).
class MediaKitMediaController extends IMediaController {
  MediaKitMediaController() {
    _player = Player();
    _video = VideoController(_player);
  }

  late final Player _player;
  late final VideoController _video;
  final List<VoidCallback> _listeners = [];

  @override
  Future<void> disposeController() async {
    await _player.dispose();
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  Widget buildPrimarySurface({Key? key}) {
    return Video(controller: _video, key: key);
  }

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Future<void> pause() async {
    await _player.pause();
    _notify();
  }

  @override
  Future<void> play() async {
    await _player.play();
    _notify();
  }

  @override
  Future<void> prepare({Uri? primaryUri}) async {
    if (primaryUri != null) {
      await _player.open(Media(primaryUri.toString()));
    }
    _notify();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _notify();
  }

  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
