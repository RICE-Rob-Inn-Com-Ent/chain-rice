import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensors_pro.freezed.dart';
part 'sensors_pro.g.dart';

@freezed
abstract class Vec3 with _$Vec3 {
  @JsonSerializable(explicitToJson: true)
  const factory Vec3({
    required double x,
    required double y,
    required double z,
  }) = _Vec3;

  factory Vec3.fromJson(Map<String, dynamic> json) => _$Vec3FromJson(json);
}

@freezed
abstract class ImuData with _$ImuData {
  @JsonSerializable(explicitToJson: true)
  const factory ImuData({
    required Vec3 accelerometer,
    required Vec3 gyroscope,
    required Vec3 magnetometer,
  }) = _ImuData;

  factory ImuData.fromJson(Map<String, dynamic> json) =>
      _$ImuDataFromJson(json);
}

@freezed
abstract class VisionSpec with _$VisionSpec {
  @JsonSerializable(explicitToJson: true)
  const factory VisionSpec({
    required String cameraPath,
    @Default(<String>[]) List<String> formats,
    required double maxFps,
    required int currentResolutionWidth,
    required int currentResolutionHeight,
  }) = _VisionSpec;

  factory VisionSpec.fromJson(Map<String, dynamic> json) =>
      _$VisionSpecFromJson(json);
}

@freezed
abstract class SdrSpectrum with _$SdrSpectrum {
  @JsonSerializable(explicitToJson: true)
  const factory SdrSpectrum({
    required double frequencyMin,
    required double frequencyMax,
    required double sampleRate,
  }) = _SdrSpectrum;

  factory SdrSpectrum.fromJson(Map<String, dynamic> json) =>
      _$SdrSpectrumFromJson(json);
}
