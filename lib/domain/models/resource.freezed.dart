// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Resource {

 String get id; String get sourceId; String get name; ResourceType get type; OrganizationMode? get organizationMode; String get relativePath; String? get thumbnailPath; int? get fileCount; BigInt? get fileSize; bool get isAvailable; DateTime? get lastScannedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Resource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceCopyWith<Resource> get copyWith => _$ResourceCopyWithImpl<Resource>(this as Resource, _$identity);

  /// Serializes this Resource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Resource&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.organizationMode, organizationMode) || other.organizationMode == organizationMode)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceId,name,type,organizationMode,relativePath,thumbnailPath,fileCount,fileSize,isAvailable,lastScannedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Resource(id: $id, sourceId: $sourceId, name: $name, type: $type, organizationMode: $organizationMode, relativePath: $relativePath, thumbnailPath: $thumbnailPath, fileCount: $fileCount, fileSize: $fileSize, isAvailable: $isAvailable, lastScannedAt: $lastScannedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ResourceCopyWith<$Res>  {
  factory $ResourceCopyWith(Resource value, $Res Function(Resource) _then) = _$ResourceCopyWithImpl;
@useResult
$Res call({
 String id, String sourceId, String name, ResourceType type, OrganizationMode? organizationMode, String relativePath, String? thumbnailPath, int? fileCount, BigInt? fileSize, bool isAvailable, DateTime? lastScannedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ResourceCopyWithImpl<$Res>
    implements $ResourceCopyWith<$Res> {
  _$ResourceCopyWithImpl(this._self, this._then);

  final Resource _self;
  final $Res Function(Resource) _then;

/// Create a copy of Resource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceId = null,Object? name = null,Object? type = null,Object? organizationMode = freezed,Object? relativePath = null,Object? thumbnailPath = freezed,Object? fileCount = freezed,Object? fileSize = freezed,Object? isAvailable = null,Object? lastScannedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResourceType,organizationMode: freezed == organizationMode ? _self.organizationMode : organizationMode // ignore: cast_nullable_to_non_nullable
as OrganizationMode?,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,fileCount: freezed == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as BigInt?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Resource].
extension ResourcePatterns on Resource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Resource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Resource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Resource value)  $default,){
final _that = this;
switch (_that) {
case _Resource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Resource value)?  $default,){
final _that = this;
switch (_that) {
case _Resource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourceId,  String name,  ResourceType type,  OrganizationMode? organizationMode,  String relativePath,  String? thumbnailPath,  int? fileCount,  BigInt? fileSize,  bool isAvailable,  DateTime? lastScannedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Resource() when $default != null:
return $default(_that.id,_that.sourceId,_that.name,_that.type,_that.organizationMode,_that.relativePath,_that.thumbnailPath,_that.fileCount,_that.fileSize,_that.isAvailable,_that.lastScannedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourceId,  String name,  ResourceType type,  OrganizationMode? organizationMode,  String relativePath,  String? thumbnailPath,  int? fileCount,  BigInt? fileSize,  bool isAvailable,  DateTime? lastScannedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Resource():
return $default(_that.id,_that.sourceId,_that.name,_that.type,_that.organizationMode,_that.relativePath,_that.thumbnailPath,_that.fileCount,_that.fileSize,_that.isAvailable,_that.lastScannedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourceId,  String name,  ResourceType type,  OrganizationMode? organizationMode,  String relativePath,  String? thumbnailPath,  int? fileCount,  BigInt? fileSize,  bool isAvailable,  DateTime? lastScannedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Resource() when $default != null:
return $default(_that.id,_that.sourceId,_that.name,_that.type,_that.organizationMode,_that.relativePath,_that.thumbnailPath,_that.fileCount,_that.fileSize,_that.isAvailable,_that.lastScannedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Resource implements Resource {
  const _Resource({required this.id, required this.sourceId, required this.name, required this.type, this.organizationMode, required this.relativePath, this.thumbnailPath, this.fileCount, this.fileSize, this.isAvailable = true, this.lastScannedAt, required this.createdAt, required this.updatedAt});
  factory _Resource.fromJson(Map<String, dynamic> json) => _$ResourceFromJson(json);

@override final  String id;
@override final  String sourceId;
@override final  String name;
@override final  ResourceType type;
@override final  OrganizationMode? organizationMode;
@override final  String relativePath;
@override final  String? thumbnailPath;
@override final  int? fileCount;
@override final  BigInt? fileSize;
@override@JsonKey() final  bool isAvailable;
@override final  DateTime? lastScannedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Resource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceCopyWith<_Resource> get copyWith => __$ResourceCopyWithImpl<_Resource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Resource&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.organizationMode, organizationMode) || other.organizationMode == organizationMode)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.lastScannedAt, lastScannedAt) || other.lastScannedAt == lastScannedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourceId,name,type,organizationMode,relativePath,thumbnailPath,fileCount,fileSize,isAvailable,lastScannedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Resource(id: $id, sourceId: $sourceId, name: $name, type: $type, organizationMode: $organizationMode, relativePath: $relativePath, thumbnailPath: $thumbnailPath, fileCount: $fileCount, fileSize: $fileSize, isAvailable: $isAvailable, lastScannedAt: $lastScannedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ResourceCopyWith<$Res> implements $ResourceCopyWith<$Res> {
  factory _$ResourceCopyWith(_Resource value, $Res Function(_Resource) _then) = __$ResourceCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourceId, String name, ResourceType type, OrganizationMode? organizationMode, String relativePath, String? thumbnailPath, int? fileCount, BigInt? fileSize, bool isAvailable, DateTime? lastScannedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ResourceCopyWithImpl<$Res>
    implements _$ResourceCopyWith<$Res> {
  __$ResourceCopyWithImpl(this._self, this._then);

  final _Resource _self;
  final $Res Function(_Resource) _then;

/// Create a copy of Resource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceId = null,Object? name = null,Object? type = null,Object? organizationMode = freezed,Object? relativePath = null,Object? thumbnailPath = freezed,Object? fileCount = freezed,Object? fileSize = freezed,Object? isAvailable = null,Object? lastScannedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Resource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ResourceType,organizationMode: freezed == organizationMode ? _self.organizationMode : organizationMode // ignore: cast_nullable_to_non_nullable
as OrganizationMode?,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,fileCount: freezed == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as BigInt?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,lastScannedAt: freezed == lastScannedAt ? _self.lastScannedAt : lastScannedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
