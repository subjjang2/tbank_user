import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_authority_response.freezed.dart';
part 'account_authority_response.g.dart';

// 1. 메인 응답 객체
@freezed
class AccountAuthorityResponse with _$AccountAuthorityResponse {
  const factory AccountAuthorityResponse({
    required String accountNumber,

    // API에서 값이 안 넘어올 경우를 대비해 Default false 처리
    @Default(false) bool isAuditorAllowed,
    @Default(false) bool isPending,


    // ② 권한 목록: 단순 String이 아닌 Permission 객체의 리스트
    @Default([]) List<Permission> permissions,
  }) = _AccountAuthorityResponse;

  factory AccountAuthorityResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountAuthorityResponseFromJson(json);
}

// 2. 내부 권한 객체 (permissions 배열 안의 아이템)
@freezed
class Permission with _$Permission {
  const factory Permission({
    required String userId,
    required String userName,

    // "ALL", "VIEW" 등.
    // 만약 고정된 값만 온다면 enum으로 처리할 수도 있지만,
    // 서버 변경 대응을 위해 String으로 받는 것이 안전합니다.
    required String type,
  }) = _Permission;

  factory Permission.fromJson(Map<String, dynamic> json) =>
      _$PermissionFromJson(json);
}