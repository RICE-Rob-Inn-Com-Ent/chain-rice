import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// TODO:
// [ ] audioplayers + volume from ui; platform channels — https://pub.dev/packages/audioplayers
//
Provider<AudioPlayer> Provider<AudioPlayer> audioPlayerProvider = Provider<AudioPlayer>((ProviderRef<AudioPlayer> ProviderRef<AudioPlayer> ref) {
  final AudioPlayer AudioPlayer player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});
