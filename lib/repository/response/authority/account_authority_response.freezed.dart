// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_authority_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AccountAuthorityResponse _$AccountAuthorityResponseFromJson(
  Map<String, dynamic> json,
) {
  return _AccountAuthorityResponse.fromJson(json);
}

/// @nodoc
mixin _$AccountAuthorityResponse {
  String get accountNumber =>
      throw _privateConstructorUsedError; // API에서 값이 안 넘어올 경우를 대비해 Default false 처리
  bool get isAuditorAllowed => throw _privateConstructorUsedError;
  bool get isPending =>
      throw _privateConstructorUsedError; // ② 권한 목록: 단순 String이 아닌 Permission 객체의 리스트
  List<Permission> get permissions => throw _privateConstructorUsedError;

  /// Serializes this AccountAuthorityResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountAuthorityResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountAuthorityResponseCopyWith<AccountAuthorityResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountAuthorityResponseCopyWith<$Res> {
  factory $AccountAuthorityResponseCopyWith(
    AccountAuthorityResponse value,
    $Res Function(AccountAuthorityResponse) then,
  ) = _$AccountAuthorityResponseCopyWithImpl<$Res, AccountAuthorityResponse>;
  @useResult
  $Res call({
    String accountNumber,
    bool isAuditorAllowed,
    bool isPending,
    List<Permission> permissions,
  });
}

/// @nodoc
class _$AccountAuthorityResponseCopyWithImpl<
  $Res,
  $Val extends AccountAuthorityResponse
>
    implements $AccountAuthorityResponseCopyWith<$Res> {
  _$AccountAuthorityResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountAuthorityResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountNumber = null,
    Object? isAuditorAllowed = null,
    Object? isPending = null,
    Object? permissions = null,
  }) {
    return _then(
      _value.copyWith(
            accountNumber: null == accountNumber
                ? _value.accountNumber
                : accountNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            isAuditorAllowed: null == isAuditorAllowed
                ? _value.isAuditorAllowed
                : isAuditorAllowed // ignore: cast_nullable_to_non_nullable
                      as bool,
            isPending: null == isPending
                ? _value.isPending
                : isPending // ignore: cast_nullable_to_non_nullable
                      as bool,
            permissions: null == permissions
                ? _value.permissions
                : permissions // ignore: cast_nullable_to_non_nullable
                      as List<Permission>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountAuthorityResponseImplCopyWith<$Res>
    implements $AccountAuthorityResponseCopyWith<$Res> {
  factory _$$AccountAuthorityResponseImplCopyWith(
    _$AccountAuthorityResponseImpl value,
    $Res Function(_$AccountAuthorityResponseImpl) then,
  ) = __$$AccountAuthorityResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accountNumber,
    bool isAuditorAllowed,
    bool isPending,
    List<Permission> permissions,
  });
}

/// @nodoc
class __$$AccountAuthorityResponseImplCopyWithImpl<$Res>
    extends
        _$AccountAuthorityResponseCopyWithImpl<
          $Res,
          _$AccountAuthorityResponseImpl
        >
    implements _$$AccountAuthorityResponseImplCopyWith<$Res> {
  __$$AccountAuthorityResponseImplCopyWithImpl(
    _$AccountAuthorityResponseImpl _value,
    $Res Function(_$AccountAuthorityResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountAuthorityResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountNumber = null,
    Object? isAuditorAllowed = null,
    Object? isPending = null,
    Object? permissions = null,
  }) {
    return _then(
      _$AccountAuthorityResponseImpl(
        accountNumber: null == accountNumber
            ? _value.accountNumber
            : accountNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        isAuditorAllowed: null == isAuditorAllowed
            ? _value.isAuditorAllowed
            : isAuditorAllowed // ignore: cast_nullable_to_non_nullable
                  as bool,
        isPending: null == isPending
            ? _value.isPending
            : isPending // ignore: cast_nullable_to_non_nullable
                  as bool,
        permissions: null == permissions
            ? _value._permissions
            : permissions // ignore: cast_nullable_to_non_nullable
                  as List<Permission>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountAuthorityResponseImpl implements _AccountAuthorityResponse {
  const _$AccountAuthorityResponseImpl({
    required this.accountNumber,
    this.isAuditorAllowed = false,
    this.isPending = false,
    final List<Permission> permissions = const [],
  }) : _permissions = permissions;

  factory _$AccountAuthorityResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountAuthorityResponseImplFromJson(json);

  @override
  final String accountNumber;
  // API에서 값이 안 넘어올 경우를 대비해 Default false 처리
  @override
  @JsonKey()
  final bool isAuditorAllowed;
  @override
  @JsonKey()
  final bool isPending;
  // ② 권한 목록: 단순 String이 아닌 Permission 객체의 리스트
  final List<Permission> _permissions;
  // ② 권한 목록: 단순 String이 아닌 Permission 객체의 리스트
  @override
  @JsonKey()
  List<Permission> get permissions {
    if (_permissions is EqualUnmodifiableListView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_permissions);
  }

  @override
  String toString() {
    return 'AccountAuthorityResponse(accountNumber: $accountNumber, isAuditorAllowed: $isAuditorAllowed, isPending: $isPending, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountAuthorityResponseImpl &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.isAuditorAllowed, isAuditorAllowed) ||
                other.isAuditorAllowed == isAuditorAllowed) &&
            (identical(other.isPending, isPending) ||
                other.isPending == isPending) &&
            const DeepCollectionEquality().equals(
              other._permissions,
              _permissions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accountNumber,
    isAuditorAllowed,
    isPending,
    const DeepCollectionEquality().hash(_permissions),
  );

  /// Create a copy of AccountAuthorityResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountAuthorityResponseImplCopyWith<_$AccountAuthorityResponseImpl>
  get copyWith =>
      __$$AccountAuthorityResponseImplCopyWithImpl<
        _$AccountAuthorityResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountAuthorityResponseImplToJson(this);
  }
}

abstract class _AccountAuthorityResponse implements AccountAuthorityResponse {
  const factory _AccountAuthorityResponse({
    required final String accountNumber,
    final bool isAuditorAllowed,
    final bool isPending,
    final List<Permission> permissions,
  }) = _$AccountAuthorityResponseImpl;

  factory _AccountAuthorityResponse.fromJson(Map<String, dynamic> json) =
      _$AccountAuthorityResponseImpl.fromJson;

  @override
  String get accountNumber; // API에서 값이 안 넘어올 경우를 대비해 Default false 처리
  @override
  bool get isAuditorAllowed;
  @override
  bool get isPending; // ② 권한 목록: 단순 String이 아닌 Permission 객체의 리스트
  @override
  List<Permission> get permissions;

  /// Create a copy of AccountAuthorityResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountAuthorityResponseImplCopyWith<_$AccountAuthorityResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

Permission _$PermissionFromJson(Map<String, dynamic> json) {
  return _Permission.fromJson(json);
}

/// @nodoc
mixin _$Permission {
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError; // "ALL", "VIEW" 등.
  // 만약 고정된 값만 온다면 enum으로 처리할 수도 있지만,
  // 서버 변경 대응을 위해 String으로 받는 것이 안전합니다.
  String get type => throw _privateConstructorUsedError;

  /// Serializes this Permission to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Permission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PermissionCopyWith<Permission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PermissionCopyWith<$Res> {
  factory $PermissionCopyWith(
    Permission value,
    $Res Function(Permission) then,
  ) = _$PermissionCopyWithImpl<$Res, Permission>;
  @useResult
  $Res call({String userId, String userName, String type});
}

/// @nodoc
class _$PermissionCopyWithImpl<$Res, $Val extends Permission>
    implements $PermissionCopyWith<$Res> {
  _$PermissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Permission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PermissionImplCopyWith<$Res>
    implements $PermissionCopyWith<$Res> {
  factory _$$PermissionImplCopyWith(
    _$PermissionImpl value,
    $Res Function(_$PermissionImpl) then,
  ) = __$$PermissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String userName, String type});
}

/// @nodoc
class __$$PermissionImplCopyWithImpl<$Res>
    extends _$PermissionCopyWithImpl<$Res, _$PermissionImpl>
    implements _$$PermissionImplCopyWith<$Res> {
  __$$PermissionImplCopyWithImpl(
    _$PermissionImpl _value,
    $Res Function(_$PermissionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Permission
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? type = null,
  }) {
    return _then(
      _$PermissionImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PermissionImpl implements _Permission {
  const _$PermissionImpl({
    required this.userId,
    required this.userName,
    required this.type,
  });

  factory _$PermissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PermissionImplFromJson(json);

  @override
  final String userId;
  @override
  final String userName;
  // "ALL", "VIEW" 등.
  // 만약 고정된 값만 온다면 enum으로 처리할 수도 있지만,
  // 서버 변경 대응을 위해 String으로 받는 것이 안전합니다.
  @override
  final String type;

  @override
  String toString() {
    return 'Permission(userId: $userId, userName: $userName, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, userName, type);

  /// Create a copy of Permission
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionImplCopyWith<_$PermissionImpl> get copyWith =>
      __$$PermissionImplCopyWithImpl<_$PermissionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PermissionImplToJson(this);
  }
}

abstract class _Permission implements Permission {
  const factory _Permission({
    required final String userId,
    required final String userName,
    required final String type,
  }) = _$PermissionImpl;

  factory _Permission.fromJson(Map<String, dynamic> json) =
      _$PermissionImpl.fromJson;

  @override
  String get userId;
  @override
  String get userName; // "ALL", "VIEW" 등.
  // 만약 고정된 값만 온다면 enum으로 처리할 수도 있지만,
  // 서버 변경 대응을 위해 String으로 받는 것이 안전합니다.
  @override
  String get type;

  /// Create a copy of Permission
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionImplCopyWith<_$PermissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
