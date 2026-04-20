import 'package:flutter/widgets.dart';

/// Swappable media backend — implement with MediaKit, ExoPlayer later, etc.
abstract class IMediaController extends Listenable {
  Future<void> prepare({Uri? primaryUri});

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  /// Release players / textures. Safe to call more than once.
  Future<void> disposeController();

  /// Primary video surface (no-op widget when audio-only).
  Widget buildPrimarySurface({Key? key});
}
