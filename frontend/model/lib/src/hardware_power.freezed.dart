// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hardware_power.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BatteryInfo {
  double get capacityPercent;
  double get voltage;
  double get current;
  double get health;
  bool get isCharging;

  /// Create a copy of BatteryInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BatteryInfoCopyWith<BatteryInfo> get copyWith =>
      _$BatteryInfoCopyWithImpl<BatteryInfo>(this as BatteryInfo, _$identity);

  /// Serializes this BatteryInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BatteryInfo &&
            (identical(other.capacityPercent, capacityPercent) ||
                other.capacityPercent == capacityPercent) &&
            (identical(other.voltage, voltage) || other.voltage == voltage) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.health, health) || other.health == health) &&
            (identical(other.isCharging, isCharging) ||
                other.isCharging == isCharging));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, capacityPercent, voltage, current, health, isCharging);

  @override
  String toString() {
    return 'BatteryInfo(capacityPercent: $capacityPercent, voltage: $voltage, current: $current, health: $health, isCharging: $isCharging)';
  }
}

/// @nodoc
abstract mixin class $BatteryInfoCopyWith<$Res> {
  factory $BatteryInfoCopyWith(
          BatteryInfo value, $Res Function(BatteryInfo) _then) =
      _$BatteryInfoCopyWithImpl;
  @useResult
  $Res call(
      {double capacityPercent,
      double voltage,
      double current,
      double health,
      bool isCharging});
}

/// @nodoc
class _$BatteryInfoCopyWithImpl<$Res> implements $BatteryInfoCopyWith<$Res> {
  _$BatteryInfoCopyWithImpl(this._self, this._then);

  final BatteryInfo _self;
  final $Res Function(BatteryInfo) _then;

  /// Create a copy of BatteryInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? capacityPercent = null,
    Object? voltage = null,
    Object? current = null,
    Object? health = null,
    Object? isCharging = null,
  }) {
    return _then(_self.copyWith(
      capacityPercent: null == capacityPercent
          ? _self.capacityPercent
          : capacityPercent // ignore: cast_nullable_to_non_nullable
              as double,
      voltage: null == voltage
          ? _self.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
      current: null == current
          ? _self.current
          : current // ignore: cast_nullable_to_non_nullable
              as double,
      health: null == health
          ? _self.health
          : health // ignore: cast_nullable_to_non_nullable
              as double,
      isCharging: null == isCharging
          ? _self.isCharging
          : isCharging // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [BatteryInfo].
extension BatteryInfoPatterns on BatteryInfo {
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
    TResult Function(_BatteryInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo() when $default != null:
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
    TResult Function(_BatteryInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo():
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
    TResult? Function(_BatteryInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo() when $default != null:
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
    TResult Function(double capacityPercent, double voltage, double current,
            double health, bool isCharging)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo() when $default != null:
        return $default(_that.capacityPercent, _that.voltage, _that.current,
            _that.health, _that.isCharging);
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
    TResult Function(double capacityPercent, double voltage, double current,
            double health, bool isCharging)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo():
        return $default(_that.capacityPercent, _that.voltage, _that.current,
            _that.health, _that.isCharging);
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
    TResult? Function(double capacityPercent, double voltage, double current,
            double health, bool isCharging)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatteryInfo() when $default != null:
        return $default(_that.capacityPercent, _that.voltage, _that.current,
            _that.health, _that.isCharging);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _BatteryInfo implements BatteryInfo {
  const _BatteryInfo(
      {required this.capacityPercent,
      required this.voltage,
      required this.current,
      required this.health,
      required this.isCharging});
  factory _BatteryInfo.fromJson(Map<String, dynamic> json) =>
      _$BatteryInfoFromJson(json);

  @override
  final double capacityPercent;
  @override
  final double voltage;
  @override
  final double current;
  @override
  final double health;
  @override
  final bool isCharging;

  /// Create a copy of BatteryInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BatteryInfoCopyWith<_BatteryInfo> get copyWith =>
      __$BatteryInfoCopyWithImpl<_BatteryInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BatteryInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BatteryInfo &&
            (identical(other.capacityPercent, capacityPercent) ||
                other.capacityPercent == capacityPercent) &&
            (identical(other.voltage, voltage) || other.voltage == voltage) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.health, health) || other.health == health) &&
            (identical(other.isCharging, isCharging) ||
                other.isCharging == isCharging));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, capacityPercent, voltage, current, health, isCharging);

  @override
  String toString() {
    return 'BatteryInfo(capacityPercent: $capacityPercent, voltage: $voltage, current: $current, health: $health, isCharging: $isCharging)';
  }
}

/// @nodoc
abstract mixin class _$BatteryInfoCopyWith<$Res>
    implements $BatteryInfoCopyWith<$Res> {
  factory _$BatteryInfoCopyWith(
          _BatteryInfo value, $Res Function(_BatteryInfo) _then) =
      __$BatteryInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double capacityPercent,
      double voltage,
      double current,
      double health,
      bool isCharging});
}

/// @nodoc
class __$BatteryInfoCopyWithImpl<$Res> implements _$BatteryInfoCopyWith<$Res> {
  __$BatteryInfoCopyWithImpl(this._self, this._then);

  final _BatteryInfo _self;
  final $Res Function(_BatteryInfo) _then;

  /// Create a copy of BatteryInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? capacityPercent = null,
    Object? voltage = null,
    Object? current = null,
    Object? health = null,
    Object? isCharging = null,
  }) {
    return _then(_BatteryInfo(
      capacityPercent: null == capacityPercent
          ? _self.capacityPercent
          : capacityPercent // ignore: cast_nullable_to_non_nullable
              as double,
      voltage: null == voltage
          ? _self.voltage
          : voltage // ignore: cast_nullable_to_non_nullable
              as double,
      current: null == current
          ? _self.current
          : current // ignore: cast_nullable_to_non_nullable
              as double,
      health: null == health
          ? _self.health
          : health // ignore: cast_nullable_to_non_nullable
              as double,
      isCharging: null == isCharging
          ? _self.isCharging
          : isCharging // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$PowerSupply {
  PowerSource get source;
  double get consumptionWatts;
  BatteryInfo? get battery;

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PowerSupplyCopyWith<PowerSupply> get copyWith =>
      _$PowerSupplyCopyWithImpl<PowerSupply>(this as PowerSupply, _$identity);

  /// Serializes this PowerSupply to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PowerSupply &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.consumptionWatts, consumptionWatts) ||
                other.consumptionWatts == consumptionWatts) &&
            (identical(other.battery, battery) || other.battery == battery));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, source, consumptionWatts, battery);

  @override
  String toString() {
    return 'PowerSupply(source: $source, consumptionWatts: $consumptionWatts, battery: $battery)';
  }
}

/// @nodoc
abstract mixin class $PowerSupplyCopyWith<$Res> {
  factory $PowerSupplyCopyWith(
          PowerSupply value, $Res Function(PowerSupply) _then) =
      _$PowerSupplyCopyWithImpl;
  @useResult
  $Res call(
      {PowerSource source, double consumptionWatts, BatteryInfo? battery});

  $BatteryInfoCopyWith<$Res>? get battery;
}

/// @nodoc
class _$PowerSupplyCopyWithImpl<$Res> implements $PowerSupplyCopyWith<$Res> {
  _$PowerSupplyCopyWithImpl(this._self, this._then);

  final PowerSupply _self;
  final $Res Function(PowerSupply) _then;

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? consumptionWatts = null,
    Object? battery = freezed,
  }) {
    return _then(_self.copyWith(
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as PowerSource,
      consumptionWatts: null == consumptionWatts
          ? _self.consumptionWatts
          : consumptionWatts // ignore: cast_nullable_to_non_nullable
              as double,
      battery: freezed == battery
          ? _self.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as BatteryInfo?,
    ));
  }

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BatteryInfoCopyWith<$Res>? get battery {
    if (_self.battery == null) {
      return null;
    }

    return $BatteryInfoCopyWith<$Res>(_self.battery!, (value) {
      return _then(_self.copyWith(battery: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PowerSupply].
extension PowerSupplyPatterns on PowerSupply {
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
    TResult Function(_PowerSupply value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PowerSupply() when $default != null:
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
    TResult Function(_PowerSupply value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PowerSupply():
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
    TResult? Function(_PowerSupply value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PowerSupply() when $default != null:
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
            PowerSource source, double consumptionWatts, BatteryInfo? battery)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PowerSupply() when $default != null:
        return $default(_that.source, _that.consumptionWatts, _that.battery);
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
            PowerSource source, double consumptionWatts, BatteryInfo? battery)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PowerSupply():
        return $default(_that.source, _that.consumptionWatts, _that.battery);
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
            PowerSource source, double consumptionWatts, BatteryInfo? battery)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PowerSupply() when $default != null:
        return $default(_that.source, _that.consumptionWatts, _that.battery);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PowerSupply implements PowerSupply {
  const _PowerSupply(
      {required this.source, required this.consumptionWatts, this.battery});
  factory _PowerSupply.fromJson(Map<String, dynamic> json) =>
      _$PowerSupplyFromJson(json);

  @override
  final PowerSource source;
  @override
  final double consumptionWatts;
  @override
  final BatteryInfo? battery;

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PowerSupplyCopyWith<_PowerSupply> get copyWith =>
      __$PowerSupplyCopyWithImpl<_PowerSupply>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PowerSupplyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PowerSupply &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.consumptionWatts, consumptionWatts) ||
                other.consumptionWatts == consumptionWatts) &&
            (identical(other.battery, battery) || other.battery == battery));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, source, consumptionWatts, battery);

  @override
  String toString() {
    return 'PowerSupply(source: $source, consumptionWatts: $consumptionWatts, battery: $battery)';
  }
}

/// @nodoc
abstract mixin class _$PowerSupplyCopyWith<$Res>
    implements $PowerSupplyCopyWith<$Res> {
  factory _$PowerSupplyCopyWith(
          _PowerSupply value, $Res Function(_PowerSupply) _then) =
      __$PowerSupplyCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PowerSource source, double consumptionWatts, BatteryInfo? battery});

  @override
  $BatteryInfoCopyWith<$Res>? get battery;
}

/// @nodoc
class __$PowerSupplyCopyWithImpl<$Res> implements _$PowerSupplyCopyWith<$Res> {
  __$PowerSupplyCopyWithImpl(this._self, this._then);

  final _PowerSupply _self;
  final $Res Function(_PowerSupply) _then;

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? source = null,
    Object? consumptionWatts = null,
    Object? battery = freezed,
  }) {
    return _then(_PowerSupply(
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as PowerSource,
      consumptionWatts: null == consumptionWatts
          ? _self.consumptionWatts
          : consumptionWatts // ignore: cast_nullable_to_non_nullable
              as double,
      battery: freezed == battery
          ? _self.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as BatteryInfo?,
    ));
  }

  /// Create a copy of PowerSupply
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BatteryInfoCopyWith<$Res>? get battery {
    if (_self.battery == null) {
      return null;
    }

    return $BatteryInfoCopyWith<$Res>(_self.battery!, (value) {
      return _then(_self.copyWith(battery: value));
    });
  }
}

// dart format on
