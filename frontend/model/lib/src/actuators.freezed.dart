// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'actuators.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PwmChannel {
  String get id;
  double get dutyCycle;
  double get frequency;

  /// Create a copy of PwmChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PwmChannelCopyWith<PwmChannel> get copyWith =>
      _$PwmChannelCopyWithImpl<PwmChannel>(this as PwmChannel, _$identity);

  /// Serializes this PwmChannel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PwmChannel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dutyCycle, dutyCycle) ||
                other.dutyCycle == dutyCycle) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, dutyCycle, frequency);

  @override
  String toString() {
    return 'PwmChannel(id: $id, dutyCycle: $dutyCycle, frequency: $frequency)';
  }
}

/// @nodoc
abstract mixin class $PwmChannelCopyWith<$Res> {
  factory $PwmChannelCopyWith(
          PwmChannel value, $Res Function(PwmChannel) _then) =
      _$PwmChannelCopyWithImpl;
  @useResult
  $Res call({String id, double dutyCycle, double frequency});
}

/// @nodoc
class _$PwmChannelCopyWithImpl<$Res> implements $PwmChannelCopyWith<$Res> {
  _$PwmChannelCopyWithImpl(this._self, this._then);

  final PwmChannel _self;
  final $Res Function(PwmChannel) _then;

  /// Create a copy of PwmChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dutyCycle = null,
    Object? frequency = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      dutyCycle: null == dutyCycle
          ? _self.dutyCycle
          : dutyCycle // ignore: cast_nullable_to_non_nullable
              as double,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [PwmChannel].
extension PwmChannelPatterns on PwmChannel {
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
    TResult Function(_PwmChannel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PwmChannel() when $default != null:
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
    TResult Function(_PwmChannel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PwmChannel():
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
    TResult? Function(_PwmChannel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PwmChannel() when $default != null:
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
    TResult Function(String id, double dutyCycle, double frequency)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PwmChannel() when $default != null:
        return $default(_that.id, _that.dutyCycle, _that.frequency);
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
    TResult Function(String id, double dutyCycle, double frequency) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PwmChannel():
        return $default(_that.id, _that.dutyCycle, _that.frequency);
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
    TResult? Function(String id, double dutyCycle, double frequency)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PwmChannel() when $default != null:
        return $default(_that.id, _that.dutyCycle, _that.frequency);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PwmChannel implements PwmChannel {
  const _PwmChannel(
      {required this.id, required this.dutyCycle, required this.frequency});
  factory _PwmChannel.fromJson(Map<String, dynamic> json) =>
      _$PwmChannelFromJson(json);

  @override
  final String id;
  @override
  final double dutyCycle;
  @override
  final double frequency;

  /// Create a copy of PwmChannel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PwmChannelCopyWith<_PwmChannel> get copyWith =>
      __$PwmChannelCopyWithImpl<_PwmChannel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PwmChannelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PwmChannel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dutyCycle, dutyCycle) ||
                other.dutyCycle == dutyCycle) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, dutyCycle, frequency);

  @override
  String toString() {
    return 'PwmChannel(id: $id, dutyCycle: $dutyCycle, frequency: $frequency)';
  }
}

/// @nodoc
abstract mixin class _$PwmChannelCopyWith<$Res>
    implements $PwmChannelCopyWith<$Res> {
  factory _$PwmChannelCopyWith(
          _PwmChannel value, $Res Function(_PwmChannel) _then) =
      __$PwmChannelCopyWithImpl;
  @override
  @useResult
  $Res call({String id, double dutyCycle, double frequency});
}

/// @nodoc
class __$PwmChannelCopyWithImpl<$Res> implements _$PwmChannelCopyWith<$Res> {
  __$PwmChannelCopyWithImpl(this._self, this._then);

  final _PwmChannel _self;
  final $Res Function(_PwmChannel) _then;

  /// Create a copy of PwmChannel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? dutyCycle = null,
    Object? frequency = null,
  }) {
    return _then(_PwmChannel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      dutyCycle: null == dutyCycle
          ? _self.dutyCycle
          : dutyCycle // ignore: cast_nullable_to_non_nullable
              as double,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$GpioPin {
  int get pinNumber;
  GpioMode get mode;
  GpioValue? get value;

  /// Create a copy of GpioPin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpioPinCopyWith<GpioPin> get copyWith =>
      _$GpioPinCopyWithImpl<GpioPin>(this as GpioPin, _$identity);

  /// Serializes this GpioPin to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpioPin &&
            (identical(other.pinNumber, pinNumber) ||
                other.pinNumber == pinNumber) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pinNumber, mode, value);

  @override
  String toString() {
    return 'GpioPin(pinNumber: $pinNumber, mode: $mode, value: $value)';
  }
}

/// @nodoc
abstract mixin class $GpioPinCopyWith<$Res> {
  factory $GpioPinCopyWith(GpioPin value, $Res Function(GpioPin) _then) =
      _$GpioPinCopyWithImpl;
  @useResult
  $Res call({int pinNumber, GpioMode mode, GpioValue? value});
}

/// @nodoc
class _$GpioPinCopyWithImpl<$Res> implements $GpioPinCopyWith<$Res> {
  _$GpioPinCopyWithImpl(this._self, this._then);

  final GpioPin _self;
  final $Res Function(GpioPin) _then;

  /// Create a copy of GpioPin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pinNumber = null,
    Object? mode = null,
    Object? value = freezed,
  }) {
    return _then(_self.copyWith(
      pinNumber: null == pinNumber
          ? _self.pinNumber
          : pinNumber // ignore: cast_nullable_to_non_nullable
              as int,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as GpioMode,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as GpioValue?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GpioPin].
extension GpioPinPatterns on GpioPin {
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
    TResult Function(_GpioPin value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpioPin() when $default != null:
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
    TResult Function(_GpioPin value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpioPin():
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
    TResult? Function(_GpioPin value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpioPin() when $default != null:
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
    TResult Function(int pinNumber, GpioMode mode, GpioValue? value)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpioPin() when $default != null:
        return $default(_that.pinNumber, _that.mode, _that.value);
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
    TResult Function(int pinNumber, GpioMode mode, GpioValue? value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpioPin():
        return $default(_that.pinNumber, _that.mode, _that.value);
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
    TResult? Function(int pinNumber, GpioMode mode, GpioValue? value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpioPin() when $default != null:
        return $default(_that.pinNumber, _that.mode, _that.value);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GpioPin implements GpioPin {
  const _GpioPin({required this.pinNumber, required this.mode, this.value});
  factory _GpioPin.fromJson(Map<String, dynamic> json) =>
      _$GpioPinFromJson(json);

  @override
  final int pinNumber;
  @override
  final GpioMode mode;
  @override
  final GpioValue? value;

  /// Create a copy of GpioPin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GpioPinCopyWith<_GpioPin> get copyWith =>
      __$GpioPinCopyWithImpl<_GpioPin>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpioPinToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GpioPin &&
            (identical(other.pinNumber, pinNumber) ||
                other.pinNumber == pinNumber) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pinNumber, mode, value);

  @override
  String toString() {
    return 'GpioPin(pinNumber: $pinNumber, mode: $mode, value: $value)';
  }
}

/// @nodoc
abstract mixin class _$GpioPinCopyWith<$Res> implements $GpioPinCopyWith<$Res> {
  factory _$GpioPinCopyWith(_GpioPin value, $Res Function(_GpioPin) _then) =
      __$GpioPinCopyWithImpl;
  @override
  @useResult
  $Res call({int pinNumber, GpioMode mode, GpioValue? value});
}

/// @nodoc
class __$GpioPinCopyWithImpl<$Res> implements _$GpioPinCopyWith<$Res> {
  __$GpioPinCopyWithImpl(this._self, this._then);

  final _GpioPin _self;
  final $Res Function(_GpioPin) _then;

  /// Create a copy of GpioPin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pinNumber = null,
    Object? mode = null,
    Object? value = freezed,
  }) {
    return _then(_GpioPin(
      pinNumber: null == pinNumber
          ? _self.pinNumber
          : pinNumber // ignore: cast_nullable_to_non_nullable
              as int,
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as GpioMode,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as GpioValue?,
    ));
  }
}

/// @nodoc
mixin _$MotorControl {
  String get id;
  double get rpm;
  double get loadPercentage;
  double get temperature;

  /// Create a copy of MotorControl
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MotorControlCopyWith<MotorControl> get copyWith =>
      _$MotorControlCopyWithImpl<MotorControl>(
          this as MotorControl, _$identity);

  /// Serializes this MotorControl to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MotorControl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rpm, rpm) || other.rpm == rpm) &&
            (identical(other.loadPercentage, loadPercentage) ||
                other.loadPercentage == loadPercentage) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, rpm, loadPercentage, temperature);

  @override
  String toString() {
    return 'MotorControl(id: $id, rpm: $rpm, loadPercentage: $loadPercentage, temperature: $temperature)';
  }
}

/// @nodoc
abstract mixin class $MotorControlCopyWith<$Res> {
  factory $MotorControlCopyWith(
          MotorControl value, $Res Function(MotorControl) _then) =
      _$MotorControlCopyWithImpl;
  @useResult
  $Res call({String id, double rpm, double loadPercentage, double temperature});
}

/// @nodoc
class _$MotorControlCopyWithImpl<$Res> implements $MotorControlCopyWith<$Res> {
  _$MotorControlCopyWithImpl(this._self, this._then);

  final MotorControl _self;
  final $Res Function(MotorControl) _then;

  /// Create a copy of MotorControl
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? rpm = null,
    Object? loadPercentage = null,
    Object? temperature = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rpm: null == rpm
          ? _self.rpm
          : rpm // ignore: cast_nullable_to_non_nullable
              as double,
      loadPercentage: null == loadPercentage
          ? _self.loadPercentage
          : loadPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      temperature: null == temperature
          ? _self.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [MotorControl].
extension MotorControlPatterns on MotorControl {
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
    TResult Function(_MotorControl value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MotorControl() when $default != null:
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
    TResult Function(_MotorControl value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MotorControl():
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
    TResult? Function(_MotorControl value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MotorControl() when $default != null:
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
            String id, double rpm, double loadPercentage, double temperature)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MotorControl() when $default != null:
        return $default(
            _that.id, _that.rpm, _that.loadPercentage, _that.temperature);
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
            String id, double rpm, double loadPercentage, double temperature)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MotorControl():
        return $default(
            _that.id, _that.rpm, _that.loadPercentage, _that.temperature);
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
            String id, double rpm, double loadPercentage, double temperature)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MotorControl() when $default != null:
        return $default(
            _that.id, _that.rpm, _that.loadPercentage, _that.temperature);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MotorControl implements MotorControl {
  const _MotorControl(
      {required this.id,
      required this.rpm,
      required this.loadPercentage,
      required this.temperature});
  factory _MotorControl.fromJson(Map<String, dynamic> json) =>
      _$MotorControlFromJson(json);

  @override
  final String id;
  @override
  final double rpm;
  @override
  final double loadPercentage;
  @override
  final double temperature;

  /// Create a copy of MotorControl
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MotorControlCopyWith<_MotorControl> get copyWith =>
      __$MotorControlCopyWithImpl<_MotorControl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MotorControlToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MotorControl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.rpm, rpm) || other.rpm == rpm) &&
            (identical(other.loadPercentage, loadPercentage) ||
                other.loadPercentage == loadPercentage) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, rpm, loadPercentage, temperature);

  @override
  String toString() {
    return 'MotorControl(id: $id, rpm: $rpm, loadPercentage: $loadPercentage, temperature: $temperature)';
  }
}

/// @nodoc
abstract mixin class _$MotorControlCopyWith<$Res>
    implements $MotorControlCopyWith<$Res> {
  factory _$MotorControlCopyWith(
          _MotorControl value, $Res Function(_MotorControl) _then) =
      __$MotorControlCopyWithImpl;
  @override
  @useResult
  $Res call({String id, double rpm, double loadPercentage, double temperature});
}

/// @nodoc
class __$MotorControlCopyWithImpl<$Res>
    implements _$MotorControlCopyWith<$Res> {
  __$MotorControlCopyWithImpl(this._self, this._then);

  final _MotorControl _self;
  final $Res Function(_MotorControl) _then;

  /// Create a copy of MotorControl
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? rpm = null,
    Object? loadPercentage = null,
    Object? temperature = null,
  }) {
    return _then(_MotorControl(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      rpm: null == rpm
          ? _self.rpm
          : rpm // ignore: cast_nullable_to_non_nullable
              as double,
      loadPercentage: null == loadPercentage
          ? _self.loadPercentage
          : loadPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      temperature: null == temperature
          ? _self.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
