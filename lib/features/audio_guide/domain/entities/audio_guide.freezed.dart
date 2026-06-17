// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_guide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AudioGuide {

 int get id; String get title; String get url; String get modified; bool get isDownloaded; int? get matchedAttractionId; String? get summary; String? get fileExt; String? get localFilePath;
/// Create a copy of AudioGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioGuideCopyWith<AudioGuide> get copyWith => _$AudioGuideCopyWithImpl<AudioGuide>(this as AudioGuide, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded)&&(identical(other.matchedAttractionId, matchedAttractionId) || other.matchedAttractionId == matchedAttractionId)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.fileExt, fileExt) || other.fileExt == fileExt)&&(identical(other.localFilePath, localFilePath) || other.localFilePath == localFilePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,url,modified,isDownloaded,matchedAttractionId,summary,fileExt,localFilePath);

@override
String toString() {
  return 'AudioGuide(id: $id, title: $title, url: $url, modified: $modified, isDownloaded: $isDownloaded, matchedAttractionId: $matchedAttractionId, summary: $summary, fileExt: $fileExt, localFilePath: $localFilePath)';
}


}

/// @nodoc
abstract mixin class $AudioGuideCopyWith<$Res>  {
  factory $AudioGuideCopyWith(AudioGuide value, $Res Function(AudioGuide) _then) = _$AudioGuideCopyWithImpl;
@useResult
$Res call({
 int id, String title, String url, String modified, bool isDownloaded, int? matchedAttractionId, String? summary, String? fileExt, String? localFilePath
});




}
/// @nodoc
class _$AudioGuideCopyWithImpl<$Res>
    implements $AudioGuideCopyWith<$Res> {
  _$AudioGuideCopyWithImpl(this._self, this._then);

  final AudioGuide _self;
  final $Res Function(AudioGuide) _then;

/// Create a copy of AudioGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? url = null,Object? modified = null,Object? isDownloaded = null,Object? matchedAttractionId = freezed,Object? summary = freezed,Object? fileExt = freezed,Object? localFilePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,matchedAttractionId: freezed == matchedAttractionId ? _self.matchedAttractionId : matchedAttractionId // ignore: cast_nullable_to_non_nullable
as int?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,fileExt: freezed == fileExt ? _self.fileExt : fileExt // ignore: cast_nullable_to_non_nullable
as String?,localFilePath: freezed == localFilePath ? _self.localFilePath : localFilePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioGuide].
extension AudioGuidePatterns on AudioGuide {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioGuide() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioGuide value)  $default,){
final _that = this;
switch (_that) {
case _AudioGuide():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioGuide value)?  $default,){
final _that = this;
switch (_that) {
case _AudioGuide() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String url,  String modified,  bool isDownloaded,  int? matchedAttractionId,  String? summary,  String? fileExt,  String? localFilePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioGuide() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.modified,_that.isDownloaded,_that.matchedAttractionId,_that.summary,_that.fileExt,_that.localFilePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String url,  String modified,  bool isDownloaded,  int? matchedAttractionId,  String? summary,  String? fileExt,  String? localFilePath)  $default,) {final _that = this;
switch (_that) {
case _AudioGuide():
return $default(_that.id,_that.title,_that.url,_that.modified,_that.isDownloaded,_that.matchedAttractionId,_that.summary,_that.fileExt,_that.localFilePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String url,  String modified,  bool isDownloaded,  int? matchedAttractionId,  String? summary,  String? fileExt,  String? localFilePath)?  $default,) {final _that = this;
switch (_that) {
case _AudioGuide() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.modified,_that.isDownloaded,_that.matchedAttractionId,_that.summary,_that.fileExt,_that.localFilePath);case _:
  return null;

}
}

}

/// @nodoc


class _AudioGuide implements AudioGuide {
  const _AudioGuide({required this.id, required this.title, required this.url, required this.modified, required this.isDownloaded, this.matchedAttractionId, this.summary, this.fileExt, this.localFilePath});
  

@override final  int id;
@override final  String title;
@override final  String url;
@override final  String modified;
@override final  bool isDownloaded;
@override final  int? matchedAttractionId;
@override final  String? summary;
@override final  String? fileExt;
@override final  String? localFilePath;

/// Create a copy of AudioGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioGuideCopyWith<_AudioGuide> get copyWith => __$AudioGuideCopyWithImpl<_AudioGuide>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded)&&(identical(other.matchedAttractionId, matchedAttractionId) || other.matchedAttractionId == matchedAttractionId)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.fileExt, fileExt) || other.fileExt == fileExt)&&(identical(other.localFilePath, localFilePath) || other.localFilePath == localFilePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,url,modified,isDownloaded,matchedAttractionId,summary,fileExt,localFilePath);

@override
String toString() {
  return 'AudioGuide(id: $id, title: $title, url: $url, modified: $modified, isDownloaded: $isDownloaded, matchedAttractionId: $matchedAttractionId, summary: $summary, fileExt: $fileExt, localFilePath: $localFilePath)';
}


}

/// @nodoc
abstract mixin class _$AudioGuideCopyWith<$Res> implements $AudioGuideCopyWith<$Res> {
  factory _$AudioGuideCopyWith(_AudioGuide value, $Res Function(_AudioGuide) _then) = __$AudioGuideCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String url, String modified, bool isDownloaded, int? matchedAttractionId, String? summary, String? fileExt, String? localFilePath
});




}
/// @nodoc
class __$AudioGuideCopyWithImpl<$Res>
    implements _$AudioGuideCopyWith<$Res> {
  __$AudioGuideCopyWithImpl(this._self, this._then);

  final _AudioGuide _self;
  final $Res Function(_AudioGuide) _then;

/// Create a copy of AudioGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? url = null,Object? modified = null,Object? isDownloaded = null,Object? matchedAttractionId = freezed,Object? summary = freezed,Object? fileExt = freezed,Object? localFilePath = freezed,}) {
  return _then(_AudioGuide(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,matchedAttractionId: freezed == matchedAttractionId ? _self.matchedAttractionId : matchedAttractionId // ignore: cast_nullable_to_non_nullable
as int?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,fileExt: freezed == fileExt ? _self.fileExt : fileExt // ignore: cast_nullable_to_non_nullable
as String?,localFilePath: freezed == localFilePath ? _self.localFilePath : localFilePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
