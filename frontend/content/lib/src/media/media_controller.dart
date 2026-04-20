import 'package:flutter/widgets.dart';

import '../ffi/i_odin_media_signals.dart';
import 'i_audio_playback_engine.dart';
import 'i_media_controller.dart';
import 'just_audio_playback_engine.dart';
import 'media_kit_media_controller.dart';

/// Coordinates primary [IMediaController] (MediaKit) with an auxiliary
/// [IAudioPlaybackEngine] (`just_audio`) and optional Odin FFI hooks.
class MediaController {
  MediaController({
    IMediaController? video,
    IAudioPlaybackEngine? auxiliaryAudio,
    IOdinMediaSignals? odin,
  })  : video = video ?? MediaKitMediaController(),
        auxiliaryAudio = auxiliaryAudio ?? JustAudioPlaybackEngine(),
        odin = odin ?? StubOdinMediaSignals();

  final IMediaController video;
  final IAudioPlaybackEngine auxiliaryAudio;
  final IOdinMediaSignals odin;

  /// Surface for embedding in layout.
  Widget primarySurface({Key? key}) => video.buildPrimarySurface(key: key);

  Future<void> prepareMain({Uri? uri}) => video.prepare(primaryUri: uri);

  Future<void> playMain() async {
    odin.signalBlink(1);
    await video.play();
  }

  Future<void> pauseMain() => video.pause();

  Future<void> playAuxiliary(Uri uri) async {
    await auxiliaryAudio.setUrl(uri);
    await auxiliaryAudio.play();
  }

  Future<void> disposeAll() async {
    await video.disposeController();
    await auxiliaryAudio.disposeEngine();
  }
}
