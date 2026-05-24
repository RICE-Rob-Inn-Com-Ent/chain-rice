// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'atlas.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemAtlas {
  int get formatVersion;
  DateTime get timestamp;
  CpuInfo get cpu;
  List<GpuInfo> get gpus;
  List<NetworkInterface> get network;
  List<SocketNode> get sockets;
  List<DiscoveryNode> get discoveries;
  List<InputDevice> get inputs;
  List<DisplayInfo> get displays;
  List<InputCapabilities> get inputCapabilities;
  List<MotorControl> get actuators;
  List<PwmChannel> get pwmChannels;
  List<GpioPin> get gpioPins;
  CpuTopology? get cpuTopology;
  PowerSupply? get power;
  ImuData? get imu;
  VisionSpec? get vision;
  SdrSpectrum? get sdr;
  Map<String, dynamic> get customMetadata;

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SystemAtlasCopyWith<SystemAtlas> get copyWith =>
      _$SystemAtlasCopyWithImpl<SystemAtlas>(this as SystemAtlas, _$identity);

  /// Serializes this SystemAtlas to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SystemAtlas &&
            (identical(other.formatVersion, formatVersion) ||
                other.formatVersion == formatVersion) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            const DeepCollectionEquality().equals(other.gpus, gpus) &&
            const DeepCollectionEquality().equals(other.network, network) &&
            const DeepCollectionEquality().equals(other.sockets, sockets) &&
            const DeepCollectionEquality()
                .equals(other.discoveries, discoveries) &&
            const DeepCollectionEquality().equals(other.inputs, inputs) &&
            const DeepCollectionEquality().equals(other.displays, displays) &&
            const DeepCollectionEquality()
                .equals(other.inputCapabilities, inputCapabilities) &&
            const DeepCollectionEquality().equals(other.actuators, actuators) &&
            const DeepCollectionEquality()
                .equals(other.pwmChannels, pwmChannels) &&
            const DeepCollectionEquality().equals(other.gpioPins, gpioPins) &&
            (identical(other.cpuTopology, cpuTopology) ||
                other.cpuTopology == cpuTopology) &&
            (identical(other.power, power) || other.power == power) &&
            (identical(other.imu, imu) || other.imu == imu) &&
            (identical(other.vision, vision) || other.vision == vision) &&
            (identical(other.sdr, sdr) || other.sdr == sdr) &&
            const DeepCollectionEquality()
                .equals(other.customMetadata, customMetadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        formatVersion,
        timestamp,
        cpu,
        const DeepCollectionEquality().hash(gpus),
        const DeepCollectionEquality().hash(network),
        const DeepCollectionEquality().hash(sockets),
        const DeepCollectionEquality().hash(discoveries),
        const DeepCollectionEquality().hash(inputs),
        const DeepCollectionEquality().hash(displays),
        const DeepCollectionEquality().hash(inputCapabilities),
        const DeepCollectionEquality().hash(actuators),
        const DeepCollectionEquality().hash(pwmChannels),
        const DeepCollectionEquality().hash(gpioPins),
        cpuTopology,
        power,
        imu,
        vision,
        sdr,
        const DeepCollectionEquality().hash(customMetadata)
      ]);

  @override
  String toString() {
    return 'SystemAtlas(formatVersion: $formatVersion, timestamp: $timestamp, cpu: $cpu, gpus: $gpus, network: $network, sockets: $sockets, discoveries: $discoveries, inputs: $inputs, displays: $displays, inputCapabilities: $inputCapabilities, actuators: $actuators, pwmChannels: $pwmChannels, gpioPins: $gpioPins, cpuTopology: $cpuTopology, power: $power, imu: $imu, vision: $vision, sdr: $sdr, customMetadata: $customMetadata)';
  }
}

/// @nodoc
abstract mixin class $SystemAtlasCopyWith<$Res> {
  factory $SystemAtlasCopyWith(
          SystemAtlas value, $Res Function(SystemAtlas) _then) =
      _$SystemAtlasCopyWithImpl;
  @useResult
  $Res call(
      {int formatVersion,
      DateTime timestamp,
      CpuInfo cpu,
      List<GpuInfo> gpus,
      List<NetworkInterface> network,
      List<SocketNode> sockets,
      List<DiscoveryNode> discoveries,
      List<InputDevice> inputs,
      List<DisplayInfo> displays,
      List<InputCapabilities> inputCapabilities,
      List<MotorControl> actuators,
      List<PwmChannel> pwmChannels,
      List<GpioPin> gpioPins,
      CpuTopology? cpuTopology,
      PowerSupply? power,
      ImuData? imu,
      VisionSpec? vision,
      SdrSpectrum? sdr,
      Map<String, dynamic> customMetadata});

  $CpuInfoCopyWith<$Res> get cpu;
  $CpuTopologyCopyWith<$Res>? get cpuTopology;
  $PowerSupplyCopyWith<$Res>? get power;
  $ImuDataCopyWith<$Res>? get imu;
  $VisionSpecCopyWith<$Res>? get vision;
  $SdrSpectrumCopyWith<$Res>? get sdr;
}

/// @nodoc
class _$SystemAtlasCopyWithImpl<$Res> implements $SystemAtlasCopyWith<$Res> {
  _$SystemAtlasCopyWithImpl(this._self, this._then);

  final SystemAtlas _self;
  final $Res Function(SystemAtlas) _then;

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formatVersion = null,
    Object? timestamp = null,
    Object? cpu = null,
    Object? gpus = null,
    Object? network = null,
    Object? sockets = null,
    Object? discoveries = null,
    Object? inputs = null,
    Object? displays = null,
    Object? inputCapabilities = null,
    Object? actuators = null,
    Object? pwmChannels = null,
    Object? gpioPins = null,
    Object? cpuTopology = freezed,
    Object? power = freezed,
    Object? imu = freezed,
    Object? vision = freezed,
    Object? sdr = freezed,
    Object? customMetadata = null,
  }) {
    return _then(_self.copyWith(
      formatVersion: null == formatVersion
          ? _self.formatVersion
          : formatVersion // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cpu: null == cpu
          ? _self.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuInfo,
      gpus: null == gpus
          ? _self.gpus
          : gpus // ignore: cast_nullable_to_non_nullable
              as List<GpuInfo>,
      network: null == network
          ? _self.network
          : network // ignore: cast_nullable_to_non_nullable
              as List<NetworkInterface>,
      sockets: null == sockets
          ? _self.sockets
          : sockets // ignore: cast_nullable_to_non_nullable
              as List<SocketNode>,
      discoveries: null == discoveries
          ? _self.discoveries
          : discoveries // ignore: cast_nullable_to_non_nullable
              as List<DiscoveryNode>,
      inputs: null == inputs
          ? _self.inputs
          : inputs // ignore: cast_nullable_to_non_nullable
              as List<InputDevice>,
      displays: null == displays
          ? _self.displays
          : displays // ignore: cast_nullable_to_non_nullable
              as List<DisplayInfo>,
      inputCapabilities: null == inputCapabilities
          ? _self.inputCapabilities
          : inputCapabilities // ignore: cast_nullable_to_non_nullable
              as List<InputCapabilities>,
      actuators: null == actuators
          ? _self.actuators
          : actuators // ignore: cast_nullable_to_non_nullable
              as List<MotorControl>,
      pwmChannels: null == pwmChannels
          ? _self.pwmChannels
          : pwmChannels // ignore: cast_nullable_to_non_nullable
              as List<PwmChannel>,
      gpioPins: null == gpioPins
          ? _self.gpioPins
          : gpioPins // ignore: cast_nullable_to_non_nullable
              as List<GpioPin>,
      cpuTopology: freezed == cpuTopology
          ? _self.cpuTopology
          : cpuTopology // ignore: cast_nullable_to_non_nullable
              as CpuTopology?,
      power: freezed == power
          ? _self.power
          : power // ignore: cast_nullable_to_non_nullable
              as PowerSupply?,
      imu: freezed == imu
          ? _self.imu
          : imu // ignore: cast_nullable_to_non_nullable
              as ImuData?,
      vision: freezed == vision
          ? _self.vision
          : vision // ignore: cast_nullable_to_non_nullable
              as VisionSpec?,
      sdr: freezed == sdr
          ? _self.sdr
          : sdr // ignore: cast_nullable_to_non_nullable
              as SdrSpectrum?,
      customMetadata: null == customMetadata
          ? _self.customMetadata
          : customMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuInfoCopyWith<$Res> get cpu {
    return $CpuInfoCopyWith<$Res>(_self.cpu, (value) {
      return _then(_self.copyWith(cpu: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuTopologyCopyWith<$Res>? get cpuTopology {
    if (_self.cpuTopology == null) {
      return null;
    }

    return $CpuTopologyCopyWith<$Res>(_self.cpuTopology!, (value) {
      return _then(_self.copyWith(cpuTopology: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PowerSupplyCopyWith<$Res>? get power {
    if (_self.power == null) {
      return null;
    }

    return $PowerSupplyCopyWith<$Res>(_self.power!, (value) {
      return _then(_self.copyWith(power: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImuDataCopyWith<$Res>? get imu {
    if (_self.imu == null) {
      return null;
    }

    return $ImuDataCopyWith<$Res>(_self.imu!, (value) {
      return _then(_self.copyWith(imu: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisionSpecCopyWith<$Res>? get vision {
    if (_self.vision == null) {
      return null;
    }

    return $VisionSpecCopyWith<$Res>(_self.vision!, (value) {
      return _then(_self.copyWith(vision: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SdrSpectrumCopyWith<$Res>? get sdr {
    if (_self.sdr == null) {
      return null;
    }

    return $SdrSpectrumCopyWith<$Res>(_self.sdr!, (value) {
      return _then(_self.copyWith(sdr: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SystemAtlas].
extension SystemAtlasPatterns on SystemAtlas {
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
    TResult Function(_SystemAtlas value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas() when $default != null:
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
    TResult Function(_SystemAtlas value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas():
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
    TResult? Function(_SystemAtlas value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas() when $default != null:
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
            int formatVersion,
            DateTime timestamp,
            CpuInfo cpu,
            List<GpuInfo> gpus,
            List<NetworkInterface> network,
            List<SocketNode> sockets,
            List<DiscoveryNode> discoveries,
            List<InputDevice> inputs,
            List<DisplayInfo> displays,
            List<InputCapabilities> inputCapabilities,
            List<MotorControl> actuators,
            List<PwmChannel> pwmChannels,
            List<GpioPin> gpioPins,
            CpuTopology? cpuTopology,
            PowerSupply? power,
            ImuData? imu,
            VisionSpec? vision,
            SdrSpectrum? sdr,
            Map<String, dynamic> customMetadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas() when $default != null:
        return $default(
            _that.formatVersion,
            _that.timestamp,
            _that.cpu,
            _that.gpus,
            _that.network,
            _that.sockets,
            _that.discoveries,
            _that.inputs,
            _that.displays,
            _that.inputCapabilities,
            _that.actuators,
            _that.pwmChannels,
            _that.gpioPins,
            _that.cpuTopology,
            _that.power,
            _that.imu,
            _that.vision,
            _that.sdr,
            _that.customMetadata);
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
    TResult Function(
            int formatVersion,
            DateTime timestamp,
            CpuInfo cpu,
            List<GpuInfo> gpus,
            List<NetworkInterface> network,
            List<SocketNode> sockets,
            List<DiscoveryNode> discoveries,
            List<InputDevice> inputs,
            List<DisplayInfo> displays,
            List<InputCapabilities> inputCapabilities,
            List<MotorControl> actuators,
            List<PwmChannel> pwmChannels,
            List<GpioPin> gpioPins,
            CpuTopology? cpuTopology,
            PowerSupply? power,
            ImuData? imu,
            VisionSpec? vision,
            SdrSpectrum? sdr,
            Map<String, dynamic> customMetadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas():
        return $default(
            _that.formatVersion,
            _that.timestamp,
            _that.cpu,
            _that.gpus,
            _that.network,
            _that.sockets,
            _that.discoveries,
            _that.inputs,
            _that.displays,
            _that.inputCapabilities,
            _that.actuators,
            _that.pwmChannels,
            _that.gpioPins,
            _that.cpuTopology,
            _that.power,
            _that.imu,
            _that.vision,
            _that.sdr,
            _that.customMetadata);
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
            int formatVersion,
            DateTime timestamp,
            CpuInfo cpu,
            List<GpuInfo> gpus,
            List<NetworkInterface> network,
            List<SocketNode> sockets,
            List<DiscoveryNode> discoveries,
            List<InputDevice> inputs,
            List<DisplayInfo> displays,
            List<InputCapabilities> inputCapabilities,
            List<MotorControl> actuators,
            List<PwmChannel> pwmChannels,
            List<GpioPin> gpioPins,
            CpuTopology? cpuTopology,
            PowerSupply? power,
            ImuData? imu,
            VisionSpec? vision,
            SdrSpectrum? sdr,
            Map<String, dynamic> customMetadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAtlas() when $default != null:
        return $default(
            _that.formatVersion,
            _that.timestamp,
            _that.cpu,
            _that.gpus,
            _that.network,
            _that.sockets,
            _that.discoveries,
            _that.inputs,
            _that.displays,
            _that.inputCapabilities,
            _that.actuators,
            _that.pwmChannels,
            _that.gpioPins,
            _that.cpuTopology,
            _that.power,
            _that.imu,
            _that.vision,
            _that.sdr,
            _that.customMetadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SystemAtlas implements SystemAtlas {
  const _SystemAtlas(
      {this.formatVersion = 1,
      required this.timestamp,
      required this.cpu,
      final List<GpuInfo> gpus = const <GpuInfo>[],
      final List<NetworkInterface> network = const <NetworkInterface>[],
      final List<SocketNode> sockets = const <SocketNode>[],
      final List<DiscoveryNode> discoveries = const <DiscoveryNode>[],
      final List<InputDevice> inputs = const <InputDevice>[],
      final List<DisplayInfo> displays = const <DisplayInfo>[],
      final List<InputCapabilities> inputCapabilities =
          const <InputCapabilities>[],
      final List<MotorControl> actuators = const <MotorControl>[],
      final List<PwmChannel> pwmChannels = const <PwmChannel>[],
      final List<GpioPin> gpioPins = const <GpioPin>[],
      this.cpuTopology,
      this.power,
      this.imu,
      this.vision,
      this.sdr,
      final Map<String, dynamic> customMetadata = const <String, dynamic>{}})
      : _gpus = gpus,
        _network = network,
        _sockets = sockets,
        _discoveries = discoveries,
        _inputs = inputs,
        _displays = displays,
        _inputCapabilities = inputCapabilities,
        _actuators = actuators,
        _pwmChannels = pwmChannels,
        _gpioPins = gpioPins,
        _customMetadata = customMetadata;
  factory _SystemAtlas.fromJson(Map<String, dynamic> json) =>
      _$SystemAtlasFromJson(json);

  @override
  @JsonKey()
  final int formatVersion;
  @override
  final DateTime timestamp;
  @override
  final CpuInfo cpu;
  final List<GpuInfo> _gpus;
  @override
  @JsonKey()
  List<GpuInfo> get gpus {
    if (_gpus is EqualUnmodifiableListView) return _gpus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gpus);
  }

  final List<NetworkInterface> _network;
  @override
  @JsonKey()
  List<NetworkInterface> get network {
    if (_network is EqualUnmodifiableListView) return _network;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_network);
  }

  final List<SocketNode> _sockets;
  @override
  @JsonKey()
  List<SocketNode> get sockets {
    if (_sockets is EqualUnmodifiableListView) return _sockets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sockets);
  }

  final List<DiscoveryNode> _discoveries;
  @override
  @JsonKey()
  List<DiscoveryNode> get discoveries {
    if (_discoveries is EqualUnmodifiableListView) return _discoveries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discoveries);
  }

  final List<InputDevice> _inputs;
  @override
  @JsonKey()
  List<InputDevice> get inputs {
    if (_inputs is EqualUnmodifiableListView) return _inputs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputs);
  }

  final List<DisplayInfo> _displays;
  @override
  @JsonKey()
  List<DisplayInfo> get displays {
    if (_displays is EqualUnmodifiableListView) return _displays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_displays);
  }

  final List<InputCapabilities> _inputCapabilities;
  @override
  @JsonKey()
  List<InputCapabilities> get inputCapabilities {
    if (_inputCapabilities is EqualUnmodifiableListView)
      return _inputCapabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputCapabilities);
  }

  final List<MotorControl> _actuators;
  @override
  @JsonKey()
  List<MotorControl> get actuators {
    if (_actuators is EqualUnmodifiableListView) return _actuators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_actuators);
  }

  final List<PwmChannel> _pwmChannels;
  @override
  @JsonKey()
  List<PwmChannel> get pwmChannels {
    if (_pwmChannels is EqualUnmodifiableListView) return _pwmChannels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pwmChannels);
  }

  final List<GpioPin> _gpioPins;
  @override
  @JsonKey()
  List<GpioPin> get gpioPins {
    if (_gpioPins is EqualUnmodifiableListView) return _gpioPins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gpioPins);
  }

  @override
  final CpuTopology? cpuTopology;
  @override
  final PowerSupply? power;
  @override
  final ImuData? imu;
  @override
  final VisionSpec? vision;
  @override
  final SdrSpectrum? sdr;
  final Map<String, dynamic> _customMetadata;
  @override
  @JsonKey()
  Map<String, dynamic> get customMetadata {
    if (_customMetadata is EqualUnmodifiableMapView) return _customMetadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customMetadata);
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SystemAtlasCopyWith<_SystemAtlas> get copyWith =>
      __$SystemAtlasCopyWithImpl<_SystemAtlas>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SystemAtlasToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SystemAtlas &&
            (identical(other.formatVersion, formatVersion) ||
                other.formatVersion == formatVersion) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            const DeepCollectionEquality().equals(other._gpus, _gpus) &&
            const DeepCollectionEquality().equals(other._network, _network) &&
            const DeepCollectionEquality().equals(other._sockets, _sockets) &&
            const DeepCollectionEquality()
                .equals(other._discoveries, _discoveries) &&
            const DeepCollectionEquality().equals(other._inputs, _inputs) &&
            const DeepCollectionEquality().equals(other._displays, _displays) &&
            const DeepCollectionEquality()
                .equals(other._inputCapabilities, _inputCapabilities) &&
            const DeepCollectionEquality()
                .equals(other._actuators, _actuators) &&
            const DeepCollectionEquality()
                .equals(other._pwmChannels, _pwmChannels) &&
            const DeepCollectionEquality().equals(other._gpioPins, _gpioPins) &&
            (identical(other.cpuTopology, cpuTopology) ||
                other.cpuTopology == cpuTopology) &&
            (identical(other.power, power) || other.power == power) &&
            (identical(other.imu, imu) || other.imu == imu) &&
            (identical(other.vision, vision) || other.vision == vision) &&
            (identical(other.sdr, sdr) || other.sdr == sdr) &&
            const DeepCollectionEquality()
                .equals(other._customMetadata, _customMetadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        formatVersion,
        timestamp,
        cpu,
        const DeepCollectionEquality().hash(_gpus),
        const DeepCollectionEquality().hash(_network),
        const DeepCollectionEquality().hash(_sockets),
        const DeepCollectionEquality().hash(_discoveries),
        const DeepCollectionEquality().hash(_inputs),
        const DeepCollectionEquality().hash(_displays),
        const DeepCollectionEquality().hash(_inputCapabilities),
        const DeepCollectionEquality().hash(_actuators),
        const DeepCollectionEquality().hash(_pwmChannels),
        const DeepCollectionEquality().hash(_gpioPins),
        cpuTopology,
        power,
        imu,
        vision,
        sdr,
        const DeepCollectionEquality().hash(_customMetadata)
      ]);

  @override
  String toString() {
    return 'SystemAtlas(formatVersion: $formatVersion, timestamp: $timestamp, cpu: $cpu, gpus: $gpus, network: $network, sockets: $sockets, discoveries: $discoveries, inputs: $inputs, displays: $displays, inputCapabilities: $inputCapabilities, actuators: $actuators, pwmChannels: $pwmChannels, gpioPins: $gpioPins, cpuTopology: $cpuTopology, power: $power, imu: $imu, vision: $vision, sdr: $sdr, customMetadata: $customMetadata)';
  }
}

/// @nodoc
abstract mixin class _$SystemAtlasCopyWith<$Res>
    implements $SystemAtlasCopyWith<$Res> {
  factory _$SystemAtlasCopyWith(
          _SystemAtlas value, $Res Function(_SystemAtlas) _then) =
      __$SystemAtlasCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int formatVersion,
      DateTime timestamp,
      CpuInfo cpu,
      List<GpuInfo> gpus,
      List<NetworkInterface> network,
      List<SocketNode> sockets,
      List<DiscoveryNode> discoveries,
      List<InputDevice> inputs,
      List<DisplayInfo> displays,
      List<InputCapabilities> inputCapabilities,
      List<MotorControl> actuators,
      List<PwmChannel> pwmChannels,
      List<GpioPin> gpioPins,
      CpuTopology? cpuTopology,
      PowerSupply? power,
      ImuData? imu,
      VisionSpec? vision,
      SdrSpectrum? sdr,
      Map<String, dynamic> customMetadata});

  @override
  $CpuInfoCopyWith<$Res> get cpu;
  @override
  $CpuTopologyCopyWith<$Res>? get cpuTopology;
  @override
  $PowerSupplyCopyWith<$Res>? get power;
  @override
  $ImuDataCopyWith<$Res>? get imu;
  @override
  $VisionSpecCopyWith<$Res>? get vision;
  @override
  $SdrSpectrumCopyWith<$Res>? get sdr;
}

/// @nodoc
class __$SystemAtlasCopyWithImpl<$Res> implements _$SystemAtlasCopyWith<$Res> {
  __$SystemAtlasCopyWithImpl(this._self, this._then);

  final _SystemAtlas _self;
  final $Res Function(_SystemAtlas) _then;

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? formatVersion = null,
    Object? timestamp = null,
    Object? cpu = null,
    Object? gpus = null,
    Object? network = null,
    Object? sockets = null,
    Object? discoveries = null,
    Object? inputs = null,
    Object? displays = null,
    Object? inputCapabilities = null,
    Object? actuators = null,
    Object? pwmChannels = null,
    Object? gpioPins = null,
    Object? cpuTopology = freezed,
    Object? power = freezed,
    Object? imu = freezed,
    Object? vision = freezed,
    Object? sdr = freezed,
    Object? customMetadata = null,
  }) {
    return _then(_SystemAtlas(
      formatVersion: null == formatVersion
          ? _self.formatVersion
          : formatVersion // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cpu: null == cpu
          ? _self.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuInfo,
      gpus: null == gpus
          ? _self._gpus
          : gpus // ignore: cast_nullable_to_non_nullable
              as List<GpuInfo>,
      network: null == network
          ? _self._network
          : network // ignore: cast_nullable_to_non_nullable
              as List<NetworkInterface>,
      sockets: null == sockets
          ? _self._sockets
          : sockets // ignore: cast_nullable_to_non_nullable
              as List<SocketNode>,
      discoveries: null == discoveries
          ? _self._discoveries
          : discoveries // ignore: cast_nullable_to_non_nullable
              as List<DiscoveryNode>,
      inputs: null == inputs
          ? _self._inputs
          : inputs // ignore: cast_nullable_to_non_nullable
              as List<InputDevice>,
      displays: null == displays
          ? _self._displays
          : displays // ignore: cast_nullable_to_non_nullable
              as List<DisplayInfo>,
      inputCapabilities: null == inputCapabilities
          ? _self._inputCapabilities
          : inputCapabilities // ignore: cast_nullable_to_non_nullable
              as List<InputCapabilities>,
      actuators: null == actuators
          ? _self._actuators
          : actuators // ignore: cast_nullable_to_non_nullable
              as List<MotorControl>,
      pwmChannels: null == pwmChannels
          ? _self._pwmChannels
          : pwmChannels // ignore: cast_nullable_to_non_nullable
              as List<PwmChannel>,
      gpioPins: null == gpioPins
          ? _self._gpioPins
          : gpioPins // ignore: cast_nullable_to_non_nullable
              as List<GpioPin>,
      cpuTopology: freezed == cpuTopology
          ? _self.cpuTopology
          : cpuTopology // ignore: cast_nullable_to_non_nullable
              as CpuTopology?,
      power: freezed == power
          ? _self.power
          : power // ignore: cast_nullable_to_non_nullable
              as PowerSupply?,
      imu: freezed == imu
          ? _self.imu
          : imu // ignore: cast_nullable_to_non_nullable
              as ImuData?,
      vision: freezed == vision
          ? _self.vision
          : vision // ignore: cast_nullable_to_non_nullable
              as VisionSpec?,
      sdr: freezed == sdr
          ? _self.sdr
          : sdr // ignore: cast_nullable_to_non_nullable
              as SdrSpectrum?,
      customMetadata: null == customMetadata
          ? _self._customMetadata
          : customMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuInfoCopyWith<$Res> get cpu {
    return $CpuInfoCopyWith<$Res>(_self.cpu, (value) {
      return _then(_self.copyWith(cpu: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuTopologyCopyWith<$Res>? get cpuTopology {
    if (_self.cpuTopology == null) {
      return null;
    }

    return $CpuTopologyCopyWith<$Res>(_self.cpuTopology!, (value) {
      return _then(_self.copyWith(cpuTopology: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PowerSupplyCopyWith<$Res>? get power {
    if (_self.power == null) {
      return null;
    }

    return $PowerSupplyCopyWith<$Res>(_self.power!, (value) {
      return _then(_self.copyWith(power: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImuDataCopyWith<$Res>? get imu {
    if (_self.imu == null) {
      return null;
    }

    return $ImuDataCopyWith<$Res>(_self.imu!, (value) {
      return _then(_self.copyWith(imu: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisionSpecCopyWith<$Res>? get vision {
    if (_self.vision == null) {
      return null;
    }

    return $VisionSpecCopyWith<$Res>(_self.vision!, (value) {
      return _then(_self.copyWith(vision: value));
    });
  }

  /// Create a copy of SystemAtlas
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SdrSpectrumCopyWith<$Res>? get sdr {
    if (_self.sdr == null) {
      return null;
    }

    return $SdrSpectrumCopyWith<$Res>(_self.sdr!, (value) {
      return _then(_self.copyWith(sdr: value));
    });
  }
}

// dart format on
