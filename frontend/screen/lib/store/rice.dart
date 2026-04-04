import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO:
// [ ] activeProject, cookStatus, cookErrors; Phoenix invalidation
//
class RiceState {
  const RiceState({this.values = const <String, Object?>{}});

  final Map<String, Object?> values;

  RiceState copyWith({Map<String, Object?>? values}) => RiceState(values: values ?? this.values);
}

class RiceNotifier extends StateNotifier<RiceState> {
  RiceNotifier() : super(const RiceState());

  Object? get(String key) => state.values[key];

  void set(String key, Object? value) {
    state = state.copyWith(values: {...state.values, key: value});
  }

  void hydrate(Map<String, Object?> data) {
    state = state.copyWith(values: {...state.values, ...data});
  }

  void reset() {
    state = const RiceState();
  }
}
