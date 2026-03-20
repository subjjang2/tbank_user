// prisma/schema.prisma의 Enum들과 1:1 매칭되는 파일입니다.

/// 1. 회원 권한
enum Role {
  USER,
  ADMIN,
  AUDITOR;

  /// 문자열을 Enum으로 변환 (예: "ADMIN" -> Role.ADMIN)
  static Role fromJson(String value) =>
      Role.values.firstWhere((e) => e.name == value, orElse: () => Role.USER);

  /// Enum을 문자열로 변환 (예: Role.ADMIN -> "ADMIN")
  String toJson() => name;
}

/// 2. 계좌 타입
enum AccountType {
  PERSONAL,        // 개인 계좌
  SHARED,          // 공동 계좌
  SYSTEM_ISSUE,    // 발행용
  SYSTEM_FEE,      // 수수료
  SYSTEM_INCENTIVE,// 성과급
  SYSTEM_AUDIT;    // 감찰부

  static AccountType fromJson(String value) =>
      AccountType.values.firstWhere((e) => e.name == value, orElse: () => AccountType.PERSONAL);

  String toJson() => name;

  // 화면 표시용 텍스트 (옵션)
  String get label {
    switch (this) {
      case AccountType.PERSONAL: return "개인";
      case AccountType.SHARED: return "공동";
      case AccountType.SYSTEM_ISSUE: return "발행";
      case AccountType.SYSTEM_FEE: return "수수료";
      case AccountType.SYSTEM_INCENTIVE: return "성과급";
      case AccountType.SYSTEM_AUDIT: return "감찰";
    }
  }
}

/// 3. 계좌 상태
enum AccountStatus {
  PENDING,
  ACTIVE,
  DORMANT,
  FROZEN;

  static AccountStatus fromJson(String value) =>
      AccountStatus.values.firstWhere((e) => e.name == value, orElse: () => AccountStatus.ACTIVE);

  String toJson() => name;
}

/// 4. 멤버 권한
enum MemberRole {
  OWNER,
  MEMBER,
  VIEWER;

  static MemberRole fromJson(String value) =>
      MemberRole.values.firstWhere((e) => e.name == value, orElse: () => MemberRole.MEMBER);

  String toJson() => name;
}

/// 5. 거래 유형
enum TransactionType {
  SUPPLY,
  MINT,
  BURN,
  TRANSFER,
  resetIncentive; // Prisma 스키마의 소문자 표기 유지

  static TransactionType fromJson(String value) =>
      TransactionType.values.firstWhere((e) => e.name == value, orElse: () => TransactionType.TRANSFER);

  String toJson() => name;
}

/// 6. 거래 상태
enum TxStatus {
  PENDING,
  SUCCESS,
  FAILED,
  CANCELLED;

  static TxStatus fromJson(String value) =>
      TxStatus.values.firstWhere((e) => e.name == value, orElse: () => TxStatus.SUCCESS);

  String toJson() => name;
}

/// 7. 요청 유형
enum RequestType {
  CREATE_ACCOUNT,
  DELETE_ACCOUNT,
  INVITE_MEMBER,
  GRANT_VIEW_ACCESS,
  GRANT_TRANSFER_ACCESS,
  REVOKE_VIEW_ACCESS,
  REVOKE_TRANSFER_ACCESS;

  static RequestType fromJson(String value) =>
      RequestType.values.firstWhere((e) => e.name == value, orElse: () => RequestType.CREATE_ACCOUNT);

  String toJson() => name;
}

/// 8. 요청 상태
enum RequestStatus {
  PENDING,
  APPROVED,
  REJECTED;

  static RequestStatus fromJson(String value) =>
      RequestStatus.values.firstWhere((e) => e.name == value, orElse: () => RequestStatus.PENDING);

  String toJson() => name;
}