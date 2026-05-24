// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hardware_gpu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GpuMemory {
  int get totalBytes;
  int get usedBytes;
  int get freeBytes;

  /// Create a copy of GpuMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuMemoryCopyWith<GpuMemory> get copyWith =>
      _$GpuMemoryCopyWithImpl<GpuMemory>(this as GpuMemory, _$identity);

  /// Serializes this GpuMemory to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpuMemory &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.freeBytes, freeBytes) ||
                other.freeBytes == freeBytes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalBytes, usedBytes, freeBytes);

  @override
  String toString() {
    return 'GpuMemory(totalBytes: $totalBytes, usedBytes: $usedBytes, freeBytes: $freeBytes)';
  }
}

/// @nodoc
abstract mixin class $GpuMemoryCopyWith<$Res> {
  factory $GpuMemoryCopyWith(GpuMemory value, $Res Function(GpuMemory) _then) =
      _$GpuMemoryCopyWithImpl;
  @useResult
  $Res call({int totalBytes, int usedBytes, int freeBytes});
}

/// @nodoc
class _$GpuMemoryCopyWithImpl<$Res> implements $GpuMemoryCopyWith<$Res> {
  _$GpuMemoryCopyWithImpl(this._self, this._then);

  final GpuMemory _self;
  final $Res Function(GpuMemory) _then;

  /// Create a copy of GpuMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? freeBytes = null,
  }) {
    return _then(_self.copyWith(
      totalBytes: null == totalBytes
          ? _self.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _self.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      freeBytes: null == freeBytes
          ? _self.freeBytes
          : freeBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [GpuMemory].
extension GpuMemoryPatterns on GpuMemory {
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
    TResult Function(_GpuMemory value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpuMemory() when $default != null:
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
    TResult Function(_GpuMemory value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuMemory():
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
    TResult? Function(_GpuMemory value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuMemory() when $default != null:
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
    TResult Function(int totalBytes, int usedBytes, int freeBytes)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpuMemory() when $default != null:
        return $default(_that.totalBytes, _that.usedBytes, _that.freeBytes);
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
    TResult Function(int totalBytes, int usedBytes, int freeBytes) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuMemory():
        return $default(_that.totalBytes, _that.usedBytes, _that.freeBytes);
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
    TResult? Function(int totalBytes, int usedBytes, int freeBytes)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuMemory() when $default != null:
        return $default(_that.totalBytes, _that.usedBytes, _that.freeBytes);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GpuMemory implements GpuMemory {
  const _GpuMemory(
      {required this.totalBytes,
      required this.usedBytes,
      required this.freeBytes});
  factory _GpuMemory.fromJson(Map<String, dynamic> json) =>
      _$GpuMemoryFromJson(json);

  @override
  final int totalBytes;
  @override
  final int usedBytes;
  @override
  final int freeBytes;

  /// Create a copy of GpuMemory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GpuMemoryCopyWith<_GpuMemory> get copyWith =>
      __$GpuMemoryCopyWithImpl<_GpuMemory>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpuMemoryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GpuMemory &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.freeBytes, freeBytes) ||
                other.freeBytes == freeBytes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalBytes, usedBytes, freeBytes);

  @override
  String toString() {
    return 'GpuMemory(totalBytes: $totalBytes, usedBytes: $usedBytes, freeBytes: $freeBytes)';
  }
}

/// @nodoc
abstract mixin class _$GpuMemoryCopyWith<$Res>
    implements $GpuMemoryCopyWith<$Res> {
  factory _$GpuMemoryCopyWith(
          _GpuMemory value, $Res Function(_GpuMemory) _then) =
      __$GpuMemoryCopyWithImpl;
  @override
  @useResult
  $Res call({int totalBytes, int usedBytes, int freeBytes});
}

/// @nodoc
class __$GpuMemoryCopyWithImpl<$Res> implements _$GpuMemoryCopyWith<$Res> {
  __$GpuMemoryCopyWithImpl(this._self, this._then);

  final _GpuMemory _self;
  final $Res Function(_GpuMemory) _then;

  /// Create a copy of GpuMemory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? freeBytes = null,
  }) {
    return _then(_GpuMemory(
      totalBytes: null == totalBytes
          ? _self.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _self.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      freeBytes: null == freeBytes
          ? _self.freeBytes
          : freeBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

GpuInfo _$GpuInfoFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'nvidia':
      return GpuInfoNvidia.fromJson(json);
    case 'generic':
      return GpuInfoGeneric.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json, 'kind', 'GpuInfo', 'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$GpuInfo {
  String get model;
  String get vendor;
  String? get uuid;
  GpuMemory get memory;
  double? get temperatureC;
  DataUnit? get powerUsage;
  String? get pcieStatus;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuInfoCopyWith<GpuInfo> get copyWith =>
      _$GpuInfoCopyWithImpl<GpuInfo>(this as GpuInfo, _$identity);

  /// Serializes this GpuInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpuInfo &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.powerUsage, powerUsage) ||
                other.powerUsage == powerUsage) &&
            (identical(other.pcieStatus, pcieStatus) ||
                other.pcieStatus == pcieStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, model, vendor, uuid, memory,
      temperatureC, powerUsage, pcieStatus);

  @override
  String toString() {
    return 'GpuInfo(model: $model, vendor: $vendor, uuid: $uuid, memory: $memory, temperatureC: $temperatureC, powerUsage: $powerUsage, pcieStatus: $pcieStatus)';
  }
}

/// @nodoc
abstract mixin class $GpuInfoCopyWith<$Res> {
  factory $GpuInfoCopyWith(GpuInfo value, $Res Function(GpuInfo) _then) =
      _$GpuInfoCopyWithImpl;
  @useResult
  $Res call(
      {String model,
      String vendor,
      String uuid,
      GpuMemory memory,
      double temperatureC,
      DataUnit powerUsage,
      String pcieStatus});

  $GpuMemoryCopyWith<$Res> get memory;
  $DataUnitCopyWith<$Res>? get powerUsage;
}

/// @nodoc
class _$GpuInfoCopyWithImpl<$Res> implements $GpuInfoCopyWith<$Res> {
  _$GpuInfoCopyWithImpl(this._self, this._then);

  final GpuInfo _self;
  final $Res Function(GpuInfo) _then;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? model = null,
    Object? vendor = null,
    Object? uuid = null,
    Object? memory = null,
    Object? temperatureC = null,
    Object? powerUsage = null,
    Object? pcieStatus = null,
  }) {
    return _then(_self.copyWith(
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      uuid: null == uuid
          ? _self.uuid!
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      memory: null == memory
          ? _self.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as GpuMemory,
      temperatureC: null == temperatureC
          ? _self.temperatureC!
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double,
      powerUsage: null == powerUsage
          ? _self.powerUsage!
          : powerUsage // ignore: cast_nullable_to_non_nullable
              as DataUnit,
      pcieStatus: null == pcieStatus
          ? _self.pcieStatus!
          : pcieStatus // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpuMemoryCopyWith<$Res> get memory {
    return $GpuMemoryCopyWith<$Res>(_self.memory, (value) {
      return _then(_self.copyWith(memory: value));
    });
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataUnitCopyWith<$Res>? get powerUsage {
    if (_self.powerUsage == null) {
      return null;
    }

    return $DataUnitCopyWith<$Res>(_self.powerUsage!, (value) {
      return _then(_self.copyWith(powerUsage: value));
    });
  }
}

/// Adds pattern-matching-related methods to [GpuInfo].
extension GpuInfoPatterns on GpuInfo {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GpuInfoNvidia value)? nvidia,
    TResult Function(GpuInfoGeneric value)? generic,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia() when nvidia != null:
        return nvidia(_that);
      case GpuInfoGeneric() when generic != null:
        return generic(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(GpuInfoNvidia value) nvidia,
    required TResult Function(GpuInfoGeneric value) generic,
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia():
        return nvidia(_that);
      case GpuInfoGeneric():
        return generic(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GpuInfoNvidia value)? nvidia,
    TResult? Function(GpuInfoGeneric value)? generic,
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia() when nvidia != null:
        return nvidia(_that);
      case GpuInfoGeneric() when generic != null:
        return generic(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String model, String vendor, String uuid, GpuMemory memory,
            double temperatureC, DataUnit powerUsage, String pcieStatus)?
        nvidia,
    TResult Function(
            String model,
            String vendor,
            String? uuid,
            GpuMemory memory,
            double? temperatureC,
            DataUnit? powerUsage,
            String? pcieStatus)?
        generic,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia() when nvidia != null:
        return nvidia(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
      case GpuInfoGeneric() when generic != null:
        return generic(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
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
  TResult when<TResult extends Object?>({
    required TResult Function(
            String model,
            String vendor,
            String uuid,
            GpuMemory memory,
            double temperatureC,
            DataUnit powerUsage,
            String pcieStatus)
        nvidia,
    required TResult Function(
            String model,
            String vendor,
            String? uuid,
            GpuMemory memory,
            double? temperatureC,
            DataUnit? powerUsage,
            String? pcieStatus)
        generic,
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia():
        return nvidia(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
      case GpuInfoGeneric():
        return generic(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String model,
            String vendor,
            String uuid,
            GpuMemory memory,
            double temperatureC,
            DataUnit powerUsage,
            String pcieStatus)?
        nvidia,
    TResult? Function(
            String model,
            String vendor,
            String? uuid,
            GpuMemory memory,
            double? temperatureC,
            DataUnit? powerUsage,
            String? pcieStatus)?
        generic,
  }) {
    final _that = this;
    switch (_that) {
      case GpuInfoNvidia() when nvidia != null:
        return nvidia(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
      case GpuInfoGeneric() when generic != null:
        return generic(_that.model, _that.vendor, _that.uuid, _that.memory,
            _that.temperatureC, _that.powerUsage, _that.pcieStatus);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class GpuInfoNvidia implements GpuInfo {
  const GpuInfoNvidia(
      {required this.model,
      required this.vendor,
      required this.uuid,
      required this.memory,
      required this.temperatureC,
      required this.powerUsage,
      required this.pcieStatus,
      final String? $type})
      : $type = $type ?? 'nvidia';
  factory GpuInfoNvidia.fromJson(Map<String, dynamic> json) =>
      _$GpuInfoNvidiaFromJson(json);

  @override
  final String model;
  @override
  final String vendor;
  @override
  final String uuid;
  @override
  final GpuMemory memory;
  @override
  final double temperatureC;
  @override
  final DataUnit powerUsage;
  @override
  final String pcieStatus;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuInfoNvidiaCopyWith<GpuInfoNvidia> get copyWith =>
      _$GpuInfoNvidiaCopyWithImpl<GpuInfoNvidia>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpuInfoNvidiaToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpuInfoNvidia &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.powerUsage, powerUsage) ||
                other.powerUsage == powerUsage) &&
            (identical(other.pcieStatus, pcieStatus) ||
                other.pcieStatus == pcieStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, model, vendor, uuid, memory,
      temperatureC, powerUsage, pcieStatus);

  @override
  String toString() {
    return 'GpuInfo.nvidia(model: $model, vendor: $vendor, uuid: $uuid, memory: $memory, temperatureC: $temperatureC, powerUsage: $powerUsage, pcieStatus: $pcieStatus)';
  }
}

/// @nodoc
abstract mixin class $GpuInfoNvidiaCopyWith<$Res>
    implements $GpuInfoCopyWith<$Res> {
  factory $GpuInfoNvidiaCopyWith(
          GpuInfoNvidia value, $Res Function(GpuInfoNvidia) _then) =
      _$GpuInfoNvidiaCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String model,
      String vendor,
      String uuid,
      GpuMemory memory,
      double temperatureC,
      DataUnit powerUsage,
      String pcieStatus});

  @override
  $GpuMemoryCopyWith<$Res> get memory;
  @override
  $DataUnitCopyWith<$Res> get powerUsage;
}

/// @nodoc
class _$GpuInfoNvidiaCopyWithImpl<$Res>
    implements $GpuInfoNvidiaCopyWith<$Res> {
  _$GpuInfoNvidiaCopyWithImpl(this._self, this._then);

  final GpuInfoNvidia _self;
  final $Res Function(GpuInfoNvidia) _then;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? model = null,
    Object? vendor = null,
    Object? uuid = null,
    Object? memory = null,
    Object? temperatureC = null,
    Object? powerUsage = null,
    Object? pcieStatus = null,
  }) {
    return _then(GpuInfoNvidia(
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      uuid: null == uuid
          ? _self.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      memory: null == memory
          ? _self.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as GpuMemory,
      temperatureC: null == temperatureC
          ? _self.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double,
      powerUsage: null == powerUsage
          ? _self.powerUsage
          : powerUsage // ignore: cast_nullable_to_non_nullable
              as DataUnit,
      pcieStatus: null == pcieStatus
          ? _self.pcieStatus
          : pcieStatus // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpuMemoryCopyWith<$Res> get memory {
    return $GpuMemoryCopyWith<$Res>(_self.memory, (value) {
      return _then(_self.copyWith(memory: value));
    });
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataUnitCopyWith<$Res> get powerUsage {
    return $DataUnitCopyWith<$Res>(_self.powerUsage, (value) {
      return _then(_self.copyWith(powerUsage: value));
    });
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class GpuInfoGeneric implements GpuInfo {
  const GpuInfoGeneric(
      {required this.model,
      required this.vendor,
      this.uuid,
      required this.memory,
      this.temperatureC,
      this.powerUsage,
      this.pcieStatus,
      final String? $type})
      : $type = $type ?? 'generic';
  factory GpuInfoGeneric.fromJson(Map<String, dynamic> json) =>
      _$GpuInfoGenericFromJson(json);

  @override
  final String model;
  @override
  final String vendor;
  @override
  final String? uuid;
  @override
  final GpuMemory memory;
  @override
  final double? temperatureC;
  @override
  final DataUnit? powerUsage;
  @override
  final String? pcieStatus;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuInfoGenericCopyWith<GpuInfoGeneric> get copyWith =>
      _$GpuInfoGenericCopyWithImpl<GpuInfoGeneric>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpuInfoGenericToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpuInfoGeneric &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.powerUsage, powerUsage) ||
                other.powerUsage == powerUsage) &&
            (identical(other.pcieStatus, pcieStatus) ||
                other.pcieStatus == pcieStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, model, vendor, uuid, memory,
      temperatureC, powerUsage, pcieStatus);

  @override
  String toString() {
    return 'GpuInfo.generic(model: $model, vendor: $vendor, uuid: $uuid, memory: $memory, temperatureC: $temperatureC, powerUsage: $powerUsage, pcieStatus: $pcieStatus)';
  }
}

/// @nodoc
abstract mixin class $GpuInfoGenericCopyWith<$Res>
    implements $GpuInfoCopyWith<$Res> {
  factory $GpuInfoGenericCopyWith(
          GpuInfoGeneric value, $Res Function(GpuInfoGeneric) _then) =
      _$GpuInfoGenericCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String model,
      String vendor,
      String? uuid,
      GpuMemory memory,
      double? temperatureC,
      DataUnit? powerUsage,
      String? pcieStatus});

  @override
  $GpuMemoryCopyWith<$Res> get memory;
  @override
  $DataUnitCopyWith<$Res>? get powerUsage;
}

/// @nodoc
class _$GpuInfoGenericCopyWithImpl<$Res>
    implements $GpuInfoGenericCopyWith<$Res> {
  _$GpuInfoGenericCopyWithImpl(this._self, this._then);

  final GpuInfoGeneric _self;
  final $Res Function(GpuInfoGeneric) _then;

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? model = null,
    Object? vendor = null,
    Object? uuid = freezed,
    Object? memory = null,
    Object? temperatureC = freezed,
    Object? powerUsage = freezed,
    Object? pcieStatus = freezed,
  }) {
    return _then(GpuInfoGeneric(
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      uuid: freezed == uuid
          ? _self.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String?,
      memory: null == memory
          ? _self.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as GpuMemory,
      temperatureC: freezed == temperatureC
          ? _self.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double?,
      powerUsage: freezed == powerUsage
          ? _self.powerUsage
          : powerUsage // ignore: cast_nullable_to_non_nullable
              as DataUnit?,
      pcieStatus: freezed == pcieStatus
          ? _self.pcieStatus
          : pcieStatus // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpuMemoryCopyWith<$Res> get memory {
    return $GpuMemoryCopyWith<$Res>(_self.memory, (value) {
      return _then(_self.copyWith(memory: value));
    });
  }

  /// Create a copy of GpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataUnitCopyWith<$Res>? get powerUsage {
    if (_self.powerUsage == null) {
      return null;
    }

    return $DataUnitCopyWith<$Res>(_self.powerUsage!, (value) {
      return _then(_self.copyWith(powerUsage: value));
    });
  }
}

// dart format on
