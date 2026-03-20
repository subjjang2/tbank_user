enum AccountStatus {
  // 서버에서 오는 문자열 값과 매핑
  pending('PENDING'),
  active('ACTIVE'),
  blocked('BLOCKED'),
  closed('CLOSED'),
  unknown('UNKNOWN'); // 예외 처리를 위한 값

  final String code;
  const AccountStatus(this.code);

  // 문자열을 Enum으로 변환하는 함수 (JSON 파싱 시 사용)
  factory AccountStatus.getByCode(String code) {
    return AccountStatus.values.firstWhere(
            (value) => value.code == code,
        orElse: () => AccountStatus.unknown
    );
  }
}