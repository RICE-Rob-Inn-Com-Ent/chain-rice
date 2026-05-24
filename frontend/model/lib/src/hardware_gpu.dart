import 'package:freezed_annotation/freezed_annotation.dart';

import 'common.dart';

part 'hardware_gpu.freezed.dart';
part 'hardware_gpu.g.dart';

@freezed
abstract class GpuMemory with _$GpuMemory {
  @JsonSerializable(explicitToJson: true)
  const factory GpuMemory({
    required int totalBytes,
    required int usedBytes,
    required int freeBytes,
  }) = _GpuMemory;

  factory GpuMemory.fromJson(Map<String, dynamic> json) =>
      _$GpuMemoryFromJson(json);
}

/// Вендор-специфічні GPU: NVIDIA vs generic (інтегровані / інші DRM).
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class GpuInfo with _$GpuInfo {
  @JsonSerializable(explicitToJson: true)
  const factory GpuInfo.nvidia({
    required String model,
    required String vendor,
    required String uuid,
    required GpuMemory memory,
    required double temperatureC,
    required DataUnit powerUsage,
    required String pcieStatus,
  }) = GpuInfoNvidia;

  @JsonSerializable(explicitToJson: true)
  const factory GpuInfo.generic({
    required String model,
    required String vendor,
    String? uuid,
    required GpuMemory memory,
    double? temperatureC,
    DataUnit? powerUsage,
    String? pcieStatus,
  }) = GpuInfoGeneric;

  factory GpuInfo.fromJson(Map<String, dynamic> json) =>
      _$GpuInfoFromJson(json);
}
