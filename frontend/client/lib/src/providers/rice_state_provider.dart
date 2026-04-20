import 'package:model/unit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rice_state_provider.g.dart';

@Riverpod(keepAlive: true)
class RiceSessionState extends _$RiceSessionState {
  @override
  RiceState build() => const RiceState();

  void patchContext(Map<String, dynamic> patch) {
    state = state.copyWith(
      context: {...state.context, ...patch},
    );
  }
}
