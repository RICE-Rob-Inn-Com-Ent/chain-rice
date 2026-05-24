import 'package:freezed_annotation/freezed_annotation.dart';

import 'actuators.dart';
import 'hardware_cpu.dart';
import 'hardware_gpu.dart';
import 'hardware_power.dart';
import 'network_topology.dart';
import 'peripherals_input.dart';
import 'sensors_pro.dart';

part 'atlas.freezed.dart';
part 'atlas.g.dart';

/// Головний маніфест тіла системи (.rice BARD ↔ Odin atlas / Elixir SAGE).
@freezed
abstract class SystemAtlas with _$SystemAtlas {
  @JsonSerializable(explicitToJson: true)
  const factory SystemAtlas({
    @Default(1) int formatVersion,
    required DateTime timestamp,
    required CpuInfo cpu,
    @Default(<GpuInfo>[]) List<GpuInfo> gpus,
    @Default(<NetworkInterface>[]) List<NetworkInterface> network,
    @Default(<SocketNode>[]) List<SocketNode> sockets,
    @Default(<DiscoveryNode>[]) List<DiscoveryNode> discoveries,
    @Default(<InputDevice>[]) List<InputDevice> inputs,
    @Default(<DisplayInfo>[]) List<DisplayInfo> displays,
    @Default(<InputCapabilities>[]) List<InputCapabilities> inputCapabilities,
    @Default(<MotorControl>[]) List<MotorControl> actuators,
    @Default(<PwmChannel>[]) List<PwmChannel> pwmChannels,
    @Default(<GpioPin>[]) List<GpioPin> gpioPins,
    CpuTopology? cpuTopology,
    PowerSupply? power,
    ImuData? imu,
    VisionSpec? vision,
    SdrSpectrum? sdr,
    @Default(<String, dynamic>{}) Map<String, dynamic> customMetadata,
  }) = _SystemAtlas;

  factory SystemAtlas.fromJson(Map<String, dynamic> json) =>
      _$SystemAtlasFromJson(json);
}
