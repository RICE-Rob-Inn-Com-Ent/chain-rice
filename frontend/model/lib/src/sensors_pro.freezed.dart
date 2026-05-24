// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sensors_pro.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vec3 {
  double get x;
  double get y;
  double get z;

  /// Create a copy of Vec3
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<Vec3> get copyWith =>
      _$Vec3CopyWithImpl<Vec3>(this as Vec3, _$identity);

  /// Serializes this Vec3 to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Vec3 &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.z, z) || other.z == z));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, z);

  @override
  String toString() {
    return 'Vec3(x: $x, y: $y, z: $z)';
  }
}

/// @nodoc
abstract mixin class $Vec3CopyWith<$Res> {
  factory $Vec3CopyWith(Vec3 value, $Res Function(Vec3) _then) =
      _$Vec3CopyWithImpl;
  @useResult
  $Res call({double x, double y, double z});
}

/// @nodoc
class _$Vec3CopyWithImpl<$Res> implements $Vec3CopyWith<$Res> {
  _$Vec3CopyWithImpl(this._self, this._then);

  final Vec3 _self;
  final $Res Function(Vec3) _then;

  /// Create a copy of Vec3
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? z = null,
  }) {
    return _then(_self.copyWith(
      x: null == x
          ? _self.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _self.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      z: null == z
          ? _self.z
          : z // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [Vec3].
extension Vec3Patterns on Vec3 {
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
    TResult Function(_Vec3 value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Vec3() when $default != null:
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
    TResult Function(_Vec3 value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vec3():
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
    TResult? Function(_Vec3 value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vec3() when $default != null:
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
    TResult Function(double x, double y, double z)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Vec3() when $default != null:
        return $default(_that.x, _that.y, _that.z);
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
    TResult Function(double x, double y, double z) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vec3():
        return $default(_that.x, _that.y, _that.z);
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
    TResult? Function(double x, double y, double z)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Vec3() when $default != null:
        return $default(_that.x, _that.y, _that.z);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Vec3 implements Vec3 {
  const _Vec3({required this.x, required this.y, required this.z});
  factory _Vec3.fromJson(Map<String, dynamic> json) => _$Vec3FromJson(json);

  @override
  final double x;
  @override
  final double y;
  @override
  final double z;

  /// Create a copy of Vec3
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$Vec3CopyWith<_Vec3> get copyWith =>
      __$Vec3CopyWithImpl<_Vec3>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$Vec3ToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Vec3 &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.z, z) || other.z == z));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, z);

  @override
  String toString() {
    return 'Vec3(x: $x, y: $y, z: $z)';
  }
}

/// @nodoc
abstract mixin class _$Vec3CopyWith<$Res> implements $Vec3CopyWith<$Res> {
  factory _$Vec3CopyWith(_Vec3 value, $Res Function(_Vec3) _then) =
      __$Vec3CopyWithImpl;
  @override
  @useResult
  $Res call({double x, double y, double z});
}

/// @nodoc
class __$Vec3CopyWithImpl<$Res> implements _$Vec3CopyWith<$Res> {
  __$Vec3CopyWithImpl(this._self, this._then);

  final _Vec3 _self;
  final $Res Function(_Vec3) _then;

  /// Create a copy of Vec3
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? z = null,
  }) {
    return _then(_Vec3(
      x: null == x
          ? _self.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _self.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      z: null == z
          ? _self.z
          : z // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$ImuData {
  Vec3 get accelerometer;
  Vec3 get gyroscope;
  Vec3 get magnetometer;

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImuDataCopyWith<ImuData> get copyWith =>
      _$ImuDataCopyWithImpl<ImuData>(this as ImuData, _$identity);

  /// Serializes this ImuData to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImuData &&
            (identical(other.accelerometer, accelerometer) ||
                other.accelerometer == accelerometer) &&
            (identical(other.gyroscope, gyroscope) ||
                other.gyroscope == gyroscope) &&
            (identical(other.magnetometer, magnetometer) ||
                other.magnetometer == magnetometer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accelerometer, gyroscope, magnetometer);

  @override
  String toString() {
    return 'ImuData(accelerometer: $accelerometer, gyroscope: $gyroscope, magnetometer: $magnetometer)';
  }
}

/// @nodoc
abstract mixin class $ImuDataCopyWith<$Res> {
  factory $ImuDataCopyWith(ImuData value, $Res Function(ImuData) _then) =
      _$ImuDataCopyWithImpl;
  @useResult
  $Res call({Vec3 accelerometer, Vec3 gyroscope, Vec3 magnetometer});

  $Vec3CopyWith<$Res> get accelerometer;
  $Vec3CopyWith<$Res> get gyroscope;
  $Vec3CopyWith<$Res> get magnetometer;
}

/// @nodoc
class _$ImuDataCopyWithImpl<$Res> implements $ImuDataCopyWith<$Res> {
  _$ImuDataCopyWithImpl(this._self, this._then);

  final ImuData _self;
  final $Res Function(ImuData) _then;

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accelerometer = null,
    Object? gyroscope = null,
    Object? magnetometer = null,
  }) {
    return _then(_self.copyWith(
      accelerometer: null == accelerometer
          ? _self.accelerometer
          : accelerometer // ignore: cast_nullable_to_non_nullable
              as Vec3,
      gyroscope: null == gyroscope
          ? _self.gyroscope
          : gyroscope // ignore: cast_nullable_to_non_nullable
              as Vec3,
      magnetometer: null == magnetometer
          ? _self.magnetometer
          : magnetometer // ignore: cast_nullable_to_non_nullable
              as Vec3,
    ));
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get accelerometer {
    return $Vec3CopyWith<$Res>(_self.accelerometer, (value) {
      return _then(_self.copyWith(accelerometer: value));
    });
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get gyroscope {
    return $Vec3CopyWith<$Res>(_self.gyroscope, (value) {
      return _then(_self.copyWith(gyroscope: value));
    });
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get magnetometer {
    return $Vec3CopyWith<$Res>(_self.magnetometer, (value) {
      return _then(_self.copyWith(magnetometer: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ImuData].
extension ImuDataPatterns on ImuData {
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
    TResult Function(_ImuData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImuData() when $default != null:
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
    TResult Function(_ImuData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImuData():
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
    TResult? Function(_ImuData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImuData() when $default != null:
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
    TResult Function(Vec3 accelerometer, Vec3 gyroscope, Vec3 magnetometer)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImuData() when $default != null:
        return $default(
            _that.accelerometer, _that.gyroscope, _that.magnetometer);
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
    TResult Function(Vec3 accelerometer, Vec3 gyroscope, Vec3 magnetometer)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImuData():
        return $default(
            _that.accelerometer, _that.gyroscope, _that.magnetometer);
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
    TResult? Function(Vec3 accelerometer, Vec3 gyroscope, Vec3 magnetometer)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImuData() when $default != null:
        return $default(
            _that.accelerometer, _that.gyroscope, _that.magnetometer);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ImuData implements ImuData {
  const _ImuData(
      {required this.accelerometer,
      required this.gyroscope,
      required this.magnetometer});
  factory _ImuData.fromJson(Map<String, dynamic> json) =>
      _$ImuDataFromJson(json);

  @override
  final Vec3 accelerometer;
  @override
  final Vec3 gyroscope;
  @override
  final Vec3 magnetometer;

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ImuDataCopyWith<_ImuData> get copyWith =>
      __$ImuDataCopyWithImpl<_ImuData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ImuDataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ImuData &&
            (identical(other.accelerometer, accelerometer) ||
                other.accelerometer == accelerometer) &&
            (identical(other.gyroscope, gyroscope) ||
                other.gyroscope == gyroscope) &&
            (identical(other.magnetometer, magnetometer) ||
                other.magnetometer == magnetometer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accelerometer, gyroscope, magnetometer);

  @override
  String toString() {
    return 'ImuData(accelerometer: $accelerometer, gyroscope: $gyroscope, magnetometer: $magnetometer)';
  }
}

/// @nodoc
abstract mixin class _$ImuDataCopyWith<$Res> implements $ImuDataCopyWith<$Res> {
  factory _$ImuDataCopyWith(_ImuData value, $Res Function(_ImuData) _then) =
      __$ImuDataCopyWithImpl;
  @override
  @useResult
  $Res call({Vec3 accelerometer, Vec3 gyroscope, Vec3 magnetometer});

  @override
  $Vec3CopyWith<$Res> get accelerometer;
  @override
  $Vec3CopyWith<$Res> get gyroscope;
  @override
  $Vec3CopyWith<$Res> get magnetometer;
}

/// @nodoc
class __$ImuDataCopyWithImpl<$Res> implements _$ImuDataCopyWith<$Res> {
  __$ImuDataCopyWithImpl(this._self, this._then);

  final _ImuData _self;
  final $Res Function(_ImuData) _then;

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? accelerometer = null,
    Object? gyroscope = null,
    Object? magnetometer = null,
  }) {
    return _then(_ImuData(
      accelerometer: null == accelerometer
          ? _self.accelerometer
          : accelerometer // ignore: cast_nullable_to_non_nullable
              as Vec3,
      gyroscope: null == gyroscope
          ? _self.gyroscope
          : gyroscope // ignore: cast_nullable_to_non_nullable
              as Vec3,
      magnetometer: null == magnetometer
          ? _self.magnetometer
          : magnetometer // ignore: cast_nullable_to_non_nullable
              as Vec3,
    ));
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get accelerometer {
    return $Vec3CopyWith<$Res>(_self.accelerometer, (value) {
      return _then(_self.copyWith(accelerometer: value));
    });
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get gyroscope {
    return $Vec3CopyWith<$Res>(_self.gyroscope, (value) {
      return _then(_self.copyWith(gyroscope: value));
    });
  }

  /// Create a copy of ImuData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Vec3CopyWith<$Res> get magnetometer {
    return $Vec3CopyWith<$Res>(_self.magnetometer, (value) {
      return _then(_self.copyWith(magnetometer: value));
    });
  }
}

/// @nodoc
mixin _$VisionSpec {
  String get cameraPath;
  List<String> get formats;
  double get maxFps;
  int get currentResolutionWidth;
  int get currentResolutionHeight;

  /// Create a copy of VisionSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VisionSpecCopyWith<VisionSpec> get copyWith =>
      _$VisionSpecCopyWithImpl<VisionSpec>(this as VisionSpec, _$identity);

  /// Serializes this VisionSpec to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VisionSpec &&
            (identical(other.cameraPath, cameraPath) ||
                other.cameraPath == cameraPath) &&
            const DeepCollectionEquality().equals(other.formats, formats) &&
            (identical(other.maxFps, maxFps) || other.maxFps == maxFps) &&
            (identical(other.currentResolutionWidth, currentResolutionWidth) ||
                other.currentResolutionWidth == currentResolutionWidth) &&
            (identical(
                    other.currentResolutionHeight, currentResolutionHeight) ||
                other.currentResolutionHeight == currentResolutionHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      cameraPath,
      const DeepCollectionEquality().hash(formats),
      maxFps,
      currentResolutionWidth,
      currentResolutionHeight);

  @override
  String toString() {
    return 'VisionSpec(cameraPath: $cameraPath, formats: $formats, maxFps: $maxFps, currentResolutionWidth: $currentResolutionWidth, currentResolutionHeight: $currentResolutionHeight)';
  }
}

/// @nodoc
abstract mixin class $VisionSpecCopyWith<$Res> {
  factory $VisionSpecCopyWith(
          VisionSpec value, $Res Function(VisionSpec) _then) =
      _$VisionSpecCopyWithImpl;
  @useResult
  $Res call(
      {String cameraPath,
      List<String> formats,
      double maxFps,
      int currentResolutionWidth,
      int currentResolutionHeight});
}

/// @nodoc
class _$VisionSpecCopyWithImpl<$Res> implements $VisionSpecCopyWith<$Res> {
  _$VisionSpecCopyWithImpl(this._self, this._then);

  final VisionSpec _self;
  final $Res Function(VisionSpec) _then;

  /// Create a copy of VisionSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cameraPath = null,
    Object? formats = null,
    Object? maxFps = null,
    Object? currentResolutionWidth = null,
    Object? currentResolutionHeight = null,
  }) {
    return _then(_self.copyWith(
      cameraPath: null == cameraPath
          ? _self.cameraPath
          : cameraPath // ignore: cast_nullable_to_non_nullable
              as String,
      formats: null == formats
          ? _self.formats
          : formats // ignore: cast_nullable_to_non_nullable
              as List<String>,
      maxFps: null == maxFps
          ? _self.maxFps
          : maxFps // ignore: cast_nullable_to_non_nullable
              as double,
      currentResolutionWidth: null == currentResolutionWidth
          ? _self.currentResolutionWidth
          : currentResolutionWidth // ignore: cast_nullable_to_non_nullable
              as int,
      currentResolutionHeight: null == currentResolutionHeight
          ? _self.currentResolutionHeight
          : currentResolutionHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [VisionSpec].
extension VisionSpecPatterns on VisionSpec {
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
    TResult Function(_VisionSpec value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisionSpec() when $default != null:
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
    TResult Function(_VisionSpec value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisionSpec():
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
    TResult? Function(_VisionSpec value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisionSpec() when $default != null:
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
    TResult Function(String cameraPath, List<String> formats, double maxFps,
            int currentResolutionWidth, int currentResolutionHeight)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisionSpec() when $default != null:
        return $default(_that.cameraPath, _that.formats, _that.maxFps,
            _that.currentResolutionWidth, _that.currentResolutionHeight);
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
    TResult Function(String cameraPath, List<String> formats, double maxFps,
            int currentResolutionWidth, int currentResolutionHeight)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisionSpec():
        return $default(_that.cameraPath, _that.formats, _that.maxFps,
            _that.currentResolutionWidth, _that.currentResolutionHeight);
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
    TResult? Function(String cameraPath, List<String> formats, double maxFps,
            int currentResolutionWidth, int currentResolutionHeight)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisionSpec() when $default != null:
        return $default(_that.cameraPath, _that.formats, _that.maxFps,
            _that.currentResolutionWidth, _that.currentResolutionHeight);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _VisionSpec implements VisionSpec {
  const _VisionSpec(
      {required this.cameraPath,
      final List<String> formats = const <String>[],
      required this.maxFps,
      required this.currentResolutionWidth,
      required this.currentResolutionHeight})
      : _formats = formats;
  factory _VisionSpec.fromJson(Map<String, dynamic> json) =>
      _$VisionSpecFromJson(json);

  @override
  final String cameraPath;
  final List<String> _formats;
  @override
  @JsonKey()
  List<String> get formats {
    if (_formats is EqualUnmodifiableListView) return _formats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_formats);
  }

  @override
  final double maxFps;
  @override
  final int currentResolutionWidth;
  @override
  final int currentResolutionHeight;

  /// Create a copy of VisionSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VisionSpecCopyWith<_VisionSpec> get copyWith =>
      __$VisionSpecCopyWithImpl<_VisionSpec>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VisionSpecToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VisionSpec &&
            (identical(other.cameraPath, cameraPath) ||
                other.cameraPath == cameraPath) &&
            const DeepCollectionEquality().equals(other._formats, _formats) &&
            (identical(other.maxFps, maxFps) || other.maxFps == maxFps) &&
            (identical(other.currentResolutionWidth, currentResolutionWidth) ||
                other.currentResolutionWidth == currentResolutionWidth) &&
            (identical(
                    other.currentResolutionHeight, currentResolutionHeight) ||
                other.currentResolutionHeight == currentResolutionHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      cameraPath,
      const DeepCollectionEquality().hash(_formats),
      maxFps,
      currentResolutionWidth,
      currentResolutionHeight);

  @override
  String toString() {
    return 'VisionSpec(cameraPath: $cameraPath, formats: $formats, maxFps: $maxFps, currentResolutionWidth: $currentResolutionWidth, currentResolutionHeight: $currentResolutionHeight)';
  }
}

/// @nodoc
abstract mixin class _$VisionSpecCopyWith<$Res>
    implements $VisionSpecCopyWith<$Res> {
  factory _$VisionSpecCopyWith(
          _VisionSpec value, $Res Function(_VisionSpec) _then) =
      __$VisionSpecCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String cameraPath,
      List<String> formats,
      double maxFps,
      int currentResolutionWidth,
      int currentResolutionHeight});
}

/// @nodoc
class __$VisionSpecCopyWithImpl<$Res> implements _$VisionSpecCopyWith<$Res> {
  __$VisionSpecCopyWithImpl(this._self, this._then);

  final _VisionSpec _self;
  final $Res Function(_VisionSpec) _then;

  /// Create a copy of VisionSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cameraPath = null,
    Object? formats = null,
    Object? maxFps = null,
    Object? currentResolutionWidth = null,
    Object? currentResolutionHeight = null,
  }) {
    return _then(_VisionSpec(
      cameraPath: null == cameraPath
          ? _self.cameraPath
          : cameraPath // ignore: cast_nullable_to_non_nullable
              as String,
      formats: null == formats
          ? _self._formats
          : formats // ignore: cast_nullable_to_non_nullable
              as List<String>,
      maxFps: null == maxFps
          ? _self.maxFps
          : maxFps // ignore: cast_nullable_to_non_nullable
              as double,
      currentResolutionWidth: null == currentResolutionWidth
          ? _self.currentResolutionWidth
          : currentResolutionWidth // ignore: cast_nullable_to_non_nullable
              as int,
      currentResolutionHeight: null == currentResolutionHeight
          ? _self.currentResolutionHeight
          : currentResolutionHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$SdrSpectrum {
  double get frequencyMin;
  double get frequencyMax;
  double get sampleRate;

  /// Create a copy of SdrSpectrum
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SdrSpectrumCopyWith<SdrSpectrum> get copyWith =>
      _$SdrSpectrumCopyWithImpl<SdrSpectrum>(this as SdrSpectrum, _$identity);

  /// Serializes this SdrSpectrum to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SdrSpectrum &&
            (identical(other.frequencyMin, frequencyMin) ||
                other.frequencyMin == frequencyMin) &&
            (identical(other.frequencyMax, frequencyMax) ||
                other.frequencyMax == frequencyMax) &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, frequencyMin, frequencyMax, sampleRate);

  @override
  String toString() {
    return 'SdrSpectrum(frequencyMin: $frequencyMin, frequencyMax: $frequencyMax, sampleRate: $sampleRate)';
  }
}

/// @nodoc
abstract mixin class $SdrSpectrumCopyWith<$Res> {
  factory $SdrSpectrumCopyWith(
          SdrSpectrum value, $Res Function(SdrSpectrum) _then) =
      _$SdrSpectrumCopyWithImpl;
  @useResult
  $Res call({double frequencyMin, double frequencyMax, double sampleRate});
}

/// @nodoc
class _$SdrSpectrumCopyWithImpl<$Res> implements $SdrSpectrumCopyWith<$Res> {
  _$SdrSpectrumCopyWithImpl(this._self, this._then);

  final SdrSpectrum _self;
  final $Res Function(SdrSpectrum) _then;

  /// Create a copy of SdrSpectrum
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequencyMin = null,
    Object? frequencyMax = null,
    Object? sampleRate = null,
  }) {
    return _then(_self.copyWith(
      frequencyMin: null == frequencyMin
          ? _self.frequencyMin
          : frequencyMin // ignore: cast_nullable_to_non_nullable
              as double,
      frequencyMax: null == frequencyMax
          ? _self.frequencyMax
          : frequencyMax // ignore: cast_nullable_to_non_nullable
              as double,
      sampleRate: null == sampleRate
          ? _self.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [SdrSpectrum].
extension SdrSpectrumPatterns on SdrSpectrum {
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
    TResult Function(_SdrSpectrum value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum() when $default != null:
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
    TResult Function(_SdrSpectrum value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum():
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
    TResult? Function(_SdrSpectrum value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum() when $default != null:
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
            double frequencyMin, double frequencyMax, double sampleRate)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum() when $default != null:
        return $default(
            _that.frequencyMin, _that.frequencyMax, _that.sampleRate);
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
            double frequencyMin, double frequencyMax, double sampleRate)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum():
        return $default(
            _that.frequencyMin, _that.frequencyMax, _that.sampleRate);
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
            double frequencyMin, double frequencyMax, double sampleRate)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SdrSpectrum() when $default != null:
        return $default(
            _that.frequencyMin, _that.frequencyMax, _that.sampleRate);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SdrSpectrum implements SdrSpectrum {
  const _SdrSpectrum(
      {required this.frequencyMin,
      required this.frequencyMax,
      required this.sampleRate});
  factory _SdrSpectrum.fromJson(Map<String, dynamic> json) =>
      _$SdrSpectrumFromJson(json);

  @override
  final double frequencyMin;
  @override
  final double frequencyMax;
  @override
  final double sampleRate;

  /// Create a copy of SdrSpectrum
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SdrSpectrumCopyWith<_SdrSpectrum> get copyWith =>
      __$SdrSpectrumCopyWithImpl<_SdrSpectrum>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SdrSpectrumToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SdrSpectrum &&
            (identical(other.frequencyMin, frequencyMin) ||
                other.frequencyMin == frequencyMin) &&
            (identical(other.frequencyMax, frequencyMax) ||
                other.frequencyMax == frequencyMax) &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, frequencyMin, frequencyMax, sampleRate);

  @override
  String toString() {
    return 'SdrSpectrum(frequencyMin: $frequencyMin, frequencyMax: $frequencyMax, sampleRate: $sampleRate)';
  }
}

/// @nodoc
abstract mixin class _$SdrSpectrumCopyWith<$Res>
    implements $SdrSpectrumCopyWith<$Res> {
  factory _$SdrSpectrumCopyWith(
          _SdrSpectrum value, $Res Function(_SdrSpectrum) _then) =
      __$SdrSpectrumCopyWithImpl;
  @override
  @useResult
  $Res call({double frequencyMin, double frequencyMax, double sampleRate});
}

/// @nodoc
class __$SdrSpectrumCopyWithImpl<$Res> implements _$SdrSpectrumCopyWith<$Res> {
  __$SdrSpectrumCopyWithImpl(this._self, this._then);

  final _SdrSpectrum _self;
  final $Res Function(_SdrSpectrum) _then;

  /// Create a copy of SdrSpectrum
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? frequencyMin = null,
    Object? frequencyMax = null,
    Object? sampleRate = null,
  }) {
    return _then(_SdrSpectrum(
      frequencyMin: null == frequencyMin
          ? _self.frequencyMin
          : frequencyMin // ignore: cast_nullable_to_non_nullable
              as double,
      frequencyMax: null == frequencyMax
          ? _self.frequencyMax
          : frequencyMax // ignore: cast_nullable_to_non_nullable
              as double,
      sampleRate: null == sampleRate
          ? _self.sampleRate
          : sampleRate // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
