import 'package:freezed_annotation/freezed_annotation.dart';

part 'common.freezed.dart';
part 'common.g.dart';

@JsonEnum(alwaysCreate: true)
enum SystemStatus {
  active,
  throttling,
  sleeping,
  failure,
}

@freezed
abstract class DataUnit with _$DataUnit {
  @JsonSerializable(explicitToJson: true)
  const factory DataUnit({
    required double value,
    required String unit,
  }) = _DataUnit;

  factory DataUnit.fromJson(Map<String, dynamic> json) =>
      _$DataUnitFromJson(json);
}

@freezed
abstract class GeoLocation with _$GeoLocation {
  @JsonSerializable(explicitToJson: true)
  const factory GeoLocation({
    required double lat,
    required double lon,
    @Default(0.0) double alt,
  }) = _GeoLocation;

  factory GeoLocation.fromJson(Map<String, dynamic> json) =>
      _$GeoLocationFromJson(json);
}
