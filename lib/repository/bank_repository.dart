import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/Transaction.dart';
import '../model/account.dart';
import '../util/helper/network_helper.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// 외부에서 BankRepository를 사용할 수 있도록 의존성 주입 (Dio 객체 전달)
final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository(ref.read(dioProvider));
});

// =============================================================================
// 2. Repository 클래스
// =============================================================================
class BankRepository {
  final Dio _dio;
  const BankRepository(this._dio);

  // ---------------------------------------------------------------------------
  // [API] 내 계좌 정보 조회
  // GET /api/account/my
  // ---------------------------------------------------------------------------
  Future<AccountModel> getMyAccount() async {
    try {
      final res = await _dio.get('/api/account/my');

      // 성공 시 데이터 파싱
      if (res.statusCode == 200 && res.data != null) {
        return AccountModel.fromJson(res.data);
      }
      // 데이터가 없거나 실패 시 빈 모델 반환 (Null Safety)
      return AccountModel.empty();
    } catch (e) {
      // 통신 에러 시 빈 모델 반환
      return AccountModel.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 거래 내역 목록 조회
  // GET /api/transaction/list
  // ---------------------------------------------------------------------------
  Future<List<Transaction>> getTransactionList() async {
    try {
      final res = await _dio.get('/api/transaction/list');

      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['list'] ?? [];
        // 리스트 매핑: JSON -> Transaction 객체 변환
        return list.map((e) => Transaction.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }
}