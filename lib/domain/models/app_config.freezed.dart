// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {

 int get id; AppThemeMode get themeMode; PageDirection get pageDirection; DoublePageMode get doublePageMode; bool get crossChapter; int get cacheLimitMB; int get thumbnailConcurrency; AutoSyncInterval get autoSyncInterval; DateTime get updatedAt;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.pageDirection, pageDirection) || other.pageDirection == pageDirection)&&(identical(other.doublePageMode, doublePageMode) || other.doublePageMode == doublePageMode)&&(identical(other.crossChapter, crossChapter) || other.crossChapter == crossChapter)&&(identical(other.cacheLimitMB, cacheLimitMB) || other.cacheLimitMB == cacheLimitMB)&&(identical(other.thumbnailConcurrency, thumbnailConcurrency) || other.thumbnailConcurrency == thumbnailConcurrency)&&(identical(other.autoSyncInterval, autoSyncInterval) || other.autoSyncInterval == autoSyncInterval)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,themeMode,pageDirection,doublePageMode,crossChapter,cacheLimitMB,thumbnailConcurrency,autoSyncInterval,updatedAt);

@override
String toString() {
  return 'AppConfig(id: $id, themeMode: $themeMode, pageDirection: $pageDirection, doublePageMode: $doublePageMode, crossChapter: $crossChapter, cacheLimitMB: $cacheLimitMB, thumbnailConcurrency: $thumbnailConcurrency, autoSyncInterval: $autoSyncInterval, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 int id, AppThemeMode themeMode, PageDirection pageDirection, DoublePageMode doublePageMode, bool crossChapter, int cacheLimitMB, int thumbnailConcurrency, AutoSyncInterval autoSyncInterval, DateTime updatedAt
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? themeMode = null,Object? pageDirection = null,Object? doublePageMode = null,Object? crossChapter = null,Object? cacheLimitMB = null,Object? thumbnailConcurrency = null,Object? autoSyncInterval = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,pageDirection: null == pageDirection ? _self.pageDirection : pageDirection // ignore: cast_nullable_to_non_nullable
as PageDirection,doublePageMode: null == doublePageMode ? _self.doublePageMode : doublePageMode // ignore: cast_nullable_to_non_nullable
as DoublePageMode,crossChapter: null == crossChapter ? _self.crossChapter : crossChapter // ignore: cast_nullable_to_non_nullable
as bool,cacheLimitMB: null == cacheLimitMB ? _self.cacheLimitMB : cacheLimitMB // ignore: cast_nullable_to_non_nullable
as int,thumbnailConcurrency: null == thumbnailConcurrency ? _self.thumbnailConcurrency : thumbnailConcurrency // ignore: cast_nullable_to_non_nullable
as int,autoSyncInterval: null == autoSyncInterval ? _self.autoSyncInterval : autoSyncInterval // ignore: cast_nullable_to_non_nullable
as AutoSyncInterval,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  AppThemeMode themeMode,  PageDirection pageDirection,  DoublePageMode doublePageMode,  bool crossChapter,  int cacheLimitMB,  int thumbnailConcurrency,  AutoSyncInterval autoSyncInterval,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.id,_that.themeMode,_that.pageDirection,_that.doublePageMode,_that.crossChapter,_that.cacheLimitMB,_that.thumbnailConcurrency,_that.autoSyncInterval,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  AppThemeMode themeMode,  PageDirection pageDirection,  DoublePageMode doublePageMode,  bool crossChapter,  int cacheLimitMB,  int thumbnailConcurrency,  AutoSyncInterval autoSyncInterval,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.id,_that.themeMode,_that.pageDirection,_that.doublePageMode,_that.crossChapter,_that.cacheLimitMB,_that.thumbnailConcurrency,_that.autoSyncInterval,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  AppThemeMode themeMode,  PageDirection pageDirection,  DoublePageMode doublePageMode,  bool crossChapter,  int cacheLimitMB,  int thumbnailConcurrency,  AutoSyncInterval autoSyncInterval,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.id,_that.themeMode,_that.pageDirection,_that.doublePageMode,_that.crossChapter,_that.cacheLimitMB,_that.thumbnailConcurrency,_that.autoSyncInterval,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppConfig implements AppConfig {
  const _AppConfig({this.id = 1, this.themeMode = AppThemeMode.system, this.pageDirection = PageDirection.rightToLeft, this.doublePageMode = DoublePageMode.auto, this.crossChapter = true, this.cacheLimitMB = 500, this.thumbnailConcurrency = 4, this.autoSyncInterval = AutoSyncInterval.off, required this.updatedAt});
  factory _AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  AppThemeMode themeMode;
@override@JsonKey() final  PageDirection pageDirection;
@override@JsonKey() final  DoublePageMode doublePageMode;
@override@JsonKey() final  bool crossChapter;
@override@JsonKey() final  int cacheLimitMB;
@override@JsonKey() final  int thumbnailConcurrency;
@override@JsonKey() final  AutoSyncInterval autoSyncInterval;
@override final  DateTime updatedAt;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.pageDirection, pageDirection) || other.pageDirection == pageDirection)&&(identical(other.doublePageMode, doublePageMode) || other.doublePageMode == doublePageMode)&&(identical(other.crossChapter, crossChapter) || other.crossChapter == crossChapter)&&(identical(other.cacheLimitMB, cacheLimitMB) || other.cacheLimitMB == cacheLimitMB)&&(identical(other.thumbnailConcurrency, thumbnailConcurrency) || other.thumbnailConcurrency == thumbnailConcurrency)&&(identical(other.autoSyncInterval, autoSyncInterval) || other.autoSyncInterval == autoSyncInterval)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,themeMode,pageDirection,doublePageMode,crossChapter,cacheLimitMB,thumbnailConcurrency,autoSyncInterval,updatedAt);

@override
String toString() {
  return 'AppConfig(id: $id, themeMode: $themeMode, pageDirection: $pageDirection, doublePageMode: $doublePageMode, crossChapter: $crossChapter, cacheLimitMB: $cacheLimitMB, thumbnailConcurrency: $thumbnailConcurrency, autoSyncInterval: $autoSyncInterval, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 int id, AppThemeMode themeMode, PageDirection pageDirection, DoublePageMode doublePageMode, bool crossChapter, int cacheLimitMB, int thumbnailConcurrency, AutoSyncInterval autoSyncInterval, DateTime updatedAt
});




}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? themeMode = null,Object? pageDirection = null,Object? doublePageMode = null,Object? crossChapter = null,Object? cacheLimitMB = null,Object? thumbnailConcurrency = null,Object? autoSyncInterval = null,Object? updatedAt = null,}) {
  return _then(_AppConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,pageDirection: null == pageDirection ? _self.pageDirection : pageDirection // ignore: cast_nullable_to_non_nullable
as PageDirection,doublePageMode: null == doublePageMode ? _self.doublePageMode : doublePageMode // ignore: cast_nullable_to_non_nullable
as DoublePageMode,crossChapter: null == crossChapter ? _self.crossChapter : crossChapter // ignore: cast_nullable_to_non_nullable
as bool,cacheLimitMB: null == cacheLimitMB ? _self.cacheLimitMB : cacheLimitMB // ignore: cast_nullable_to_non_nullable
as int,thumbnailConcurrency: null == thumbnailConcurrency ? _self.thumbnailConcurrency : thumbnailConcurrency // ignore: cast_nullable_to_non_nullable
as int,autoSyncInterval: null == autoSyncInterval ? _self.autoSyncInterval : autoSyncInterval // ignore: cast_nullable_to_non_nullable
as AutoSyncInterval,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
