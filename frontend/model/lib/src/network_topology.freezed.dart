// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_topology.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkInterface {
  String get name;
  String get mac;
  String? get ipV4;
  String? get ipV6;
  NetworkInterfaceType get type;

  /// Create a copy of NetworkInterface
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NetworkInterfaceCopyWith<NetworkInterface> get copyWith =>
      _$NetworkInterfaceCopyWithImpl<NetworkInterface>(
          this as NetworkInterface, _$identity);

  /// Serializes this NetworkInterface to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NetworkInterface &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mac, mac) || other.mac == mac) &&
            (identical(other.ipV4, ipV4) || other.ipV4 == ipV4) &&
            (identical(other.ipV6, ipV6) || other.ipV6 == ipV6) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, mac, ipV4, ipV6, type);

  @override
  String toString() {
    return 'NetworkInterface(name: $name, mac: $mac, ipV4: $ipV4, ipV6: $ipV6, type: $type)';
  }
}

/// @nodoc
abstract mixin class $NetworkInterfaceCopyWith<$Res> {
  factory $NetworkInterfaceCopyWith(
          NetworkInterface value, $Res Function(NetworkInterface) _then) =
      _$NetworkInterfaceCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String mac,
      String? ipV4,
      String? ipV6,
      NetworkInterfaceType type});
}

/// @nodoc
class _$NetworkInterfaceCopyWithImpl<$Res>
    implements $NetworkInterfaceCopyWith<$Res> {
  _$NetworkInterfaceCopyWithImpl(this._self, this._then);

  final NetworkInterface _self;
  final $Res Function(NetworkInterface) _then;

  /// Create a copy of NetworkInterface
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? mac = null,
    Object? ipV4 = freezed,
    Object? ipV6 = freezed,
    Object? type = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      mac: null == mac
          ? _self.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String,
      ipV4: freezed == ipV4
          ? _self.ipV4
          : ipV4 // ignore: cast_nullable_to_non_nullable
              as String?,
      ipV6: freezed == ipV6
          ? _self.ipV6
          : ipV6 // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NetworkInterfaceType,
    ));
  }
}

/// Adds pattern-matching-related methods to [NetworkInterface].
extension NetworkInterfacePatterns on NetworkInterface {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_NetworkInterface value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_NetworkInterface value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_NetworkInterface value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String name, String mac, String? ipV4, String? ipV6,
            NetworkInterfaceType type)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface() when $default != null:
        return $default(
            _that.name, _that.mac, _that.ipV4, _that.ipV6, _that.type);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String name, String mac, String? ipV4, String? ipV6,
            NetworkInterfaceType type)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface():
        return $default(
            _that.name, _that.mac, _that.ipV4, _that.ipV6, _that.type);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String name, String mac, String? ipV4, String? ipV6,
            NetworkInterfaceType type)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkInterface() when $default != null:
        return $default(
            _that.name, _that.mac, _that.ipV4, _that.ipV6, _that.type);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _NetworkInterface implements NetworkInterface {
  const _NetworkInterface(
      {required this.name,
      required this.mac,
      this.ipV4,
      this.ipV6,
      required this.type});
  factory _NetworkInterface.fromJson(Map<String, dynamic> json) =>
      _$NetworkInterfaceFromJson(json);

  @override
  final String name;
  @override
  final String mac;
  @override
  final String? ipV4;
  @override
  final String? ipV6;
  @override
  final NetworkInterfaceType type;

  /// Create a copy of NetworkInterface
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NetworkInterfaceCopyWith<_NetworkInterface> get copyWith =>
      __$NetworkInterfaceCopyWithImpl<_NetworkInterface>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NetworkInterfaceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NetworkInterface &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mac, mac) || other.mac == mac) &&
            (identical(other.ipV4, ipV4) || other.ipV4 == ipV4) &&
            (identical(other.ipV6, ipV6) || other.ipV6 == ipV6) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, mac, ipV4, ipV6, type);

  @override
  String toString() {
    return 'NetworkInterface(name: $name, mac: $mac, ipV4: $ipV4, ipV6: $ipV6, type: $type)';
  }
}

/// @nodoc
abstract mixin class _$NetworkInterfaceCopyWith<$Res>
    implements $NetworkInterfaceCopyWith<$Res> {
  factory _$NetworkInterfaceCopyWith(
          _NetworkInterface value, $Res Function(_NetworkInterface) _then) =
      __$NetworkInterfaceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String mac,
      String? ipV4,
      String? ipV6,
      NetworkInterfaceType type});
}

/// @nodoc
class __$NetworkInterfaceCopyWithImpl<$Res>
    implements _$NetworkInterfaceCopyWith<$Res> {
  __$NetworkInterfaceCopyWithImpl(this._self, this._then);

  final _NetworkInterface _self;
  final $Res Function(_NetworkInterface) _then;

  /// Create a copy of NetworkInterface
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? mac = null,
    Object? ipV4 = freezed,
    Object? ipV6 = freezed,
    Object? type = null,
  }) {
    return _then(_NetworkInterface(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      mac: null == mac
          ? _self.mac
          : mac // ignore: cast_nullable_to_non_nullable
              as String,
      ipV4: freezed == ipV4
          ? _self.ipV4
          : ipV4 // ignore: cast_nullable_to_non_nullable
              as String?,
      ipV6: freezed == ipV6
          ? _self.ipV6
          : ipV6 // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NetworkInterfaceType,
    ));
  }
}

/// @nodoc
mixin _$SocketNode {
  String get localAddress;
  String? get remoteAddress;
  SocketState get state;
  SocketProtocol get protocol;

  /// Create a copy of SocketNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SocketNodeCopyWith<SocketNode> get copyWith =>
      _$SocketNodeCopyWithImpl<SocketNode>(this as SocketNode, _$identity);

  /// Serializes this SocketNode to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SocketNode &&
            (identical(other.localAddress, localAddress) ||
                other.localAddress == localAddress) &&
            (identical(other.remoteAddress, remoteAddress) ||
                other.remoteAddress == remoteAddress) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, localAddress, remoteAddress, state, protocol);

  @override
  String toString() {
    return 'SocketNode(localAddress: $localAddress, remoteAddress: $remoteAddress, state: $state, protocol: $protocol)';
  }
}

/// @nodoc
abstract mixin class $SocketNodeCopyWith<$Res> {
  factory $SocketNodeCopyWith(
          SocketNode value, $Res Function(SocketNode) _then) =
      _$SocketNodeCopyWithImpl;
  @useResult
  $Res call(
      {String localAddress,
      String? remoteAddress,
      SocketState state,
      SocketProtocol protocol});
}

/// @nodoc
class _$SocketNodeCopyWithImpl<$Res> implements $SocketNodeCopyWith<$Res> {
  _$SocketNodeCopyWithImpl(this._self, this._then);

  final SocketNode _self;
  final $Res Function(SocketNode) _then;

  /// Create a copy of SocketNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localAddress = null,
    Object? remoteAddress = freezed,
    Object? state = null,
    Object? protocol = null,
  }) {
    return _then(_self.copyWith(
      localAddress: null == localAddress
          ? _self.localAddress
          : localAddress // ignore: cast_nullable_to_non_nullable
              as String,
      remoteAddress: freezed == remoteAddress
          ? _self.remoteAddress
          : remoteAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as SocketState,
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as SocketProtocol,
    ));
  }
}

/// Adds pattern-matching-related methods to [SocketNode].
extension SocketNodePatterns on SocketNode {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SocketNode value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocketNode() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SocketNode value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocketNode():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SocketNode value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocketNode() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String localAddress, String? remoteAddress,
            SocketState state, SocketProtocol protocol)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocketNode() when $default != null:
        return $default(_that.localAddress, _that.remoteAddress, _that.state,
            _that.protocol);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String localAddress, String? remoteAddress,
            SocketState state, SocketProtocol protocol)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocketNode():
        return $default(_that.localAddress, _that.remoteAddress, _that.state,
            _that.protocol);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String localAddress, String? remoteAddress,
            SocketState state, SocketProtocol protocol)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocketNode() when $default != null:
        return $default(_that.localAddress, _that.remoteAddress, _that.state,
            _that.protocol);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SocketNode implements SocketNode {
  const _SocketNode(
      {required this.localAddress,
      this.remoteAddress,
      required this.state,
      required this.protocol});
  factory _SocketNode.fromJson(Map<String, dynamic> json) =>
      _$SocketNodeFromJson(json);

  @override
  final String localAddress;
  @override
  final String? remoteAddress;
  @override
  final SocketState state;
  @override
  final SocketProtocol protocol;

  /// Create a copy of SocketNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SocketNodeCopyWith<_SocketNode> get copyWith =>
      __$SocketNodeCopyWithImpl<_SocketNode>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SocketNodeToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SocketNode &&
            (identical(other.localAddress, localAddress) ||
                other.localAddress == localAddress) &&
            (identical(other.remoteAddress, remoteAddress) ||
                other.remoteAddress == remoteAddress) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, localAddress, remoteAddress, state, protocol);

  @override
  String toString() {
    return 'SocketNode(localAddress: $localAddress, remoteAddress: $remoteAddress, state: $state, protocol: $protocol)';
  }
}

/// @nodoc
abstract mixin class _$SocketNodeCopyWith<$Res>
    implements $SocketNodeCopyWith<$Res> {
  factory _$SocketNodeCopyWith(
          _SocketNode value, $Res Function(_SocketNode) _then) =
      __$SocketNodeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String localAddress,
      String? remoteAddress,
      SocketState state,
      SocketProtocol protocol});
}

/// @nodoc
class __$SocketNodeCopyWithImpl<$Res> implements _$SocketNodeCopyWith<$Res> {
  __$SocketNodeCopyWithImpl(this._self, this._then);

  final _SocketNode _self;
  final $Res Function(_SocketNode) _then;

  /// Create a copy of SocketNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? localAddress = null,
    Object? remoteAddress = freezed,
    Object? state = null,
    Object? protocol = null,
  }) {
    return _then(_SocketNode(
      localAddress: null == localAddress
          ? _self.localAddress
          : localAddress // ignore: cast_nullable_to_non_nullable
              as String,
      remoteAddress: freezed == remoteAddress
          ? _self.remoteAddress
          : remoteAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as SocketState,
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as SocketProtocol,
    ));
  }
}

/// @nodoc
mixin _$DiscoveryNode {
  String get serviceName;
  int get port;
  Map<String, String> get metadata;

  /// Create a copy of DiscoveryNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DiscoveryNodeCopyWith<DiscoveryNode> get copyWith =>
      _$DiscoveryNodeCopyWithImpl<DiscoveryNode>(
          this as DiscoveryNode, _$identity);

  /// Serializes this DiscoveryNode to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DiscoveryNode &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.port, port) || other.port == port) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, serviceName, port,
      const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'DiscoveryNode(serviceName: $serviceName, port: $port, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $DiscoveryNodeCopyWith<$Res> {
  factory $DiscoveryNodeCopyWith(
          DiscoveryNode value, $Res Function(DiscoveryNode) _then) =
      _$DiscoveryNodeCopyWithImpl;
  @useResult
  $Res call({String serviceName, int port, Map<String, String> metadata});
}

/// @nodoc
class _$DiscoveryNodeCopyWithImpl<$Res>
    implements $DiscoveryNodeCopyWith<$Res> {
  _$DiscoveryNodeCopyWithImpl(this._self, this._then);

  final DiscoveryNode _self;
  final $Res Function(DiscoveryNode) _then;

  /// Create a copy of DiscoveryNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serviceName = null,
    Object? port = null,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      serviceName: null == serviceName
          ? _self.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DiscoveryNode].
extension DiscoveryNodePatterns on DiscoveryNode {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DiscoveryNode value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DiscoveryNode value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DiscoveryNode value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String serviceName, int port, Map<String, String> metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode() when $default != null:
        return $default(_that.serviceName, _that.port, _that.metadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String serviceName, int port, Map<String, String> metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode():
        return $default(_that.serviceName, _that.port, _that.metadata);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String serviceName, int port, Map<String, String> metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscoveryNode() when $default != null:
        return $default(_that.serviceName, _that.port, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DiscoveryNode implements DiscoveryNode {
  const _DiscoveryNode(
      {required this.serviceName,
      required this.port,
      final Map<String, String> metadata = const <String, String>{}})
      : _metadata = metadata;
  factory _DiscoveryNode.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryNodeFromJson(json);

  @override
  final String serviceName;
  @override
  final int port;
  final Map<String, String> _metadata;
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Create a copy of DiscoveryNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DiscoveryNodeCopyWith<_DiscoveryNode> get copyWith =>
      __$DiscoveryNodeCopyWithImpl<_DiscoveryNode>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DiscoveryNodeToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DiscoveryNode &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.port, port) || other.port == port) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, serviceName, port,
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'DiscoveryNode(serviceName: $serviceName, port: $port, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$DiscoveryNodeCopyWith<$Res>
    implements $DiscoveryNodeCopyWith<$Res> {
  factory _$DiscoveryNodeCopyWith(
          _DiscoveryNode value, $Res Function(_DiscoveryNode) _then) =
      __$DiscoveryNodeCopyWithImpl;
  @override
  @useResult
  $Res call({String serviceName, int port, Map<String, String> metadata});
}

/// @nodoc
class __$DiscoveryNodeCopyWithImpl<$Res>
    implements _$DiscoveryNodeCopyWith<$Res> {
  __$DiscoveryNodeCopyWithImpl(this._self, this._then);

  final _DiscoveryNode _self;
  final $Res Function(_DiscoveryNode) _then;

  /// Create a copy of DiscoveryNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? serviceName = null,
    Object? port = null,
    Object? metadata = null,
  }) {
    return _then(_DiscoveryNode(
      serviceName: null == serviceName
          ? _self.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

// dart format on
