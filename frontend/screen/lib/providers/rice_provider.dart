import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/rice.dart';

// TODO:
// [ ] Phoenix WebSocket; cook status; foreground connect — https://riverpod.dev/docs/providers/provider
//
final riceProvider =
    StateNotifierProvider<RiceNotifier, RiceState>((ref) => RiceNotifier());
