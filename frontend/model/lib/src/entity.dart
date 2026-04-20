import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity.freezed.dart';
part 'entity.g.dart';

/// Immutable domain unit for AI-facing state graphs.
@freezed
abstract class Entity with _$Entity {
  const factory Entity({
    required String id,
    required String kind,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
  }) = _Entity;

  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);
}
