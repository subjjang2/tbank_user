import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/transfer_repository.dart';
import 'package:tbank_user/repository/response/account_search/account_searchtype_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';

import 'mock_dio.dart';

// =============================================================================
// TransferRepository 단위 테스트
//
// 대상 메서드:
//   1. fetchHistory() — GET /transactions/{accountNumber}/history
//   2. transfer()     — POST /transactions/transfer
//   3. searchAccount() — POST /accounts/check
//
// Mock 전략: buildMockDio(handler) 로 Dio를 교체, 실제 네트워크 없이 실행.
// =============================================================================

void main() {
  // Repository 생성 헬퍼
  TransferRepository build(MockHandler handler) =>
      TransferRepository(buildMockDio(handler));

  // ---------------------------------------------------------------------------
  // 공통 픽스처
  // ---------------------------------------------------------------------------

  /// fetchHistory 성공 응답에 필요한 최소 data 구조
  Map<String, dynamic> makeHistoryData({
    List<Map<String, dynamic>>? transactions,
  }) => {
    'balance': '100000',
    'accountName': '테스트 계좌',
    'totalCount': 1,
    'totalPage': 1,
    'currentPage': 1,
    'data':
        transactions ??
        [
          {
            'id': 1,
            'createdAt': '2024-01-05T12:00:00',
            'amount': 5000,
            'fee': 0,
            'isWithdrawal': false,
            'displayType': '이체',
            'displayAmount': 5000,
            'counterpartyName': '홍길동',
          },
        ],
  };

  /// searchAccount 성공 응답에 필요한 최소 data 구조
  Map<String, dynamic> makeAccountData() => {
    'accountNumber': '123-456-789',
    'accountName': '테스트 통장',
    'ownerName': '홍길동',
    'balance': 50000,
    'status': 'ACTIVE',
  };

  // ===========================================================================
  // 1. fetchHistory()
  // ===========================================================================
  group('fetchHistory() — 경로·파라미터 검증', () {
    test('경로에 accountNumber가 포함된다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory('123-456', page: 1, limit: 10);

      expect(calledPath, '/transactions/123-456/history');
    });

    test('page와 limit이 queryParameters에 포함된다', () async {
      Map<String, dynamic>? capturedQuery;
      final repo = build((o) {
        capturedQuery = o.queryParameters;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory('111', page: 2, limit: 20);

      expect(capturedQuery?['page'], 2);
      expect(capturedQuery?['limit'], 20);
    });

    test('startDate가 있으면 yyyy-MM-dd 포맷으로 query에 추가된다 (2024-01-05)', () async {
      Map<String, dynamic>? capturedQuery;
      final repo = build((o) {
        capturedQuery = o.queryParameters;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory(
        '111',
        page: 1,
        limit: 10,
        startDate: DateTime(2024, 1, 5),
      );

      expect(capturedQuery?['startDate'], '2024-01-05');
    });

    test('endDate가 있으면 yyyy-MM-dd 포맷으로 query에 추가된다 (2024-12-31)', () async {
      Map<String, dynamic>? capturedQuery;
      final repo = build((o) {
        capturedQuery = o.queryParameters;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory(
        '111',
        page: 1,
        limit: 10,
        endDate: DateTime(2024, 12, 31),
      );

      expect(capturedQuery?['endDate'], '2024-12-31');
    });

    test('startDate와 endDate 둘 다 없으면 날짜 키가 query에 없다', () async {
      Map<String, dynamic>? capturedQuery;
      final repo = build((o) {
        capturedQuery = o.queryParameters;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory('111', page: 1, limit: 10);

      expect(capturedQuery?.containsKey('startDate'), isFalse);
      expect(capturedQuery?.containsKey('endDate'), isFalse);
    });

    test('startDate와 endDate 둘 다 있으면 두 날짜 키가 모두 query에 포함된다', () async {
      Map<String, dynamic>? capturedQuery;
      final repo = build((o) {
        capturedQuery = o.queryParameters;
        return MockReply(200, {'data': makeHistoryData()});
      });

      await repo.fetchHistory(
        '111',
        page: 1,
        limit: 10,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      expect(capturedQuery?['startDate'], '2024-01-01');
      expect(capturedQuery?['endDate'], '2024-01-31');
    });
  });

  group('fetchHistory() — 응답 파싱', () {
    test('TransactionHistoryResponse가 올바르게 파싱된다', () async {
      final repo = build((o) => MockReply(200, {'data': makeHistoryData()}));

      final result = await repo.fetchHistory('123-456', page: 1, limit: 10);

      expect(result.balance, '100000');
      expect(result.accountName, '테스트 계좌');
      expect(result.totalCount, 1);
      expect(result.totalPage, 1);
      expect(result.currentPage, 1);
      expect(result.data.length, 1);
    });

    test('Transaction 아이템이 올바르게 파싱된다', () async {
      final repo = build((o) => MockReply(200, {'data': makeHistoryData()}));

      final result = await repo.fetchHistory('123-456', page: 1, limit: 10);
      final tx = result.data.first;

      expect(tx.id, 1);
      expect(tx.amount, 5000);
      expect(tx.counterpartyName, '홍길동');
      expect(tx.isWithdrawal, isFalse);
    });

    test('data 리스트가 비어있어도 파싱된다', () async {
      final repo = build(
        (o) => MockReply(200, {'data': makeHistoryData(transactions: [])}),
      );

      final result = await repo.fetchHistory('111', page: 1, limit: 10);

      expect(result.data, isEmpty);
    });
  });

  group('fetchHistory() — 에러 계약 (AppException throw)', () {
    test('서버 message가 있으면 그 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '계좌를 찾을 수 없습니다.'}));

      await expectLater(
        repo.fetchHistory('111', page: 1, limit: 10),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '계좌를 찾을 수 없습니다.',
          ),
        ),
      );
    });

    test('500 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      expect(
        () => repo.fetchHistory('111', page: 1, limit: 10),
        throwsA(isA<AppException>()),
      );
    });

    test('연결 타임아웃이면 타임아웃 안내 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.fetchHistory('111', page: 1, limit: 10),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });

    test('연결 에러이면 서버 연결 불가 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.fetchHistory('111', page: 1, limit: 10),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('연결할 수 없습니다'),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // 2. transfer()
  // ===========================================================================
  group('transfer() — 정상 응답', () {
    test('성공 시 true를 반환한다', () async {
      final repo = build((o) => MockReply(200, {'success': true}));

      final result = await repo.transfer(
        fromAccountNumber: '111-111',
        toAccountNumber: '222-222',
        amount: '10000',
        memo: '테스트 송금',
      );

      expect(result, isTrue);
    });

    test('POST 경로가 /transactions/transfer이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'success': true});
      });

      await repo.transfer(
        fromAccountNumber: '111',
        toAccountNumber: '222',
        amount: '5000',
        memo: 'memo',
      );

      expect(calledPath, '/transactions/transfer');
    });

    test(
      '전송 data에 4개 키(fromAccountNumber, toAccountNumber, amount, memo)가 포함된다',
      () async {
        dynamic capturedData;
        final repo = build((o) {
          capturedData = o.data;
          return MockReply(200, {'success': true});
        });

        await repo.transfer(
          fromAccountNumber: 'from-111',
          toAccountNumber: 'to-222',
          amount: '99000',
          memo: '점심값',
        );

        expect(capturedData['fromAccountNumber'], 'from-111');
        expect(capturedData['toAccountNumber'], 'to-222');
        expect(capturedData['amount'], '99000');
        expect(capturedData['memo'], '점심값');
      },
    );
  });

  group('transfer() — 에러 계약 (AppException throw)', () {
    test('400 응답 message(잔액부족)가 AppException으로 그대로 전달된다', () async {
      final repo = build(respondsWith(400, {'message': '잔액이 부족합니다.'}));

      await expectLater(
        repo.transfer(
          fromAccountNumber: '111',
          toAccountNumber: '222',
          amount: '99999999',
          memo: '대량이체',
        ),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', '잔액이 부족합니다.'),
        ),
      );
    });

    test('서버 message 없는 400이면 기본 메시지로 AppException throw한다', () async {
      final repo = build(respondsWith(400, {}));

      await expectLater(
        repo.transfer(
          fromAccountNumber: '111',
          toAccountNumber: '222',
          amount: '1000',
          memo: 'test',
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('연결 타임아웃이면 타임아웃 안내 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.transfer(
          fromAccountNumber: '111',
          toAccountNumber: '222',
          amount: '5000',
          memo: 'test',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // 3. searchAccount()
  // ===========================================================================
  group('searchAccount() — 경로·파라미터 검증', () {
    test('POST 경로가 /accounts/check이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': makeAccountData()});
      });

      await repo.searchAccount(
        accountNumber: '123-456',
        type: AccountSearchType.info,
      );

      expect(calledPath, '/accounts/check');
    });

    test('AccountSearchType.info → type: "info" 가 전송된다', () async {
      dynamic capturedData;
      final repo = build((o) {
        capturedData = o.data;
        return MockReply(200, {'data': makeAccountData()});
      });

      await repo.searchAccount(
        accountNumber: '123-456',
        type: AccountSearchType.info,
      );

      expect(capturedData['type'], 'info');
      expect(capturedData['accountNumber'], '123-456');
    });

    test('AccountSearchType.check → type: "check" 가 전송된다', () async {
      dynamic capturedData;
      final repo = build((o) {
        capturedData = o.data;
        return MockReply(200, {'data': makeAccountData()});
      });

      await repo.searchAccount(
        accountNumber: '999',
        type: AccountSearchType.check,
      );

      expect(capturedData['type'], 'check');
    });

    test('AccountSearchType.full → type: "full" 이 전송된다', () async {
      dynamic capturedData;
      final repo = build((o) {
        capturedData = o.data;
        return MockReply(200, {'data': makeAccountData()});
      });

      await repo.searchAccount(
        accountNumber: '999',
        type: AccountSearchType.full,
      );

      expect(capturedData['type'], 'full');
    });
  });

  group('searchAccount() — 응답 파싱', () {
    test('data가 있으면 AccountSearchResponse를 반환한다', () async {
      final repo = build((o) => MockReply(200, {'data': makeAccountData()}));

      final result = await repo.searchAccount(
        accountNumber: '123-456-789',
        type: AccountSearchType.info,
      );

      expect(result, isNotNull);
      expect(result!.accountNumber, '123-456-789');
      expect(result.accountName, '테스트 통장');
      expect(result.ownerName, '홍길동');
      expect(result.balance, 50000);
      expect(result.isActive, isTrue);
    });

    test('data가 null이면 null을 반환한다 (핵심 분기)', () async {
      // 서버가 {"data": null} 로 응답하는 경우 — 계좌 없음 등
      final repo = build((o) => MockReply(200, {'data': null}));

      final result = await repo.searchAccount(
        accountNumber: '123-456',
        type: AccountSearchType.check,
      );

      expect(result, isNull);
    });

    test('응답 body 자체가 null이면 null을 반환한다', () async {
      // body가 완전히 비어있거나 null인 경우 방어 처리
      final repo = build((o) => MockReply(200, null));

      final result = await repo.searchAccount(
        accountNumber: '123-456',
        type: AccountSearchType.check,
      );

      expect(result, isNull);
    });
  });

  group('searchAccount() — 에러 계약 (AppException throw)', () {
    test('500 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': '서버 내부 오류'}));

      expect(
        () => repo.searchAccount(
          accountNumber: '111',
          type: AccountSearchType.check,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('연결 에러이면 서버 연결 불가 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.searchAccount(accountNumber: '111', type: AccountSearchType.full),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('연결할 수 없습니다'),
          ),
        ),
      );
    });

    test('receiveTimeout이면 타임아웃 안내 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.receiveTimeout));

      await expectLater(
        repo.searchAccount(accountNumber: '111', type: AccountSearchType.info),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });
  });
}
