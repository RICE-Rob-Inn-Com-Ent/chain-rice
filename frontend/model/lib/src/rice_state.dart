import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity.dart';

part 'rice_state.freezed.dart';
part 'rice_state.g.dart';

/// Shared immutable snapshot for AI/session orchestration across roles.
@freezed
abstract class RiceState with _$RiceState {
  const factory RiceState({
    @Default('') String sessionId,
    @Default(<String, dynamic>{}) Map<String, dynamic> context,
    @Default(<Entity>[]) List<Entity> entities,
  }) = _RiceState;

  factory RiceState.fromJson(Map<String, dynamic> json) =>
      _$RiceStateFromJson(json);
}
