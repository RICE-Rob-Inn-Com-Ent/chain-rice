import 'package:freezed_annotation/freezed_annotation.dart';

part 'hardware_cpu.freezed.dart';
part 'hardware_cpu.g.dart';

@freezed
abstract class CpuCore with _$CpuCore {
  @JsonSerializable(explicitToJson: true)
  const factory CpuCore({
    required int id,
    required double load,
    required double frequency,
    required double temp,
  }) = _CpuCore;

  factory CpuCore.fromJson(Map<String, dynamic> json) =>
      _$CpuCoreFromJson(json);
}

@freezed
abstract class CpuInfo with _$CpuInfo {
  @JsonSerializable(explicitToJson: true)
  const factory CpuInfo({
    required String model,
    required String architecture,
    required String vendor,
    required int logicalCores,
    required int physicalPackages,
  }) = _CpuInfo;

  factory CpuInfo.fromJson(Map<String, dynamic> json) =>
      _$CpuInfoFromJson(json);
}

@freezed
abstract class CpuTopology with _$CpuTopology {
  @JsonSerializable(explicitToJson: true)
  const factory CpuTopology({
    int? cacheL1Kb,
    int? cacheL2Kb,
    int? cacheL3Kb,
    @Default(1) int numaNodes,
  }) = _CpuTopology;

  factory CpuTopology.fromJson(Map<String, dynamic> json) =>
      _$CpuTopologyFromJson(json);
}
