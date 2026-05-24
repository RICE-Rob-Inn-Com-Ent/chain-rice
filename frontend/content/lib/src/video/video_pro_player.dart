import 'dart:io' show File, Platform;

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

bool _useBundledMediaKitLibs() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isLinux || Platform.isWindows;
}

/// One-time native bootstrap for libmpv-backed playback on Linux/Windows apps.
final class RiceContentMedia {
  RiceContentMedia._();

  static bool _done = false;

  static Future<void> ensureInitialized() async {
    if (_done) {
      return;
    }
    if (_useBundledMediaKitLibs()) {
      MediaKit.ensureInitialized();
    }
    _done = true;
  }
}

/// Desktop-first player (media_kit / mpv) with a Chewie + [VideoPlayerController] fallback.
final class VideoProPlayer extends StatefulWidget {
  const VideoProPlayer({
    super.key,
    required this.source,
    this.autoPlay = true,
    this.aspectRatio,
  });

  final Uri source;
  final bool autoPlay;
  final double? aspectRatio;

  @override
  State<VideoProPlayer> createState() => _VideoProPlayerState();
}

class _VideoProPlayerState extends State<VideoProPlayer> {
  Player? _mkPlayer;
  VideoController? _mkVideo;
  VideoPlayerController? _vp;
  ChewieController? _chewie;
  Object? _error;

  bool get _nativeMk => _useBundledMediaKitLibs();

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      if (_nativeMk) {
        await RiceContentMedia.ensureInitialized();
        final player = Player(
          configuration: const PlayerConfiguration(
            title: 'rice-content',
          ),
        );
        final video = VideoController(
          player,
          configuration: const VideoControllerConfiguration(
            enableHardwareAcceleration: true,
          ),
        );
        await player.open(Media(widget.source.toString()), play: widget.autoPlay);
        if (!mounted) {
          await player.dispose();
          return;
        }
        setState(() {
          _mkPlayer = player;
          _mkVideo = video;
        });
        return;
      }

      final VideoPlayerController vc;
      final scheme = widget.source.scheme.toLowerCase();
      if (scheme == 'file') {
        vc = VideoPlayerController.file(File.fromUri(widget.source));
      } else if (scheme == 'asset') {
        var path = widget.source.path;
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
        vc = VideoPlayerController.asset(path);
      } else {
        vc = VideoPlayerController.networkUrl(widget.source);
      }
      await vc.initialize();
      if (!mounted) {
        await vc.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: vc,
        autoPlay: widget.autoPlay,
        looping: false,
        aspectRatio: widget.aspectRatio ?? vc.value.aspectRatio,
        isLive: widget.source.scheme.toLowerCase() == 'rtsp',
      );
      setState(() {
        _vp = vc;
        _chewie = chewie;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vp?.dispose();
    _mkVideo = null;
    final p = _mkPlayer;
    _mkPlayer = null;
    p?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Playback error: $_error'));
    }
    final mk = _mkVideo;
    if (mk != null && _mkPlayer != null) {
      final ar = widget.aspectRatio;
      final video = Video(controller: mk);
      if (ar != null) {
        return AspectRatio(aspectRatio: ar, child: video);
      }
      return video;
    }
    final ch = _chewie;
    if (ch != null) {
      return Chewie(controller: ch);
    }
    return const Center(child: CircularProgressIndicator());
  }
}
