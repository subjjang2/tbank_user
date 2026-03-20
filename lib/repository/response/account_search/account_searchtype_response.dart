// 서버의 enum과 매칭되는 Dart enum
enum AccountSearchType {
  full,  // 전체 정보
  info,  // 계좌명 + 예금주 + 잔액
  check, // 계좌명 (잔액 미포함)
}

class AccountSearchResponse {
  final String? accountNumber;
  final String? accountName;
  final String? ownerName;
  final int? balance;
  final String? status; // ✨ [추가] ACTIVE, PENDING, BLOCKED 등

  AccountSearchResponse({
    this.accountNumber,
    this.accountName,
    this.ownerName,
    this.balance,
    this.status,
  });

  factory AccountSearchResponse.fromJson(Map<String, dynamic> json) {
    return AccountSearchResponse(
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      ownerName: json['ownerName'],
      balance: (json['balance'] as num?)?.toInt(),
      status: json['status'], // JSON 파싱 추가
    );
  }

  // ✨ [편의 기능] 상태 확인용 getter
  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING';
  bool get isBlocked => status == 'BLOCKED';
}