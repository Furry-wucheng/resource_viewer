// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileEntry {

 String get name; String get path; bool get isDirectory; BigInt? get size; DateTime? get modifiedAt;
/// Create a copy of FileEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileEntryCopyWith<FileEntry> get copyWith => _$FileEntryCopyWithImpl<FileEntry>(this as FileEntry, _$identity);

  /// Serializes this FileEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,isDirectory,size,modifiedAt);

@override
String toString() {
  return 'FileEntry(name: $name, path: $path, isDirectory: $isDirectory, size: $size, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class $FileEntryCopyWith<$Res>  {
  factory $FileEntryCopyWith(FileEntry value, $Res Function(FileEntry) _then) = _$FileEntryCopyWithImpl;
@useResult
$Res call({
 String name, String path, bool isDirectory, BigInt? size, DateTime? modifiedAt
});




}
/// @nodoc
class _$FileEntryCopyWithImpl<$Res>
    implements $FileEntryCopyWith<$Res> {
  _$FileEntryCopyWithImpl(this._self, this._then);

  final FileEntry _self;
  final $Res Function(FileEntry) _then;

/// Create a copy of FileEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? size = freezed,Object? modifiedAt = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as BigInt?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileEntry].
extension FileEntryPatterns on FileEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileEntry value)  $default,){
final _that = this;
switch (_that) {
case _FileEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FileEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  BigInt? size,  DateTime? modifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  BigInt? size,  DateTime? modifiedAt)  $default,) {final _that = this;
switch (_that) {
case _FileEntry():
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  bool isDirectory,  BigInt? size,  DateTime? modifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _FileEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.size,_that.modifiedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileEntry implements FileEntry {
  const _FileEntry({required this.name, required this.path, required this.isDirectory, this.size, this.modifiedAt});
  factory _FileEntry.fromJson(Map<String, dynamic> json) => _$FileEntryFromJson(json);

@override final  String name;
@override final  String path;
@override final  bool isDirectory;
@override final  BigInt? size;
@override final  DateTime? modifiedAt;

/// Create a copy of FileEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileEntryCopyWith<_FileEntry> get copyWith => __$FileEntryCopyWithImpl<_FileEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,isDirectory,size,modifiedAt);

@override
String toString() {
  return 'FileEntry(name: $name, path: $path, isDirectory: $isDirectory, size: $size, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class _$FileEntryCopyWith<$Res> implements $FileEntryCopyWith<$Res> {
  factory _$FileEntryCopyWith(_FileEntry value, $Res Function(_FileEntry) _then) = __$FileEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, bool isDirectory, BigInt? size, DateTime? modifiedAt
});




}
/// @nodoc
class __$FileEntryCopyWithImpl<$Res>
    implements _$FileEntryCopyWith<$Res> {
  __$FileEntryCopyWithImpl(this._self, this._then);

  final _FileEntry _self;
  final $Res Function(_FileEntry) _then;

/// Create a copy of FileEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? size = freezed,Object? modifiedAt = freezed,}) {
  return _then(_FileEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as BigInt?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
