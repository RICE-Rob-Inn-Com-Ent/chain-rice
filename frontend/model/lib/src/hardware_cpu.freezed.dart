// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hardware_cpu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CpuCore {
  int get id;
  double get load;
  double get frequency;
  double get temp;

  /// Create a copy of CpuCore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CpuCoreCopyWith<CpuCore> get copyWith =>
      _$CpuCoreCopyWithImpl<CpuCore>(this as CpuCore, _$identity);

  /// Serializes this CpuCore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CpuCore &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.load, load) || other.load == load) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.temp, temp) || other.temp == temp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, load, frequency, temp);

  @override
  String toString() {
    return 'CpuCore(id: $id, load: $load, frequency: $frequency, temp: $temp)';
  }
}

/// @nodoc
abstract mixin class $CpuCoreCopyWith<$Res> {
  factory $CpuCoreCopyWith(CpuCore value, $Res Function(CpuCore) _then) =
      _$CpuCoreCopyWithImpl;
  @useResult
  $Res call({int id, double load, double frequency, double temp});
}

/// @nodoc
class _$CpuCoreCopyWithImpl<$Res> implements $CpuCoreCopyWith<$Res> {
  _$CpuCoreCopyWithImpl(this._self, this._then);

  final CpuCore _self;
  final $Res Function(CpuCore) _then;

  /// Create a copy of CpuCore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? load = null,
    Object? frequency = null,
    Object? temp = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      load: null == load
          ? _self.load
          : load // ignore: cast_nullable_to_non_nullable
              as double,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
      temp: null == temp
          ? _self.temp
          : temp // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [CpuCore].
extension CpuCorePatterns on CpuCore {
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
    TResult Function(_CpuCore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuCore() when $default != null:
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
    TResult Function(_CpuCore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuCore():
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
    TResult? Function(_CpuCore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuCore() when $default != null:
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
    TResult Function(int id, double load, double frequency, double temp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuCore() when $default != null:
        return $default(_that.id, _that.load, _that.frequency, _that.temp);
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
    TResult Function(int id, double load, double frequency, double temp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuCore():
        return $default(_that.id, _that.load, _that.frequency, _that.temp);
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
    TResult? Function(int id, double load, double frequency, double temp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuCore() when $default != null:
        return $default(_that.id, _that.load, _that.frequency, _that.temp);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CpuCore implements CpuCore {
  const _CpuCore(
      {required this.id,
      required this.load,
      required this.frequency,
      required this.temp});
  factory _CpuCore.fromJson(Map<String, dynamic> json) =>
      _$CpuCoreFromJson(json);

  @override
  final int id;
  @override
  final double load;
  @override
  final double frequency;
  @override
  final double temp;

  /// Create a copy of CpuCore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CpuCoreCopyWith<_CpuCore> get copyWith =>
      __$CpuCoreCopyWithImpl<_CpuCore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CpuCoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CpuCore &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.load, load) || other.load == load) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.temp, temp) || other.temp == temp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, load, frequency, temp);

  @override
  String toString() {
    return 'CpuCore(id: $id, load: $load, frequency: $frequency, temp: $temp)';
  }
}

/// @nodoc
abstract mixin class _$CpuCoreCopyWith<$Res> implements $CpuCoreCopyWith<$Res> {
  factory _$CpuCoreCopyWith(_CpuCore value, $Res Function(_CpuCore) _then) =
      __$CpuCoreCopyWithImpl;
  @override
  @useResult
  $Res call({int id, double load, double frequency, double temp});
}

/// @nodoc
class __$CpuCoreCopyWithImpl<$Res> implements _$CpuCoreCopyWith<$Res> {
  __$CpuCoreCopyWithImpl(this._self, this._then);

  final _CpuCore _self;
  final $Res Function(_CpuCore) _then;

  /// Create a copy of CpuCore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? load = null,
    Object? frequency = null,
    Object? temp = null,
  }) {
    return _then(_CpuCore(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      load: null == load
          ? _self.load
          : load // ignore: cast_nullable_to_non_nullable
              as double,
      frequency: null == frequency
          ? _self.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as double,
      temp: null == temp
          ? _self.temp
          : temp // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$CpuInfo {
  String get model;
  String get architecture;
  String get vendor;
  int get logicalCores;
  int get physicalPackages;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CpuInfoCopyWith<CpuInfo> get copyWith =>
      _$CpuInfoCopyWithImpl<CpuInfo>(this as CpuInfo, _$identity);

  /// Serializes this CpuInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CpuInfo &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.logicalCores, logicalCores) ||
                other.logicalCores == logicalCores) &&
            (identical(other.physicalPackages, physicalPackages) ||
                other.physicalPackages == physicalPackages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, model, architecture, vendor, logicalCores, physicalPackages);

  @override
  String toString() {
    return 'CpuInfo(model: $model, architecture: $architecture, vendor: $vendor, logicalCores: $logicalCores, physicalPackages: $physicalPackages)';
  }
}

/// @nodoc
abstract mixin class $CpuInfoCopyWith<$Res> {
  factory $CpuInfoCopyWith(CpuInfo value, $Res Function(CpuInfo) _then) =
      _$CpuInfoCopyWithImpl;
  @useResult
  $Res call(
      {String model,
      String architecture,
      String vendor,
      int logicalCores,
      int physicalPackages});
}

/// @nodoc
class _$CpuInfoCopyWithImpl<$Res> implements $CpuInfoCopyWith<$Res> {
  _$CpuInfoCopyWithImpl(this._self, this._then);

  final CpuInfo _self;
  final $Res Function(CpuInfo) _then;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? model = null,
    Object? architecture = null,
    Object? vendor = null,
    Object? logicalCores = null,
    Object? physicalPackages = null,
  }) {
    return _then(_self.copyWith(
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      architecture: null == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      logicalCores: null == logicalCores
          ? _self.logicalCores
          : logicalCores // ignore: cast_nullable_to_non_nullable
              as int,
      physicalPackages: null == physicalPackages
          ? _self.physicalPackages
          : physicalPackages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [CpuInfo].
extension CpuInfoPatterns on CpuInfo {
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
    TResult Function(_CpuInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuInfo() when $default != null:
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
    TResult Function(_CpuInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuInfo():
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
    TResult? Function(_CpuInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuInfo() when $default != null:
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
    TResult Function(String model, String architecture, String vendor,
            int logicalCores, int physicalPackages)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuInfo() when $default != null:
        return $default(_that.model, _that.architecture, _that.vendor,
            _that.logicalCores, _that.physicalPackages);
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
    TResult Function(String model, String architecture, String vendor,
            int logicalCores, int physicalPackages)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuInfo():
        return $default(_that.model, _that.architecture, _that.vendor,
            _that.logicalCores, _that.physicalPackages);
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
    TResult? Function(String model, String architecture, String vendor,
            int logicalCores, int physicalPackages)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuInfo() when $default != null:
        return $default(_that.model, _that.architecture, _that.vendor,
            _that.logicalCores, _that.physicalPackages);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CpuInfo implements CpuInfo {
  const _CpuInfo(
      {required this.model,
      required this.architecture,
      required this.vendor,
      required this.logicalCores,
      required this.physicalPackages});
  factory _CpuInfo.fromJson(Map<String, dynamic> json) =>
      _$CpuInfoFromJson(json);

  @override
  final String model;
  @override
  final String architecture;
  @override
  final String vendor;
  @override
  final int logicalCores;
  @override
  final int physicalPackages;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CpuInfoCopyWith<_CpuInfo> get copyWith =>
      __$CpuInfoCopyWithImpl<_CpuInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CpuInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CpuInfo &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.logicalCores, logicalCores) ||
                other.logicalCores == logicalCores) &&
            (identical(other.physicalPackages, physicalPackages) ||
                other.physicalPackages == physicalPackages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, model, architecture, vendor, logicalCores, physicalPackages);

  @override
  String toString() {
    return 'CpuInfo(model: $model, architecture: $architecture, vendor: $vendor, logicalCores: $logicalCores, physicalPackages: $physicalPackages)';
  }
}

/// @nodoc
abstract mixin class _$CpuInfoCopyWith<$Res> implements $CpuInfoCopyWith<$Res> {
  factory _$CpuInfoCopyWith(_CpuInfo value, $Res Function(_CpuInfo) _then) =
      __$CpuInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String model,
      String architecture,
      String vendor,
      int logicalCores,
      int physicalPackages});
}

/// @nodoc
class __$CpuInfoCopyWithImpl<$Res> implements _$CpuInfoCopyWith<$Res> {
  __$CpuInfoCopyWithImpl(this._self, this._then);

  final _CpuInfo _self;
  final $Res Function(_CpuInfo) _then;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? model = null,
    Object? architecture = null,
    Object? vendor = null,
    Object? logicalCores = null,
    Object? physicalPackages = null,
  }) {
    return _then(_CpuInfo(
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      architecture: null == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      logicalCores: null == logicalCores
          ? _self.logicalCores
          : logicalCores // ignore: cast_nullable_to_non_nullable
              as int,
      physicalPackages: null == physicalPackages
          ? _self.physicalPackages
          : physicalPackages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$CpuTopology {
  int? get cacheL1Kb;
  int? get cacheL2Kb;
  int? get cacheL3Kb;
  int get numaNodes;

  /// Create a copy of CpuTopology
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CpuTopologyCopyWith<CpuTopology> get copyWith =>
      _$CpuTopologyCopyWithImpl<CpuTopology>(this as CpuTopology, _$identity);

  /// Serializes this CpuTopology to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CpuTopology &&
            (identical(other.cacheL1Kb, cacheL1Kb) ||
                other.cacheL1Kb == cacheL1Kb) &&
            (identical(other.cacheL2Kb, cacheL2Kb) ||
                other.cacheL2Kb == cacheL2Kb) &&
            (identical(other.cacheL3Kb, cacheL3Kb) ||
                other.cacheL3Kb == cacheL3Kb) &&
            (identical(other.numaNodes, numaNodes) ||
                other.numaNodes == numaNodes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, cacheL1Kb, cacheL2Kb, cacheL3Kb, numaNodes);

  @override
  String toString() {
    return 'CpuTopology(cacheL1Kb: $cacheL1Kb, cacheL2Kb: $cacheL2Kb, cacheL3Kb: $cacheL3Kb, numaNodes: $numaNodes)';
  }
}

/// @nodoc
abstract mixin class $CpuTopologyCopyWith<$Res> {
  factory $CpuTopologyCopyWith(
          CpuTopology value, $Res Function(CpuTopology) _then) =
      _$CpuTopologyCopyWithImpl;
  @useResult
  $Res call({int? cacheL1Kb, int? cacheL2Kb, int? cacheL3Kb, int numaNodes});
}

/// @nodoc
class _$CpuTopologyCopyWithImpl<$Res> implements $CpuTopologyCopyWith<$Res> {
  _$CpuTopologyCopyWithImpl(this._self, this._then);

  final CpuTopology _self;
  final $Res Function(CpuTopology) _then;

  /// Create a copy of CpuTopology
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cacheL1Kb = freezed,
    Object? cacheL2Kb = freezed,
    Object? cacheL3Kb = freezed,
    Object? numaNodes = null,
  }) {
    return _then(_self.copyWith(
      cacheL1Kb: freezed == cacheL1Kb
          ? _self.cacheL1Kb
          : cacheL1Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheL2Kb: freezed == cacheL2Kb
          ? _self.cacheL2Kb
          : cacheL2Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheL3Kb: freezed == cacheL3Kb
          ? _self.cacheL3Kb
          : cacheL3Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      numaNodes: null == numaNodes
          ? _self.numaNodes
          : numaNodes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [CpuTopology].
extension CpuTopologyPatterns on CpuTopology {
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
    TResult Function(_CpuTopology value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuTopology() when $default != null:
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
    TResult Function(_CpuTopology value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuTopology():
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
    TResult? Function(_CpuTopology value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuTopology() when $default != null:
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
            int? cacheL1Kb, int? cacheL2Kb, int? cacheL3Kb, int numaNodes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuTopology() when $default != null:
        return $default(
            _that.cacheL1Kb, _that.cacheL2Kb, _that.cacheL3Kb, _that.numaNodes);
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
            int? cacheL1Kb, int? cacheL2Kb, int? cacheL3Kb, int numaNodes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuTopology():
        return $default(
            _that.cacheL1Kb, _that.cacheL2Kb, _that.cacheL3Kb, _that.numaNodes);
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
            int? cacheL1Kb, int? cacheL2Kb, int? cacheL3Kb, int numaNodes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuTopology() when $default != null:
        return $default(
            _that.cacheL1Kb, _that.cacheL2Kb, _that.cacheL3Kb, _that.numaNodes);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CpuTopology implements CpuTopology {
  const _CpuTopology(
      {this.cacheL1Kb, this.cacheL2Kb, this.cacheL3Kb, this.numaNodes = 1});
  factory _CpuTopology.fromJson(Map<String, dynamic> json) =>
      _$CpuTopologyFromJson(json);

  @override
  final int? cacheL1Kb;
  @override
  final int? cacheL2Kb;
  @override
  final int? cacheL3Kb;
  @override
  @JsonKey()
  final int numaNodes;

  /// Create a copy of CpuTopology
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CpuTopologyCopyWith<_CpuTopology> get copyWith =>
      __$CpuTopologyCopyWithImpl<_CpuTopology>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CpuTopologyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CpuTopology &&
            (identical(other.cacheL1Kb, cacheL1Kb) ||
                other.cacheL1Kb == cacheL1Kb) &&
            (identical(other.cacheL2Kb, cacheL2Kb) ||
                other.cacheL2Kb == cacheL2Kb) &&
            (identical(other.cacheL3Kb, cacheL3Kb) ||
                other.cacheL3Kb == cacheL3Kb) &&
            (identical(other.numaNodes, numaNodes) ||
                other.numaNodes == numaNodes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, cacheL1Kb, cacheL2Kb, cacheL3Kb, numaNodes);

  @override
  String toString() {
    return 'CpuTopology(cacheL1Kb: $cacheL1Kb, cacheL2Kb: $cacheL2Kb, cacheL3Kb: $cacheL3Kb, numaNodes: $numaNodes)';
  }
}

/// @nodoc
abstract mixin class _$CpuTopologyCopyWith<$Res>
    implements $CpuTopologyCopyWith<$Res> {
  factory _$CpuTopologyCopyWith(
          _CpuTopology value, $Res Function(_CpuTopology) _then) =
      __$CpuTopologyCopyWithImpl;
  @override
  @useResult
  $Res call({int? cacheL1Kb, int? cacheL2Kb, int? cacheL3Kb, int numaNodes});
}

/// @nodoc
class __$CpuTopologyCopyWithImpl<$Res> implements _$CpuTopologyCopyWith<$Res> {
  __$CpuTopologyCopyWithImpl(this._self, this._then);

  final _CpuTopology _self;
  final $Res Function(_CpuTopology) _then;

  /// Create a copy of CpuTopology
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cacheL1Kb = freezed,
    Object? cacheL2Kb = freezed,
    Object? cacheL3Kb = freezed,
    Object? numaNodes = null,
  }) {
    return _then(_CpuTopology(
      cacheL1Kb: freezed == cacheL1Kb
          ? _self.cacheL1Kb
          : cacheL1Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheL2Kb: freezed == cacheL2Kb
          ? _self.cacheL2Kb
          : cacheL2Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheL3Kb: freezed == cacheL3Kb
          ? _self.cacheL3Kb
          : cacheL3Kb // ignore: cast_nullable_to_non_nullable
              as int?,
      numaNodes: null == numaNodes
          ? _self.numaNodes
          : numaNodes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
