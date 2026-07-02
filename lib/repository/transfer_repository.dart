import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tbank_user/repository/response/account_search/account_searchtype_response.dart';
import 'package:tbank_user/repository/response/transaction_history/transaction_history_response.dart';


import '../util/helper/api_error_handler.dart';
import '../util/helper/app_exception.dart';
import '../util/helper/network_helper.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// 외부에서 TransferRepository를 사용할 수 있도록 의존성을 주입합니다.
final transRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.read(dioProvider));
});

// =============================================================================
// 2. Repository 클래스
// =============================================================================
class TransferRepository {
  final Dio _dio;
  const TransferRepository(this._dio);

  // ---------------------------------------------------------------------------
  // [API] 거래 내역 조회
  // GET /transactions/{accountNumber}/history
  // ---------------------------------------------------------------------------
  Future<TransactionHistoryResponse> fetchHistory(
      String accountNumber, {
        required int page,
        required int limit,
        DateTime? startDate, // 선택적 날짜 필터
        DateTime? endDate,   // 선택적 날짜 필터
      }) async {
    try {
      // 1. 쿼리 파라미터 구성
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      // 2. 날짜 포맷팅 (yyyy-MM-dd) 및 파라미터 추가
      if (startDate != null) {
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      // 3. API 요청
      final response = await _dio.get(
        '/transactions/$accountNumber/history',
        queryParameters: queryParams,
      );

      final dynamic responseBody = response.data;

      // 4. 응답 파싱
      return TransactionHistoryResponse.fromJson(responseBody['data']);
    } catch (e) {
      // 5. 공통 에러 핸들러를 통해 예외 변환 후 던짐
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 이체 실행
  // POST /transactions/transfer
  // ---------------------------------------------------------------------------
  Future<bool> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required String amount,
    required String memo,
  }) async {
    try {
      // API 호출
      final res = await _dio.post('/transactions/transfer', data: {
        'fromAccountNumber': fromAccountNumber,
        'toAccountNumber': toAccountNumber,
        'amount': amount,
        'memo': memo,
      });

      return true; // 성공 시 true 반환
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 계좌 실명 조회 (예금주 확인)
  // POST /accounts/check
  // ---------------------------------------------------------------------------
  Future<AccountSearchResponse?> searchAccount({
    required String accountNumber,
    required AccountSearchType type, // 조회 타입 (info: 정보조회, check: 존재확인)
  }) async {
    try {
      final res = await _dio.post(
        '/accounts/check',
        data: {
          'accountNumber': accountNumber,
          'type': type.name, // Enum을 문자열로 변환하여 전송
        },
      );

      final responseBody = res.data;

      // 데이터가 존재하면 모델로 변환하여 반환
      if (responseBody != null && responseBody['data'] != null) {
        return AccountSearchResponse.fromJson(responseBody['data']);
      }

      return null;
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }
}