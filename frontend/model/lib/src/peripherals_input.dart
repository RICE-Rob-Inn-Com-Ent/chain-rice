import 'package:freezed_annotation/freezed_annotation.dart';

part 'peripherals_input.freezed.dart';
part 'peripherals_input.g.dart';

@freezed
abstract class InputDevice with _$InputDevice {
  @JsonSerializable(explicitToJson: true)
  const factory InputDevice({
    required String name,
    required String path,
    required String bustype,
    required String vendor,
    required String product,
  }) = _InputDevice;

  factory InputDevice.fromJson(Map<String, dynamic> json) =>
      _$InputDeviceFromJson(json);
}

@freezed
abstract class DisplayInfo with _$DisplayInfo {
  @JsonSerializable(explicitToJson: true)
  const factory DisplayInfo({
    required String id,
    required int width,
    required int height,
    required double refreshRate,
    required bool isConnected,
    String? edid,
  }) = _DisplayInfo;

  factory DisplayInfo.fromJson(Map<String, dynamic> json) =>
      _$DisplayInfoFromJson(json);
}

@freezed
abstract class InputCapabilities with _$InputCapabilities {
  @JsonSerializable(explicitToJson: true)
  const factory InputCapabilities({
    required bool supportsPressure,
    required bool supportsMultiTouch,
    required bool hasHaptics,
  }) = _InputCapabilities;

  factory InputCapabilities.fromJson(Map<String, dynamic> json) =>
      _$InputCapabilitiesFromJson(json);
}
