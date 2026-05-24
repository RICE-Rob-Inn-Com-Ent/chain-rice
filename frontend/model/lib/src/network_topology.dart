import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_topology.freezed.dart';
part 'network_topology.g.dart';

@JsonEnum(alwaysCreate: true)
enum NetworkInterfaceType {
  wifi,
  ethernet,
  virtual,
}

@JsonEnum(alwaysCreate: true)
enum SocketState {
  listen,
  established,
}

@JsonEnum(alwaysCreate: true)
enum SocketProtocol {
  tcp,
  udp,
}

@freezed
abstract class NetworkInterface with _$NetworkInterface {
  @JsonSerializable(explicitToJson: true)
  const factory NetworkInterface({
    required String name,
    required String mac,
    String? ipV4,
    String? ipV6,
    required NetworkInterfaceType type,
  }) = _NetworkInterface;

  factory NetworkInterface.fromJson(Map<String, dynamic> json) =>
      _$NetworkInterfaceFromJson(json);
}

@freezed
abstract class SocketNode with _$SocketNode {
  @JsonSerializable(explicitToJson: true)
  const factory SocketNode({
    required String localAddress,
    String? remoteAddress,
    required SocketState state,
    required SocketProtocol protocol,
  }) = _SocketNode;

  factory SocketNode.fromJson(Map<String, dynamic> json) =>
      _$SocketNodeFromJson(json);
}

@freezed
abstract class DiscoveryNode with _$DiscoveryNode {
  @JsonSerializable(explicitToJson: true)
  const factory DiscoveryNode({
    required String serviceName,
    required int port,
    @Default(<String, String>{}) Map<String, String> metadata,
  }) = _DiscoveryNode;

  factory DiscoveryNode.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryNodeFromJson(json);
}
