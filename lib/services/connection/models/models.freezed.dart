// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CSRFTokenResponse {

 String get token;
/// Create a copy of CSRFTokenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CSRFTokenResponseCopyWith<CSRFTokenResponse> get copyWith => _$CSRFTokenResponseCopyWithImpl<CSRFTokenResponse>(this as CSRFTokenResponse, _$identity);

  /// Serializes this CSRFTokenResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CSRFTokenResponse&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'CSRFTokenResponse(token: $token)';
}


}

/// @nodoc
abstract mixin class $CSRFTokenResponseCopyWith<$Res>  {
  factory $CSRFTokenResponseCopyWith(CSRFTokenResponse value, $Res Function(CSRFTokenResponse) _then) = _$CSRFTokenResponseCopyWithImpl;
@useResult
$Res call({
 String token
});




}
/// @nodoc
class _$CSRFTokenResponseCopyWithImpl<$Res>
    implements $CSRFTokenResponseCopyWith<$Res> {
  _$CSRFTokenResponseCopyWithImpl(this._self, this._then);

  final CSRFTokenResponse _self;
  final $Res Function(CSRFTokenResponse) _then;

/// Create a copy of CSRFTokenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CSRFTokenResponse].
extension CSRFTokenResponsePatterns on CSRFTokenResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CSRFTokenResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CSRFTokenResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CSRFTokenResponse value)  $default,){
final _that = this;
switch (_that) {
case _CSRFTokenResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CSRFTokenResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CSRFTokenResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CSRFTokenResponse() when $default != null:
return $default(_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token)  $default,) {final _that = this;
switch (_that) {
case _CSRFTokenResponse():
return $default(_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token)?  $default,) {final _that = this;
switch (_that) {
case _CSRFTokenResponse() when $default != null:
return $default(_that.token);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CSRFTokenResponse implements CSRFTokenResponse {
  const _CSRFTokenResponse({required this.token});
  factory _CSRFTokenResponse.fromJson(Map<String, dynamic> json) => _$CSRFTokenResponseFromJson(json);

@override final  String token;

/// Create a copy of CSRFTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CSRFTokenResponseCopyWith<_CSRFTokenResponse> get copyWith => __$CSRFTokenResponseCopyWithImpl<_CSRFTokenResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CSRFTokenResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CSRFTokenResponse&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'CSRFTokenResponse(token: $token)';
}


}

/// @nodoc
abstract mixin class _$CSRFTokenResponseCopyWith<$Res> implements $CSRFTokenResponseCopyWith<$Res> {
  factory _$CSRFTokenResponseCopyWith(_CSRFTokenResponse value, $Res Function(_CSRFTokenResponse) _then) = __$CSRFTokenResponseCopyWithImpl;
@override @useResult
$Res call({
 String token
});




}
/// @nodoc
class __$CSRFTokenResponseCopyWithImpl<$Res>
    implements _$CSRFTokenResponseCopyWith<$Res> {
  __$CSRFTokenResponseCopyWithImpl(this._self, this._then);

  final _CSRFTokenResponse _self;
  final $Res Function(_CSRFTokenResponse) _then;

/// Create a copy of CSRFTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,}) {
  return _then(_CSRFTokenResponse(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ConnectionCredentials {

 String get handle; String get password;
/// Create a copy of ConnectionCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionCredentialsCopyWith<ConnectionCredentials> get copyWith => _$ConnectionCredentialsCopyWithImpl<ConnectionCredentials>(this as ConnectionCredentials, _$identity);

  /// Serializes this ConnectionCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionCredentials&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,handle,password);

@override
String toString() {
  return 'ConnectionCredentials(handle: $handle, password: $password)';
}


}

/// @nodoc
abstract mixin class $ConnectionCredentialsCopyWith<$Res>  {
  factory $ConnectionCredentialsCopyWith(ConnectionCredentials value, $Res Function(ConnectionCredentials) _then) = _$ConnectionCredentialsCopyWithImpl;
@useResult
$Res call({
 String handle, String password
});




}
/// @nodoc
class _$ConnectionCredentialsCopyWithImpl<$Res>
    implements $ConnectionCredentialsCopyWith<$Res> {
  _$ConnectionCredentialsCopyWithImpl(this._self, this._then);

  final ConnectionCredentials _self;
  final $Res Function(ConnectionCredentials) _then;

/// Create a copy of ConnectionCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handle = null,Object? password = null,}) {
  return _then(_self.copyWith(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectionCredentials].
extension ConnectionCredentialsPatterns on ConnectionCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectionCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectionCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectionCredentials value)  $default,){
final _that = this;
switch (_that) {
case _ConnectionCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectionCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectionCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String handle,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectionCredentials() when $default != null:
return $default(_that.handle,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String handle,  String password)  $default,) {final _that = this;
switch (_that) {
case _ConnectionCredentials():
return $default(_that.handle,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String handle,  String password)?  $default,) {final _that = this;
switch (_that) {
case _ConnectionCredentials() when $default != null:
return $default(_that.handle,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConnectionCredentials implements ConnectionCredentials {
  const _ConnectionCredentials({required this.handle, required this.password});
  factory _ConnectionCredentials.fromJson(Map<String, dynamic> json) => _$ConnectionCredentialsFromJson(json);

@override final  String handle;
@override final  String password;

/// Create a copy of ConnectionCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionCredentialsCopyWith<_ConnectionCredentials> get copyWith => __$ConnectionCredentialsCopyWithImpl<_ConnectionCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConnectionCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectionCredentials&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,handle,password);

@override
String toString() {
  return 'ConnectionCredentials(handle: $handle, password: $password)';
}


}

/// @nodoc
abstract mixin class _$ConnectionCredentialsCopyWith<$Res> implements $ConnectionCredentialsCopyWith<$Res> {
  factory _$ConnectionCredentialsCopyWith(_ConnectionCredentials value, $Res Function(_ConnectionCredentials) _then) = __$ConnectionCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String handle, String password
});




}
/// @nodoc
class __$ConnectionCredentialsCopyWithImpl<$Res>
    implements _$ConnectionCredentialsCopyWith<$Res> {
  __$ConnectionCredentialsCopyWithImpl(this._self, this._then);

  final _ConnectionCredentials _self;
  final $Res Function(_ConnectionCredentials) _then;

/// Create a copy of ConnectionCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handle = null,Object? password = null,}) {
  return _then(_ConnectionCredentials(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
