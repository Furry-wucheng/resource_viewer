// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResourceTag {

 String get resourceId; String get tagId; DateTime get createdAt;
/// Create a copy of ResourceTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceTagCopyWith<ResourceTag> get copyWith => _$ResourceTagCopyWithImpl<ResourceTag>(this as ResourceTag, _$identity);

  /// Serializes this ResourceTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceTag&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resourceId,tagId,createdAt);

@override
String toString() {
  return 'ResourceTag(resourceId: $resourceId, tagId: $tagId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ResourceTagCopyWith<$Res>  {
  factory $ResourceTagCopyWith(ResourceTag value, $Res Function(ResourceTag) _then) = _$ResourceTagCopyWithImpl;
@useResult
$Res call({
 String resourceId, String tagId, DateTime createdAt
});




}
/// @nodoc
class _$ResourceTagCopyWithImpl<$Res>
    implements $ResourceTagCopyWith<$Res> {
  _$ResourceTagCopyWithImpl(this._self, this._then);

  final ResourceTag _self;
  final $Res Function(ResourceTag) _then;

/// Create a copy of ResourceTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resourceId = null,Object? tagId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceTag].
extension ResourceTagPatterns on ResourceTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceTag value)  $default,){
final _that = this;
switch (_that) {
case _ResourceTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceTag value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resourceId,  String tagId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceTag() when $default != null:
return $default(_that.resourceId,_that.tagId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resourceId,  String tagId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ResourceTag():
return $default(_that.resourceId,_that.tagId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resourceId,  String tagId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ResourceTag() when $default != null:
return $default(_that.resourceId,_that.tagId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResourceTag implements ResourceTag {
  const _ResourceTag({required this.resourceId, required this.tagId, required this.createdAt});
  factory _ResourceTag.fromJson(Map<String, dynamic> json) => _$ResourceTagFromJson(json);

@override final  String resourceId;
@override final  String tagId;
@override final  DateTime createdAt;

/// Create a copy of ResourceTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceTagCopyWith<_ResourceTag> get copyWith => __$ResourceTagCopyWithImpl<_ResourceTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResourceTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceTag&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,resourceId,tagId,createdAt);

@override
String toString() {
  return 'ResourceTag(resourceId: $resourceId, tagId: $tagId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ResourceTagCopyWith<$Res> implements $ResourceTagCopyWith<$Res> {
  factory _$ResourceTagCopyWith(_ResourceTag value, $Res Function(_ResourceTag) _then) = __$ResourceTagCopyWithImpl;
@override @useResult
$Res call({
 String resourceId, String tagId, DateTime createdAt
});




}
/// @nodoc
class __$ResourceTagCopyWithImpl<$Res>
    implements _$ResourceTagCopyWith<$Res> {
  __$ResourceTagCopyWithImpl(this._self, this._then);

  final _ResourceTag _self;
  final $Res Function(_ResourceTag) _then;

/// Create a copy of ResourceTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resourceId = null,Object? tagId = null,Object? createdAt = null,}) {
  return _then(_ResourceTag(
resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
