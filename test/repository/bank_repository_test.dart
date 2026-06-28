import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/bank_repository.dart';

import 'mock_dio.dart';

// =============================================================================
// BankRepository 단위 테스트
//
// 핵심 계약: BankRepository는 다른 Repository와 달리 에러를 throw하지 않고
// 빈 값(AccountModel.empty() / [])을 삼켜서 반환한다.
// =============================================================================

void main() {
  // BankRepository를 mock Dio로 생성하는 헬퍼
  BankRepository build(MockHandler handler) =>
      BankRepository(buildMockDio(handler));

  // 최소 유효 AccountModel JSON (fromJson 키 기준)
  Map<String, dynamic> validAccountJson() => {
    'bankName': '토스뱅크',
    'accountNumber': '1000-2000-3000',
    'balance': 50000,
    'type': 'savings',
  };

  // 최소 유효 Transaction JSON (id, createdAt, amount, displayType, displayAmount 필수)
  Map<String, dynamic> validTransactionJson({int id = 1}) => {
    'id': id,
    'createdAt': '2025-01-15T10:30:00',
    'amount': 10000,
    'fee': 500,
    'isWithdrawal': true,
    'displayType': '이체',
    'displayAmount': 10500,
    'counterpartyName': '홍길동',
    'counterpartyAccount': '1234-5678',
    'memo': '테스트 이체',
  };

  // ---------------------------------------------------------------------------
  // getMyAccount()
  // ---------------------------------------------------------------------------
  group('getMyAccount() — 정상 응답', () {
    test('200 + data가 있으면 AccountModel.fromJson으로 파싱된 모델을 반환한다', () async {
      final repo = build((o) => MockReply(200, validAccountJson()));

      final result = await repo.getMyAccount();

      // fromJson 키 매핑: bankName→accountName, accountNumber, balance, type
      expect(result.accountName, '토스뱅크');
      expect(result.accountNumber, '1000-2000-3000');
      expect(result.balance, 50000);
      expect(result.type, 'savings');
    });

    test('요청 경로가 /api/account/my 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, validAccountJson());
      });

      await repo.getMyAccount();

      expect(calledPath, '/api/account/my');
    });
  });

  group('getMyAccount() — 에러 삼킴 계약 (AccountModel.empty() 반환)', () {
    // AccountModel.empty() 식별자: accountName='', accountNumber='', balance=0, type=''

    test('500 응답이면 throw하지 않고 AccountModel.empty()를 반환한다', () async {
      // respondsWith(500, ...) → Dio가 badResponse DioException으로 변환 → catch에서 삼킴
      final repo = build(
        respondsWith(500, {'message': 'internal server error'}),
      );

      final result = await repo.getMyAccount();

      expect(result.accountName, '');
      expect(result.accountNumber, '');
      expect(result.balance, 0);
      expect(result.type, '');
    });

    test('연결 타임아웃이면 throw하지 않고 AccountModel.empty()를 반환한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      final result = await repo.getMyAccount();

      expect(result.accountName, '');
      expect(result.balance, 0);
    });

    test(
      '연결 실패(connectionError)면 throw하지 않고 AccountModel.empty()를 반환한다',
      () async {
        final repo = build(throwsDioType(DioExceptionType.connectionError));

        final result = await repo.getMyAccount();

        expect(result.accountNumber, '');
        expect(result.type, '');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getTransactionList()
  // ---------------------------------------------------------------------------
  group('getTransactionList() — 정상 응답', () {
    test('200 + list가 있으면 Transaction 개수가 일치한다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'list': [validTransactionJson(id: 1), validTransactionJson(id: 2)],
        }),
      );

      final result = await repo.getTransactionList();

      expect(result.length, 2);
    });

    test('Transaction 필드가 올바르게 파싱된다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'list': [validTransactionJson()],
        }),
      );

      final result = await repo.getTransactionList();

      final tx = result.first;
      expect(tx.id, 1);
      expect(tx.amount, 10000);
      expect(tx.fee, 500);
      expect(tx.isWithdrawal, true);
      expect(tx.displayType, '이체');
      expect(tx.displayAmount, 10500);
      expect(tx.counterpartyName, '홍길동');
    });

    test('요청 경로가 /api/transaction/list 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'list': []});
      });

      await repo.getTransactionList();

      expect(calledPath, '/api/transaction/list');
    });

    test('list 키가 없으면 빈 리스트를 반환한다 (data[\'list\'] == null → ?? [])', () async {
      // res.data에 'list' 키 자체가 없는 경우
      final repo = build((o) => MockReply(200, <String, dynamic>{}));

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });

    test('list가 null이면 빈 리스트를 반환한다', () async {
      final repo = build((o) => MockReply(200, {'list': null}));

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });

    test('list가 빈 배열이면 빈 리스트를 반환한다', () async {
      final repo = build((o) => MockReply(200, {'list': <dynamic>[]}));

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });
  });

  group('getTransactionList() — 에러 삼킴 계약 ([] 반환)', () {
    test('500 응답이면 throw하지 않고 빈 리스트를 반환한다', () async {
      final repo = build(
        respondsWith(500, {'message': 'internal server error'}),
      );

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });

    test('연결 타임아웃이면 throw하지 않고 빈 리스트를 반환한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });

    test('연결 실패(connectionError)면 throw하지 않고 빈 리스트를 반환한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      final result = await repo.getTransactionList();

      expect(result, isEmpty);
    });
  });
}
