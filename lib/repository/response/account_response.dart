import 'package:freezed_annotation/freezed_annotation.dart';

// 파일명과 동일하게 지정해야 합니다.
part 'account_response.freezed.dart';
part 'account_response.g.dart';

// ------------------------------------------------------------------
// 1. AccountResponse
// ------------------------------------------------------------------
@freezed
class AccountResponse with _$AccountResponse {
  const factory AccountResponse({
    // summary가 null이면 빈 객체(empty)를 반환하도록 _parseSummary 연결
    @JsonKey(name: 'summary', fromJson: _parseSummary)
    required AccountSummary summary,

    // list가 null이면 빈 리스트 반환
    @Default([]) List<Account> list,
  }) = _AccountResponse;

  factory AccountResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountResponseFromJson(json);
}

// ------------------------------------------------------------------
// 2. AccountSummary
// ------------------------------------------------------------------
@freezed
class AccountSummary with _$AccountSummary {
  const factory AccountSummary({
    // 값이 없거나 숫자여도 안전하게 String으로 변환
    @JsonKey(fromJson: _parseString, defaultValue: '0')
    required String totalBalance,

    // 값이 없거나 문자열이어도 안전하게 int로 변환
    @JsonKey(fromJson: _parseInt, defaultValue: 0)
    required int totalCount,

    @JsonKey(fromJson: _parseInt, defaultValue: 1)
    required int totalPage,

    @JsonKey(fromJson: _parseInt, defaultValue: 1)
    required int currentPage,
  }) = _AccountSummary;

  factory AccountSummary.fromJson(Map<String, dynamic> json) =>
      _$AccountSummaryFromJson(json);

  // 기존 코드 호환용 empty 팩토리
  factory AccountSummary.empty() => const AccountSummary(
    totalBalance: '0',
    totalCount: 0,
    totalPage: 1,
    currentPage: 1,
  );
}

// ------------------------------------------------------------------
// 3. Account
// ------------------------------------------------------------------
@freezed
class Account with _$Account {
  const factory Account({
    @JsonKey(fromJson: _parseInt, defaultValue: 0)
    required int id,

    @JsonKey(fromJson: _parseString, defaultValue: '이름 없음')
    required String accountName,

    @JsonKey(fromJson: _parseString, defaultValue: '')
    required String accountNumber,

    @JsonKey(fromJson: _parseString, defaultValue: '0')
    required String balance,

    @JsonKey(fromJson: _parseString, defaultValue: 'PERSONAL')
    required String type,

    @JsonKey(fromJson: _parseString, defaultValue: 'PENDING')
    required String status,

    // owner가 null이면 빈 User 객체 반환
    @JsonKey(name: 'owner', fromJson: _parseUser)
    required User owner,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

// ------------------------------------------------------------------
// 4. User
// ------------------------------------------------------------------
@freezed
class User with _$User {
  const factory User({
    @JsonKey(fromJson: _parseString, defaultValue: '')
    required String userId,

    @JsonKey(fromJson: _parseString, defaultValue: '알 수 없음')
    required String name,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // 기존 호환용
  factory User.empty() => const User(userId: '', name: '알 수 없음');
}

// ==================================================================
// 🛠️ 안전한 파싱을 위한 헬퍼 함수들 (Safe Parsing Helpers)
// ==================================================================

// 1. 안전한 Int 변환 (String "100" -> 100, null -> 0)
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// 2. 안전한 String 변환 (100 -> "100", null -> "")
String _parseString(dynamic value) {
  return value?.toString() ?? '';
}

// 3. 안전한 Summary 객체 변환
AccountSummary _parseSummary(dynamic value) {
  if (value is Map<String, dynamic>) {
    return AccountSummary.fromJson(value);
  }
  return AccountSummary.empty();
}

// 4. 안전한 User 객체 변환
User _parseUser(dynamic value) {
  if (value is Map<String, dynamic>) {
    return User.fromJson(value);
  }
  return User.empty();
}