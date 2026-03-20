import 'package:intl/intl.dart';

/// ----------------------------------------------------------------------------
/// [TransactionExecutor] ✨ 1. 실행자 정보 모델
/// 거래를 실제로 수행한 사람(본인 또는 공유 멤버)의 정보를 담습니다.
/// UI에서 '나'와 '멤버'를 아이콘이나 텍스트로 구분하기 위해 사용됩니다.
/// ----------------------------------------------------------------------------
class TransactionExecutor {
  final String userId;
  final String name;         // 실행자 이름 (화면 표시용)
  final bool isAccountOwner; // ✨ 계좌 소유주 여부 (true: 본인, false: 공유 멤버)

  TransactionExecutor({
    required this.userId,
    required this.name,
    required this.isAccountOwner,
  });

  factory TransactionExecutor.fromJson(Map<String, dynamic> json) {
    return TransactionExecutor(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      isAccountOwner: json['isAccountOwner'] ?? false,
    );
  }
}

/// ----------------------------------------------------------------------------
/// [Transaction]
/// 거래 내역 1건에 대한 상세 데이터를 담는 메인 모델입니다.
/// 금액, 시간, 상대방 정보뿐만 아니라 '누가 이체했는지(executor)'를 포함합니다.
/// ----------------------------------------------------------------------------
class Transaction {
  final int id;
  final String createdAt;       // 거래 일시 (String 형태)
  final int amount;             // 원금
  final int fee;                // 수수료
  final bool isWithdrawal;      // 출금 여부 (true: 출금, false: 입금)
  final String displayType;     // 표시 유형 (예: "이체", "카드결제")
  final int displayAmount;      // UI에 표시할 최종 금액
  final String counterpartyName;    // 거래 상대방 이름
  final String? counterpartyAccount; // 거래 상대방 계좌번호 (선택)
  final String? memo;           // 메모

  // ✨ 2. 실행자 정보 (null일 경우: 시스템 자동이체 혹은 정보 없음)
  final TransactionExecutor? executor;

  Transaction({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.fee,
    required this.isWithdrawal,
    required this.displayType,
    required this.displayAmount,
    required this.counterpartyName,
    this.counterpartyAccount,
    this.memo,
    this.executor,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      createdAt: json['createdAt'],
      amount: json['amount'],
      fee: json['fee'] ?? 0,
      isWithdrawal: json['isWithdrawal'] ?? false,
      displayType: json['displayType'],
      displayAmount: json['displayAmount'],
      counterpartyName: json['counterpartyName'] ?? '알 수 없음',
      counterpartyAccount: json['counterpartyAccount'],
      memo: json['memo'],

      // ✨ 3. 실행자 정보 파싱 (데이터가 있는 경우에만 객체 생성)
      executor: json['executor'] != null
          ? TransactionExecutor.fromJson(json['executor'])
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // [UI Helper] 화면 표시를 위한 유틸리티 Getter
  // ---------------------------------------------------------------------------

  // 리스트용 짧은 날짜 (예: 12.25 14:30)
  String get shortDate => DateFormat('MM.dd HH:mm').format(DateTime.parse(createdAt));

  // 상세화면용 전체 날짜 (예: 2025.12.25 14:30:00)
  String get fullDate => DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.parse(createdAt));

  // 3자리 콤마 포맷 금액 (예: 10,000)
  String get formattedDisplayAmount => NumberFormat('#,###').format(displayAmount);
}