// repository/response/transaction_history_response.dart


import '../../../model/transaction.dart';

class TransactionHistoryResponse {
  final String balance; // ✨ 추가된 잔액 필드
  final String accountName; // ✨ 추가된 잔액 필드
  final int totalCount;
  final int totalPage;
  final int currentPage;
  final List<Transaction> data;

  TransactionHistoryResponse({
    required this.balance,
    required this.totalCount,
    required this.totalPage,
    required this.currentPage,
    required this.data,
    required this.accountName,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryResponse(
      // 백엔드가 보내주는 balance 매핑 (혹시 모를 null 대비 0 처리)
      balance: json['balance'] ?? "0",
      totalCount: json['totalCount'] ?? 0,
      accountName: json['accountName'] ?? "",
      totalPage: json['totalPage'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      data: (json['data'] as List? ?? [])
          .map((e) => Transaction.fromJson(e))
          .toList(),
    );
  }
}