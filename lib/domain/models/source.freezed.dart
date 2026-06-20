// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Source {

 String get id; String get name; SourceType get type; String get rootPath; String? get host; int? get port; String? get username; bool get passwordStored; String? get domain; bool get enabled; bool get isAvailable; DateTime? get lastCheckAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceCopyWith<Source> get copyWith => _$SourceCopyWithImpl<Source>(this as Source, _$identity);

  /// Serializes this Source to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Source&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.passwordStored, passwordStored) || other.passwordStored == passwordStored)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.lastCheckAt, lastCheckAt) || other.lastCheckAt == lastCheckAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,rootPath,host,port,username,passwordStored,domain,enabled,isAvailable,lastCheckAt,createdAt,updatedAt);

@override
String toString() {
  return 'Source(id: $id, name: $name, type: $type, rootPath: $rootPath, host: $host, port: $port, username: $username, passwordStored: $passwordStored, domain: $domain, enabled: $enabled, isAvailable: $isAvailable, lastCheckAt: $lastCheckAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SourceCopyWith<$Res>  {
  factory $SourceCopyWith(Source value, $Res Function(Source) _then) = _$SourceCopyWithImpl;
@useResult
$Res call({
 String id, String name, SourceType type, String rootPath, String? host, int? port, String? username, bool passwordStored, String? domain, bool enabled, bool isAvailable, DateTime? lastCheckAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SourceCopyWithImpl<$Res>
    implements $SourceCopyWith<$Res> {
  _$SourceCopyWithImpl(this._self, this._then);

  final Source _self;
  final $Res Function(Source) _then;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? rootPath = null,Object? host = freezed,Object? port = freezed,Object? username = freezed,Object? passwordStored = null,Object? domain = freezed,Object? enabled = null,Object? isAvailable = null,Object? lastCheckAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,passwordStored: null == passwordStored ? _self.passwordStored : passwordStored // ignore: cast_nullable_to_non_nullable
as bool,domain: freezed == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,lastCheckAt: freezed == lastCheckAt ? _self.lastCheckAt : lastCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Source].
extension SourcePatterns on Source {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Source value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Source() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Source value)  $default,){
final _that = this;
switch (_that) {
case _Source():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Source value)?  $default,){
final _that = this;
switch (_that) {
case _Source() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  SourceType type,  String rootPath,  String? host,  int? port,  String? username,  bool passwordStored,  String? domain,  bool enabled,  bool isAvailable,  DateTime? lastCheckAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Source() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.rootPath,_that.host,_that.port,_that.username,_that.passwordStored,_that.domain,_that.enabled,_that.isAvailable,_that.lastCheckAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  SourceType type,  String rootPath,  String? host,  int? port,  String? username,  bool passwordStored,  String? domain,  bool enabled,  bool isAvailable,  DateTime? lastCheckAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Source():
return $default(_that.id,_that.name,_that.type,_that.rootPath,_that.host,_that.port,_that.username,_that.passwordStored,_that.domain,_that.enabled,_that.isAvailable,_that.lastCheckAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  SourceType type,  String rootPath,  String? host,  int? port,  String? username,  bool passwordStored,  String? domain,  bool enabled,  bool isAvailable,  DateTime? lastCheckAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Source() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.rootPath,_that.host,_that.port,_that.username,_that.passwordStored,_that.domain,_that.enabled,_that.isAvailable,_that.lastCheckAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Source implements Source {
  const _Source({required this.id, required this.name, required this.type, required this.rootPath, this.host, this.port, this.username, this.passwordStored = false, this.domain, this.enabled = true, this.isAvailable = false, this.lastCheckAt, required this.createdAt, required this.updatedAt});
  factory _Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);

@override final  String id;
@override final  String name;
@override final  SourceType type;
@override final  String rootPath;
@override final  String? host;
@override final  int? port;
@override final  String? username;
@override@JsonKey() final  bool passwordStored;
@override final  String? domain;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool isAvailable;
@override final  DateTime? lastCheckAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceCopyWith<_Source> get copyWith => __$SourceCopyWithImpl<_Source>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Source&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.username, username) || other.username == username)&&(identical(other.passwordStored, passwordStored) || other.passwordStored == passwordStored)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.lastCheckAt, lastCheckAt) || other.lastCheckAt == lastCheckAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,rootPath,host,port,username,passwordStored,domain,enabled,isAvailable,lastCheckAt,createdAt,updatedAt);

@override
String toString() {
  return 'Source(id: $id, name: $name, type: $type, rootPath: $rootPath, host: $host, port: $port, username: $username, passwordStored: $passwordStored, domain: $domain, enabled: $enabled, isAvailable: $isAvailable, lastCheckAt: $lastCheckAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SourceCopyWith<$Res> implements $SourceCopyWith<$Res> {
  factory _$SourceCopyWith(_Source value, $Res Function(_Source) _then) = __$SourceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, SourceType type, String rootPath, String? host, int? port, String? username, bool passwordStored, String? domain, bool enabled, bool isAvailable, DateTime? lastCheckAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SourceCopyWithImpl<$Res>
    implements _$SourceCopyWith<$Res> {
  __$SourceCopyWithImpl(this._self, this._then);

  final _Source _self;
  final $Res Function(_Source) _then;

/// Create a copy of Source
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? rootPath = null,Object? host = freezed,Object? port = freezed,Object? username = freezed,Object? passwordStored = null,Object? domain = freezed,Object? enabled = null,Object? isAvailable = null,Object? lastCheckAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Source(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,rootPath: null == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,port: freezed == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,passwordStored: null == passwordStored ? _self.passwordStored : passwordStored // ignore: cast_nullable_to_non_nullable
as bool,domain: freezed == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,lastCheckAt: freezed == lastCheckAt ? _self.lastCheckAt : lastCheckAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
