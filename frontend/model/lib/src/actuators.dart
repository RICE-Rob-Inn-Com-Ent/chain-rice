import 'package:freezed_annotation/freezed_annotation.dart';

part 'actuators.freezed.dart';
part 'actuators.g.dart';

@JsonEnum(alwaysCreate: true)
enum GpioMode {
  input,
  output,
}

@JsonEnum(alwaysCreate: true)
enum GpioValue {
  high,
  low,
}

@freezed
abstract class PwmChannel with _$PwmChannel {
  @JsonSerializable(explicitToJson: true)
  const factory PwmChannel({
    required String id,
    required double dutyCycle,
    required double frequency,
  }) = _PwmChannel;

  factory PwmChannel.fromJson(Map<String, dynamic> json) =>
      _$PwmChannelFromJson(json);
}

@freezed
abstract class GpioPin with _$GpioPin {
  @JsonSerializable(explicitToJson: true)
  const factory GpioPin({
    required int pinNumber,
    required GpioMode mode,
    GpioValue? value,
  }) = _GpioPin;

  factory GpioPin.fromJson(Map<String, dynamic> json) =>
      _$GpioPinFromJson(json);
}

@freezed
abstract class MotorControl with _$MotorControl {
  @JsonSerializable(explicitToJson: true)
  const factory MotorControl({
    required String id,
    required double rpm,
    required double loadPercentage,
    required double temperature,
  }) = _MotorControl;

  factory MotorControl.fromJson(Map<String, dynamic> json) =>
      _$MotorControlFromJson(json);
}
