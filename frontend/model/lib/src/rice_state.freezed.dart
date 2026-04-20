// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rice_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RiceState {
  String get sessionId;
  Map<String, dynamic> get context;
  List<Entity> get entities;

  /// Create a copy of RiceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RiceStateCopyWith<RiceState> get copyWith =>
      _$RiceStateCopyWithImpl<RiceState>(this as RiceState, _$identity);

  /// Serializes this RiceState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RiceState &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            const DeepCollectionEquality().equals(other.context, context) &&
            const DeepCollectionEquality().equals(other.entities, entities));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sessionId,
      const DeepCollectionEquality().hash(context),
      const DeepCollectionEquality().hash(entities));

  @override
  String toString() {
    return 'RiceState(sessionId: $sessionId, context: $context, entities: $entities)';
  }
}

/// @nodoc
abstract mixin class $RiceStateCopyWith<$Res> {
  factory $RiceStateCopyWith(RiceState value, $Res Function(RiceState) _then) =
      _$RiceStateCopyWithImpl;
  @useResult
  $Res call(
      {String sessionId, Map<String, dynamic> context, List<Entity> entities});
}

/// @nodoc
class _$RiceStateCopyWithImpl<$Res> implements $RiceStateCopyWith<$Res> {
  _$RiceStateCopyWithImpl(this._self, this._then);

  final RiceState _self;
  final $Res Function(RiceState) _then;

  /// Create a copy of RiceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? context = null,
    Object? entities = null,
  }) {
    return _then(_self.copyWith(
      sessionId: null == sessionId
          ? _self.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _self.context
          : context // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      entities: null == entities
          ? _self.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<Entity>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RiceState].
extension RiceStatePatterns on RiceState {
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
    TResult Function(_RiceState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RiceState() when $default != null:
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
    TResult Function(_RiceState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RiceState():
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
    TResult? Function(_RiceState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RiceState() when $default != null:
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
    TResult Function(String sessionId, Map<String, dynamic> context,
            List<Entity> entities)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RiceState() when $default != null:
        return $default(_that.sessionId, _that.context, _that.entities);
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
    TResult Function(String sessionId, Map<String, dynamic> context,
            List<Entity> entities)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RiceState():
        return $default(_that.sessionId, _that.context, _that.entities);
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
    TResult? Function(String sessionId, Map<String, dynamic> context,
            List<Entity> entities)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RiceState() when $default != null:
        return $default(_that.sessionId, _that.context, _that.entities);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RiceState implements RiceState {
  const _RiceState(
      {this.sessionId = '',
      final Map<String, dynamic> context = const <String, dynamic>{},
      final List<Entity> entities = const <Entity>[]})
      : _context = context,
        _entities = entities;
  factory _RiceState.fromJson(Map<String, dynamic> json) =>
      _$RiceStateFromJson(json);

  @override
  @JsonKey()
  final String sessionId;
  final Map<String, dynamic> _context;
  @override
  @JsonKey()
  Map<String, dynamic> get context {
    if (_context is EqualUnmodifiableMapView) return _context;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_context);
  }

  final List<Entity> _entities;
  @override
  @JsonKey()
  List<Entity> get entities {
    if (_entities is EqualUnmodifiableListView) return _entities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entities);
  }

  /// Create a copy of RiceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RiceStateCopyWith<_RiceState> get copyWith =>
      __$RiceStateCopyWithImpl<_RiceState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RiceStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RiceState &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            const DeepCollectionEquality().equals(other._context, _context) &&
            const DeepCollectionEquality().equals(other._entities, _entities));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sessionId,
      const DeepCollectionEquality().hash(_context),
      const DeepCollectionEquality().hash(_entities));

  @override
  String toString() {
    return 'RiceState(sessionId: $sessionId, context: $context, entities: $entities)';
  }
}

/// @nodoc
abstract mixin class _$RiceStateCopyWith<$Res>
    implements $RiceStateCopyWith<$Res> {
  factory _$RiceStateCopyWith(
          _RiceState value, $Res Function(_RiceState) _then) =
      __$RiceStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String sessionId, Map<String, dynamic> context, List<Entity> entities});
}

/// @nodoc
class __$RiceStateCopyWithImpl<$Res> implements _$RiceStateCopyWith<$Res> {
  __$RiceStateCopyWithImpl(this._self, this._then);

  final _RiceState _self;
  final $Res Function(_RiceState) _then;

  /// Create a copy of RiceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sessionId = null,
    Object? context = null,
    Object? entities = null,
  }) {
    return _then(_RiceState(
      sessionId: null == sessionId
          ? _self.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _self._context
          : context // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      entities: null == entities
          ? _self._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<Entity>,
    ));
  }
}

// dart format on
