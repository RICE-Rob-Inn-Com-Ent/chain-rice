import 'package:freezed_annotation/freezed_annotation.dart';

part 'hardware_power.freezed.dart';
part 'hardware_power.g.dart';

@JsonEnum(alwaysCreate: true)
enum PowerSource {
  ac,
  battery,
  poe,
}

@freezed
abstract class BatteryInfo with _$BatteryInfo {
  @JsonSerializable(explicitToJson: true)
  const factory BatteryInfo({
    required double capacityPercent,
    required double voltage,
    required double current,
    required double health,
    required bool isCharging,
  }) = _BatteryInfo;

  factory BatteryInfo.fromJson(Map<String, dynamic> json) =>
      _$BatteryInfoFromJson(json);
}

@freezed
abstract class PowerSupply with _$PowerSupply {
  @JsonSerializable(explicitToJson: true)
  const factory PowerSupply({
    required PowerSource source,
    required double consumptionWatts,
    BatteryInfo? battery,
  }) = _PowerSupply;

  factory PowerSupply.fromJson(Map<String, dynamic> json) =>
      _$PowerSupplyFromJson(json);
}
