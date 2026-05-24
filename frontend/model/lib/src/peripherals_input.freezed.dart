// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'peripherals_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InputDevice {
  String get name;
  String get path;
  String get bustype;
  String get vendor;
  String get product;

  /// Create a copy of InputDevice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InputDeviceCopyWith<InputDevice> get copyWith =>
      _$InputDeviceCopyWithImpl<InputDevice>(this as InputDevice, _$identity);

  /// Serializes this InputDevice to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InputDevice &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.bustype, bustype) || other.bustype == bustype) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.product, product) || other.product == product));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, path, bustype, vendor, product);

  @override
  String toString() {
    return 'InputDevice(name: $name, path: $path, bustype: $bustype, vendor: $vendor, product: $product)';
  }
}

/// @nodoc
abstract mixin class $InputDeviceCopyWith<$Res> {
  factory $InputDeviceCopyWith(
          InputDevice value, $Res Function(InputDevice) _then) =
      _$InputDeviceCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String path,
      String bustype,
      String vendor,
      String product});
}

/// @nodoc
class _$InputDeviceCopyWithImpl<$Res> implements $InputDeviceCopyWith<$Res> {
  _$InputDeviceCopyWithImpl(this._self, this._then);

  final InputDevice _self;
  final $Res Function(InputDevice) _then;

  /// Create a copy of InputDevice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? bustype = null,
    Object? vendor = null,
    Object? product = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      bustype: null == bustype
          ? _self.bustype
          : bustype // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      product: null == product
          ? _self.product
          : product // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [InputDevice].
extension InputDevicePatterns on InputDevice {
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
    TResult Function(_InputDevice value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InputDevice() when $default != null:
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
    TResult Function(_InputDevice value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputDevice():
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
    TResult? Function(_InputDevice value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputDevice() when $default != null:
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
    TResult Function(String name, String path, String bustype, String vendor,
            String product)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InputDevice() when $default != null:
        return $default(
            _that.name, _that.path, _that.bustype, _that.vendor, _that.product);
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
    TResult Function(String name, String path, String bustype, String vendor,
            String product)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputDevice():
        return $default(
            _that.name, _that.path, _that.bustype, _that.vendor, _that.product);
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
    TResult? Function(String name, String path, String bustype, String vendor,
            String product)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputDevice() when $default != null:
        return $default(
            _that.name, _that.path, _that.bustype, _that.vendor, _that.product);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _InputDevice implements InputDevice {
  const _InputDevice(
      {required this.name,
      required this.path,
      required this.bustype,
      required this.vendor,
      required this.product});
  factory _InputDevice.fromJson(Map<String, dynamic> json) =>
      _$InputDeviceFromJson(json);

  @override
  final String name;
  @override
  final String path;
  @override
  final String bustype;
  @override
  final String vendor;
  @override
  final String product;

  /// Create a copy of InputDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InputDeviceCopyWith<_InputDevice> get copyWith =>
      __$InputDeviceCopyWithImpl<_InputDevice>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InputDeviceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InputDevice &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.bustype, bustype) || other.bustype == bustype) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.product, product) || other.product == product));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, path, bustype, vendor, product);

  @override
  String toString() {
    return 'InputDevice(name: $name, path: $path, bustype: $bustype, vendor: $vendor, product: $product)';
  }
}

/// @nodoc
abstract mixin class _$InputDeviceCopyWith<$Res>
    implements $InputDeviceCopyWith<$Res> {
  factory _$InputDeviceCopyWith(
          _InputDevice value, $Res Function(_InputDevice) _then) =
      __$InputDeviceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String path,
      String bustype,
      String vendor,
      String product});
}

/// @nodoc
class __$InputDeviceCopyWithImpl<$Res> implements _$InputDeviceCopyWith<$Res> {
  __$InputDeviceCopyWithImpl(this._self, this._then);

  final _InputDevice _self;
  final $Res Function(_InputDevice) _then;

  /// Create a copy of InputDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? path = null,
    Object? bustype = null,
    Object? vendor = null,
    Object? product = null,
  }) {
    return _then(_InputDevice(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      bustype: null == bustype
          ? _self.bustype
          : bustype // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: null == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String,
      product: null == product
          ? _self.product
          : product // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$DisplayInfo {
  String get id;
  int get width;
  int get height;
  double get refreshRate;
  bool get isConnected;
  String? get edid;

  /// Create a copy of DisplayInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DisplayInfoCopyWith<DisplayInfo> get copyWith =>
      _$DisplayInfoCopyWithImpl<DisplayInfo>(this as DisplayInfo, _$identity);

  /// Serializes this DisplayInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DisplayInfo &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.refreshRate, refreshRate) ||
                other.refreshRate == refreshRate) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.edid, edid) || other.edid == edid));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, width, height, refreshRate, isConnected, edid);

  @override
  String toString() {
    return 'DisplayInfo(id: $id, width: $width, height: $height, refreshRate: $refreshRate, isConnected: $isConnected, edid: $edid)';
  }
}

/// @nodoc
abstract mixin class $DisplayInfoCopyWith<$Res> {
  factory $DisplayInfoCopyWith(
          DisplayInfo value, $Res Function(DisplayInfo) _then) =
      _$DisplayInfoCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      int width,
      int height,
      double refreshRate,
      bool isConnected,
      String? edid});
}

/// @nodoc
class _$DisplayInfoCopyWithImpl<$Res> implements $DisplayInfoCopyWith<$Res> {
  _$DisplayInfoCopyWithImpl(this._self, this._then);

  final DisplayInfo _self;
  final $Res Function(DisplayInfo) _then;

  /// Create a copy of DisplayInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? width = null,
    Object? height = null,
    Object? refreshRate = null,
    Object? isConnected = null,
    Object? edid = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      refreshRate: null == refreshRate
          ? _self.refreshRate
          : refreshRate // ignore: cast_nullable_to_non_nullable
              as double,
      isConnected: null == isConnected
          ? _self.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      edid: freezed == edid
          ? _self.edid
          : edid // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DisplayInfo].
extension DisplayInfoPatterns on DisplayInfo {
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
    TResult Function(_DisplayInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo() when $default != null:
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
    TResult Function(_DisplayInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo():
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
    TResult? Function(_DisplayInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo() when $default != null:
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
    TResult Function(String id, int width, int height, double refreshRate,
            bool isConnected, String? edid)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo() when $default != null:
        return $default(_that.id, _that.width, _that.height, _that.refreshRate,
            _that.isConnected, _that.edid);
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
    TResult Function(String id, int width, int height, double refreshRate,
            bool isConnected, String? edid)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo():
        return $default(_that.id, _that.width, _that.height, _that.refreshRate,
            _that.isConnected, _that.edid);
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
    TResult? Function(String id, int width, int height, double refreshRate,
            bool isConnected, String? edid)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DisplayInfo() when $default != null:
        return $default(_that.id, _that.width, _that.height, _that.refreshRate,
            _that.isConnected, _that.edid);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DisplayInfo implements DisplayInfo {
  const _DisplayInfo(
      {required this.id,
      required this.width,
      required this.height,
      required this.refreshRate,
      required this.isConnected,
      this.edid});
  factory _DisplayInfo.fromJson(Map<String, dynamic> json) =>
      _$DisplayInfoFromJson(json);

  @override
  final String id;
  @override
  final int width;
  @override
  final int height;
  @override
  final double refreshRate;
  @override
  final bool isConnected;
  @override
  final String? edid;

  /// Create a copy of DisplayInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DisplayInfoCopyWith<_DisplayInfo> get copyWith =>
      __$DisplayInfoCopyWithImpl<_DisplayInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DisplayInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DisplayInfo &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.refreshRate, refreshRate) ||
                other.refreshRate == refreshRate) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.edid, edid) || other.edid == edid));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, width, height, refreshRate, isConnected, edid);

  @override
  String toString() {
    return 'DisplayInfo(id: $id, width: $width, height: $height, refreshRate: $refreshRate, isConnected: $isConnected, edid: $edid)';
  }
}

/// @nodoc
abstract mixin class _$DisplayInfoCopyWith<$Res>
    implements $DisplayInfoCopyWith<$Res> {
  factory _$DisplayInfoCopyWith(
          _DisplayInfo value, $Res Function(_DisplayInfo) _then) =
      __$DisplayInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      int width,
      int height,
      double refreshRate,
      bool isConnected,
      String? edid});
}

/// @nodoc
class __$DisplayInfoCopyWithImpl<$Res> implements _$DisplayInfoCopyWith<$Res> {
  __$DisplayInfoCopyWithImpl(this._self, this._then);

  final _DisplayInfo _self;
  final $Res Function(_DisplayInfo) _then;

  /// Create a copy of DisplayInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? width = null,
    Object? height = null,
    Object? refreshRate = null,
    Object? isConnected = null,
    Object? edid = freezed,
  }) {
    return _then(_DisplayInfo(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      refreshRate: null == refreshRate
          ? _self.refreshRate
          : refreshRate // ignore: cast_nullable_to_non_nullable
              as double,
      isConnected: null == isConnected
          ? _self.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      edid: freezed == edid
          ? _self.edid
          : edid // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$InputCapabilities {
  bool get supportsPressure;
  bool get supportsMultiTouch;
  bool get hasHaptics;

  /// Create a copy of InputCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InputCapabilitiesCopyWith<InputCapabilities> get copyWith =>
      _$InputCapabilitiesCopyWithImpl<InputCapabilities>(
          this as InputCapabilities, _$identity);

  /// Serializes this InputCapabilities to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InputCapabilities &&
            (identical(other.supportsPressure, supportsPressure) ||
                other.supportsPressure == supportsPressure) &&
            (identical(other.supportsMultiTouch, supportsMultiTouch) ||
                other.supportsMultiTouch == supportsMultiTouch) &&
            (identical(other.hasHaptics, hasHaptics) ||
                other.hasHaptics == hasHaptics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, supportsPressure, supportsMultiTouch, hasHaptics);

  @override
  String toString() {
    return 'InputCapabilities(supportsPressure: $supportsPressure, supportsMultiTouch: $supportsMultiTouch, hasHaptics: $hasHaptics)';
  }
}

/// @nodoc
abstract mixin class $InputCapabilitiesCopyWith<$Res> {
  factory $InputCapabilitiesCopyWith(
          InputCapabilities value, $Res Function(InputCapabilities) _then) =
      _$InputCapabilitiesCopyWithImpl;
  @useResult
  $Res call({bool supportsPressure, bool supportsMultiTouch, bool hasHaptics});
}

/// @nodoc
class _$InputCapabilitiesCopyWithImpl<$Res>
    implements $InputCapabilitiesCopyWith<$Res> {
  _$InputCapabilitiesCopyWithImpl(this._self, this._then);

  final InputCapabilities _self;
  final $Res Function(InputCapabilities) _then;

  /// Create a copy of InputCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? supportsPressure = null,
    Object? supportsMultiTouch = null,
    Object? hasHaptics = null,
  }) {
    return _then(_self.copyWith(
      supportsPressure: null == supportsPressure
          ? _self.supportsPressure
          : supportsPressure // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsMultiTouch: null == supportsMultiTouch
          ? _self.supportsMultiTouch
          : supportsMultiTouch // ignore: cast_nullable_to_non_nullable
              as bool,
      hasHaptics: null == hasHaptics
          ? _self.hasHaptics
          : hasHaptics // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [InputCapabilities].
extension InputCapabilitiesPatterns on InputCapabilities {
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
    TResult Function(_InputCapabilities value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities() when $default != null:
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
    TResult Function(_InputCapabilities value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities():
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
    TResult? Function(_InputCapabilities value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities() when $default != null:
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
            bool supportsPressure, bool supportsMultiTouch, bool hasHaptics)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities() when $default != null:
        return $default(
            _that.supportsPressure, _that.supportsMultiTouch, _that.hasHaptics);
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
            bool supportsPressure, bool supportsMultiTouch, bool hasHaptics)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities():
        return $default(
            _that.supportsPressure, _that.supportsMultiTouch, _that.hasHaptics);
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
            bool supportsPressure, bool supportsMultiTouch, bool hasHaptics)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InputCapabilities() when $default != null:
        return $default(
            _that.supportsPressure, _that.supportsMultiTouch, _that.hasHaptics);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _InputCapabilities implements InputCapabilities {
  const _InputCapabilities(
      {required this.supportsPressure,
      required this.supportsMultiTouch,
      required this.hasHaptics});
  factory _InputCapabilities.fromJson(Map<String, dynamic> json) =>
      _$InputCapabilitiesFromJson(json);

  @override
  final bool supportsPressure;
  @override
  final bool supportsMultiTouch;
  @override
  final bool hasHaptics;

  /// Create a copy of InputCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InputCapabilitiesCopyWith<_InputCapabilities> get copyWith =>
      __$InputCapabilitiesCopyWithImpl<_InputCapabilities>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InputCapabilitiesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InputCapabilities &&
            (identical(other.supportsPressure, supportsPressure) ||
                other.supportsPressure == supportsPressure) &&
            (identical(other.supportsMultiTouch, supportsMultiTouch) ||
                other.supportsMultiTouch == supportsMultiTouch) &&
            (identical(other.hasHaptics, hasHaptics) ||
                other.hasHaptics == hasHaptics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, supportsPressure, supportsMultiTouch, hasHaptics);

  @override
  String toString() {
    return 'InputCapabilities(supportsPressure: $supportsPressure, supportsMultiTouch: $supportsMultiTouch, hasHaptics: $hasHaptics)';
  }
}

/// @nodoc
abstract mixin class _$InputCapabilitiesCopyWith<$Res>
    implements $InputCapabilitiesCopyWith<$Res> {
  factory _$InputCapabilitiesCopyWith(
          _InputCapabilities value, $Res Function(_InputCapabilities) _then) =
      __$InputCapabilitiesCopyWithImpl;
  @override
  @useResult
  $Res call({bool supportsPressure, bool supportsMultiTouch, bool hasHaptics});
}

/// @nodoc
class __$InputCapabilitiesCopyWithImpl<$Res>
    implements _$InputCapabilitiesCopyWith<$Res> {
  __$InputCapabilitiesCopyWithImpl(this._self, this._then);

  final _InputCapabilities _self;
  final $Res Function(_InputCapabilities) _then;

  /// Create a copy of InputCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? supportsPressure = null,
    Object? supportsMultiTouch = null,
    Object? hasHaptics = null,
  }) {
    return _then(_InputCapabilities(
      supportsPressure: null == supportsPressure
          ? _self.supportsPressure
          : supportsPressure // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsMultiTouch: null == supportsMultiTouch
          ? _self.supportsMultiTouch
          : supportsMultiTouch // ignore: cast_nullable_to_non_nullable
              as bool,
      hasHaptics: null == hasHaptics
          ? _self.hasHaptics
          : hasHaptics // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
