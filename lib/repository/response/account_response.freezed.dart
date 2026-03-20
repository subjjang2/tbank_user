// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AccountResponse _$AccountResponseFromJson(Map<String, dynamic> json) {
  return _AccountResponse.fromJson(json);
}

/// @nodoc
mixin _$AccountResponse {
  // summary가 null이면 빈 객체(empty)를 반환하도록 _parseSummary 연결
  @JsonKey(name: 'summary', fromJson: _parseSummary)
  AccountSummary get summary => throw _privateConstructorUsedError; // list가 null이면 빈 리스트 반환
  List<Account> get list => throw _privateConstructorUsedError;

  /// Serializes this AccountResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountResponseCopyWith<AccountResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountResponseCopyWith<$Res> {
  factory $AccountResponseCopyWith(
    AccountResponse value,
    $Res Function(AccountResponse) then,
  ) = _$AccountResponseCopyWithImpl<$Res, AccountResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'summary', fromJson: _parseSummary) AccountSummary summary,
    List<Account> list,
  });

  $AccountSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class _$AccountResponseCopyWithImpl<$Res, $Val extends AccountResponse>
    implements $AccountResponseCopyWith<$Res> {
  _$AccountResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summary = null, Object? list = null}) {
    return _then(
      _value.copyWith(
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as AccountSummary,
            list: null == list
                ? _value.list
                : list // ignore: cast_nullable_to_non_nullable
                      as List<Account>,
          )
          as $Val,
    );
  }

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountSummaryCopyWith<$Res> get summary {
    return $AccountSummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AccountResponseImplCopyWith<$Res>
    implements $AccountResponseCopyWith<$Res> {
  factory _$$AccountResponseImplCopyWith(
    _$AccountResponseImpl value,
    $Res Function(_$AccountResponseImpl) then,
  ) = __$$AccountResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'summary', fromJson: _parseSummary) AccountSummary summary,
    List<Account> list,
  });

  @override
  $AccountSummaryCopyWith<$Res> get summary;
}

/// @nodoc
class __$$AccountResponseImplCopyWithImpl<$Res>
    extends _$AccountResponseCopyWithImpl<$Res, _$AccountResponseImpl>
    implements _$$AccountResponseImplCopyWith<$Res> {
  __$$AccountResponseImplCopyWithImpl(
    _$AccountResponseImpl _value,
    $Res Function(_$AccountResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summary = null, Object? list = null}) {
    return _then(
      _$AccountResponseImpl(
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as AccountSummary,
        list: null == list
            ? _value._list
            : list // ignore: cast_nullable_to_non_nullable
                  as List<Account>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountResponseImpl implements _AccountResponse {
  const _$AccountResponseImpl({
    @JsonKey(name: 'summary', fromJson: _parseSummary) required this.summary,
    final List<Account> list = const [],
  }) : _list = list;

  factory _$AccountResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountResponseImplFromJson(json);

  // summary가 null이면 빈 객체(empty)를 반환하도록 _parseSummary 연결
  @override
  @JsonKey(name: 'summary', fromJson: _parseSummary)
  final AccountSummary summary;
  // list가 null이면 빈 리스트 반환
  final List<Account> _list;
  // list가 null이면 빈 리스트 반환
  @override
  @JsonKey()
  List<Account> get list {
    if (_list is EqualUnmodifiableListView) return _list;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_list);
  }

  @override
  String toString() {
    return 'AccountResponse(summary: $summary, list: $list)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountResponseImpl &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(other._list, _list));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    summary,
    const DeepCollectionEquality().hash(_list),
  );

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountResponseImplCopyWith<_$AccountResponseImpl> get copyWith =>
      __$$AccountResponseImplCopyWithImpl<_$AccountResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountResponseImplToJson(this);
  }
}

abstract class _AccountResponse implements AccountResponse {
  const factory _AccountResponse({
    @JsonKey(name: 'summary', fromJson: _parseSummary)
    required final AccountSummary summary,
    final List<Account> list,
  }) = _$AccountResponseImpl;

  factory _AccountResponse.fromJson(Map<String, dynamic> json) =
      _$AccountResponseImpl.fromJson;

  // summary가 null이면 빈 객체(empty)를 반환하도록 _parseSummary 연결
  @override
  @JsonKey(name: 'summary', fromJson: _parseSummary)
  AccountSummary get summary; // list가 null이면 빈 리스트 반환
  @override
  List<Account> get list;

  /// Create a copy of AccountResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountResponseImplCopyWith<_$AccountResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccountSummary _$AccountSummaryFromJson(Map<String, dynamic> json) {
  return _AccountSummary.fromJson(json);
}

/// @nodoc
mixin _$AccountSummary {
  // 값이 없거나 숫자여도 안전하게 String으로 변환
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  String get totalBalance => throw _privateConstructorUsedError; // 값이 없거나 문자열이어도 안전하게 int로 변환
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  int get totalCount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  int get totalPage => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  int get currentPage => throw _privateConstructorUsedError;

  /// Serializes this AccountSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountSummaryCopyWith<AccountSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountSummaryCopyWith<$Res> {
  factory $AccountSummaryCopyWith(
    AccountSummary value,
    $Res Function(AccountSummary) then,
  ) = _$AccountSummaryCopyWithImpl<$Res, AccountSummary>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseString, defaultValue: '0') String totalBalance,
    @JsonKey(fromJson: _parseInt, defaultValue: 0) int totalCount,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) int totalPage,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) int currentPage,
  });
}

/// @nodoc
class _$AccountSummaryCopyWithImpl<$Res, $Val extends AccountSummary>
    implements $AccountSummaryCopyWith<$Res> {
  _$AccountSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? totalCount = null,
    Object? totalPage = null,
    Object? currentPage = null,
  }) {
    return _then(
      _value.copyWith(
            totalBalance: null == totalBalance
                ? _value.totalBalance
                : totalBalance // ignore: cast_nullable_to_non_nullable
                      as String,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPage: null == totalPage
                ? _value.totalPage
                : totalPage // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountSummaryImplCopyWith<$Res>
    implements $AccountSummaryCopyWith<$Res> {
  factory _$$AccountSummaryImplCopyWith(
    _$AccountSummaryImpl value,
    $Res Function(_$AccountSummaryImpl) then,
  ) = __$$AccountSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseString, defaultValue: '0') String totalBalance,
    @JsonKey(fromJson: _parseInt, defaultValue: 0) int totalCount,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) int totalPage,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) int currentPage,
  });
}

/// @nodoc
class __$$AccountSummaryImplCopyWithImpl<$Res>
    extends _$AccountSummaryCopyWithImpl<$Res, _$AccountSummaryImpl>
    implements _$$AccountSummaryImplCopyWith<$Res> {
  __$$AccountSummaryImplCopyWithImpl(
    _$AccountSummaryImpl _value,
    $Res Function(_$AccountSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBalance = null,
    Object? totalCount = null,
    Object? totalPage = null,
    Object? currentPage = null,
  }) {
    return _then(
      _$AccountSummaryImpl(
        totalBalance: null == totalBalance
            ? _value.totalBalance
            : totalBalance // ignore: cast_nullable_to_non_nullable
                  as String,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPage: null == totalPage
            ? _value.totalPage
            : totalPage // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountSummaryImpl implements _AccountSummary {
  const _$AccountSummaryImpl({
    @JsonKey(fromJson: _parseString, defaultValue: '0')
    required this.totalBalance,
    @JsonKey(fromJson: _parseInt, defaultValue: 0) required this.totalCount,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) required this.totalPage,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) required this.currentPage,
  });

  factory _$AccountSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountSummaryImplFromJson(json);

  // 값이 없거나 숫자여도 안전하게 String으로 변환
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  final String totalBalance;
  // 값이 없거나 문자열이어도 안전하게 int로 변환
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  final int totalCount;
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  final int totalPage;
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  final int currentPage;

  @override
  String toString() {
    return 'AccountSummary(totalBalance: $totalBalance, totalCount: $totalCount, totalPage: $totalPage, currentPage: $currentPage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountSummaryImpl &&
            (identical(other.totalBalance, totalBalance) ||
                other.totalBalance == totalBalance) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.totalPage, totalPage) ||
                other.totalPage == totalPage) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalBalance,
    totalCount,
    totalPage,
    currentPage,
  );

  /// Create a copy of AccountSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountSummaryImplCopyWith<_$AccountSummaryImpl> get copyWith =>
      __$$AccountSummaryImplCopyWithImpl<_$AccountSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountSummaryImplToJson(this);
  }
}

abstract class _AccountSummary implements AccountSummary {
  const factory _AccountSummary({
    @JsonKey(fromJson: _parseString, defaultValue: '0')
    required final String totalBalance,
    @JsonKey(fromJson: _parseInt, defaultValue: 0)
    required final int totalCount,
    @JsonKey(fromJson: _parseInt, defaultValue: 1) required final int totalPage,
    @JsonKey(fromJson: _parseInt, defaultValue: 1)
    required final int currentPage,
  }) = _$AccountSummaryImpl;

  factory _AccountSummary.fromJson(Map<String, dynamic> json) =
      _$AccountSummaryImpl.fromJson;

  // 값이 없거나 숫자여도 안전하게 String으로 변환
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  String get totalBalance; // 값이 없거나 문자열이어도 안전하게 int로 변환
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  int get totalCount;
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  int get totalPage;
  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 1)
  int get currentPage;

  /// Create a copy of AccountSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountSummaryImplCopyWith<_$AccountSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Account _$AccountFromJson(Map<String, dynamic> json) {
  return _Account.fromJson(json);
}

/// @nodoc
mixin _$Account {
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  int get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
  String get accountName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: '')
  String get accountNumber => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  String get balance => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
  String get status => throw _privateConstructorUsedError; // owner가 null이면 빈 User 객체 반환
  @JsonKey(name: 'owner', fromJson: _parseUser)
  User get owner => throw _privateConstructorUsedError;

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountCopyWith<Account> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) then) =
      _$AccountCopyWithImpl<$Res, Account>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseInt, defaultValue: 0) int id,
    @JsonKey(fromJson: _parseString, defaultValue: '이름 없음') String accountName,
    @JsonKey(fromJson: _parseString, defaultValue: '') String accountNumber,
    @JsonKey(fromJson: _parseString, defaultValue: '0') String balance,
    @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL') String type,
    @JsonKey(fromJson: _parseString, defaultValue: 'PENDING') String status,
    @JsonKey(name: 'owner', fromJson: _parseUser) User owner,
  });

  $UserCopyWith<$Res> get owner;
}

/// @nodoc
class _$AccountCopyWithImpl<$Res, $Val extends Account>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountName = null,
    Object? accountNumber = null,
    Object? balance = null,
    Object? type = null,
    Object? status = null,
    Object? owner = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            accountName: null == accountName
                ? _value.accountName
                : accountName // ignore: cast_nullable_to_non_nullable
                      as String,
            accountNumber: null == accountNumber
                ? _value.accountNumber
                : accountNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            balance: null == balance
                ? _value.balance
                : balance // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as User,
          )
          as $Val,
    );
  }

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get owner {
    return $UserCopyWith<$Res>(_value.owner, (value) {
      return _then(_value.copyWith(owner: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AccountImplCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$$AccountImplCopyWith(
    _$AccountImpl value,
    $Res Function(_$AccountImpl) then,
  ) = __$$AccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseInt, defaultValue: 0) int id,
    @JsonKey(fromJson: _parseString, defaultValue: '이름 없음') String accountName,
    @JsonKey(fromJson: _parseString, defaultValue: '') String accountNumber,
    @JsonKey(fromJson: _parseString, defaultValue: '0') String balance,
    @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL') String type,
    @JsonKey(fromJson: _parseString, defaultValue: 'PENDING') String status,
    @JsonKey(name: 'owner', fromJson: _parseUser) User owner,
  });

  @override
  $UserCopyWith<$Res> get owner;
}

/// @nodoc
class __$$AccountImplCopyWithImpl<$Res>
    extends _$AccountCopyWithImpl<$Res, _$AccountImpl>
    implements _$$AccountImplCopyWith<$Res> {
  __$$AccountImplCopyWithImpl(
    _$AccountImpl _value,
    $Res Function(_$AccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountName = null,
    Object? accountNumber = null,
    Object? balance = null,
    Object? type = null,
    Object? status = null,
    Object? owner = null,
  }) {
    return _then(
      _$AccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        accountName: null == accountName
            ? _value.accountName
            : accountName // ignore: cast_nullable_to_non_nullable
                  as String,
        accountNumber: null == accountNumber
            ? _value.accountNumber
            : accountNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        balance: null == balance
            ? _value.balance
            : balance // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as User,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountImpl implements _Account {
  const _$AccountImpl({
    @JsonKey(fromJson: _parseInt, defaultValue: 0) required this.id,
    @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
    required this.accountName,
    @JsonKey(fromJson: _parseString, defaultValue: '')
    required this.accountNumber,
    @JsonKey(fromJson: _parseString, defaultValue: '0') required this.balance,
    @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
    required this.type,
    @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
    required this.status,
    @JsonKey(name: 'owner', fromJson: _parseUser) required this.owner,
  });

  factory _$AccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountImplFromJson(json);

  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  final int id;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
  final String accountName;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '')
  final String accountNumber;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  final String balance;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
  final String type;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
  final String status;
  // owner가 null이면 빈 User 객체 반환
  @override
  @JsonKey(name: 'owner', fromJson: _parseUser)
  final User owner;

  @override
  String toString() {
    return 'Account(id: $id, accountName: $accountName, accountNumber: $accountNumber, balance: $balance, type: $type, status: $status, owner: $owner)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountName, accountName) ||
                other.accountName == accountName) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.owner, owner) || other.owner == owner));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    accountName,
    accountNumber,
    balance,
    type,
    status,
    owner,
  );

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      __$$AccountImplCopyWithImpl<_$AccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountImplToJson(this);
  }
}

abstract class _Account implements Account {
  const factory _Account({
    @JsonKey(fromJson: _parseInt, defaultValue: 0) required final int id,
    @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
    required final String accountName,
    @JsonKey(fromJson: _parseString, defaultValue: '')
    required final String accountNumber,
    @JsonKey(fromJson: _parseString, defaultValue: '0')
    required final String balance,
    @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
    required final String type,
    @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
    required final String status,
    @JsonKey(name: 'owner', fromJson: _parseUser) required final User owner,
  }) = _$AccountImpl;

  factory _Account.fromJson(Map<String, dynamic> json) = _$AccountImpl.fromJson;

  @override
  @JsonKey(fromJson: _parseInt, defaultValue: 0)
  int get id;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
  String get accountName;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '')
  String get accountNumber;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '0')
  String get balance;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
  String get type;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
  String get status; // owner가 null이면 빈 User 객체 반환
  @override
  @JsonKey(name: 'owner', fromJson: _parseUser)
  User get owner;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  @JsonKey(fromJson: _parseString, defaultValue: '')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음')
  String get name => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseString, defaultValue: '') String userId,
    @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음') String name,
  });
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _parseString, defaultValue: '') String userId,
    @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음') String name,
  });
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? name = null}) {
    return _then(
      _$UserImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl({
    @JsonKey(fromJson: _parseString, defaultValue: '') required this.userId,
    @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음') required this.name,
  });

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  @JsonKey(fromJson: _parseString, defaultValue: '')
  final String userId;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음')
  final String name;

  @override
  String toString() {
    return 'User(userId: $userId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, name);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    @JsonKey(fromJson: _parseString, defaultValue: '')
    required final String userId,
    @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음')
    required final String name,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  @JsonKey(fromJson: _parseString, defaultValue: '')
  String get userId;
  @override
  @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음')
  String get name;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
