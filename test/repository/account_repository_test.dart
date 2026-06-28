import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/app_config.dart';
import 'package:tbank_user/util/helper/app_exception.dart';

import 'mock_dio.dart';

// =============================================================================
// AccountRepository 단위 테스트
//
// 대상 메서드:
//   1. getMyProfile()              — GET /users/me
//   2. getAccessibleAccounts()    — GET /accounts/accessible  (limit 무시 검증)
//   3. getViewerAccounts()        — GET /accounts/viewer      (limit 무시 검증)
//   4. requestPermissionChange()  — POST /accounts/permissions/request (Permission DTO 매핑)
//   5. searchUserForPermission()  — GET /users/search         (404→null 특수 케이스)
//   6. getPermissions()           — GET /accounts/{number}/permissions (경로 포함 검증)
//   7. createPersonalAccount()    — POST /accounts/createPersonal
//   8. fetchMyAccounts()          — GET /accounts/accountList
// =============================================================================

void main() {
  // Mock Dio로 AccountRepository를 생성하는 헬퍼
  AccountRepository build(MockHandler handler) =>
      AccountRepository(buildMockDio(handler));

  // ---------------------------------------------------------------------------
  // 테스트용 최소 유효 JSON 픽스처
  // (각 모델의 fromJson을 직접 읽어 구성 — 추측 없음)
  // ---------------------------------------------------------------------------

  // UserProfileModel.fromJson: {userId, name, role}
  Map<String, dynamic> userProfileJson() => {
    'userId': 'u1',
    'name': '홍길동',
    'role': 'USER',
  };

  // AccountResponse.fromJson (data 래퍼 안): {summary, list}
  // summary: {totalBalance, totalCount, totalPage, currentPage}
  // list[]: {id, accountName, accountNumber, balance, type, status, owner}
  Map<String, dynamic> accountResponseJson() => {
    'summary': {
      'totalBalance': '5000',
      'totalCount': 1,
      'totalPage': 1,
      'currentPage': 1,
    },
    'list': [
      {
        'id': 1,
        'accountName': '테스트계좌',
        'accountNumber': '1234-5678',
        'balance': '5000',
        'type': 'PERSONAL',
        'status': 'ACTIVE',
        'owner': {'userId': 'u1', 'name': '홍길동'},
      },
    ],
  };

  // AccountAuthorityResponse.fromJson (data 래퍼 안):
  // {accountNumber, isAuditorAllowed, isPending, permissions[]}
  Map<String, dynamic> authorityResponseJson() => {
    'accountNumber': 'ACC001',
    'isAuditorAllowed': true,
    'isPending': false,
    'permissions': [
      {'userId': 'u1', 'userName': '홍길동', 'type': 'ALL'},
    ],
  };

  // account_response.dart의 freezed User: {userId, name} 만 필요
  // (account_repository.dart는 model/user.dart를 임포트하지 않으므로
  //  searchUserForPermission의 User는 account_response.dart의 User임)
  Map<String, dynamic> userJson() => {'userId': 'u1', 'name': '홍길동'};

  // ==========================================================================
  // 1. getMyProfile() — GET /users/me
  // ==========================================================================
  group('getMyProfile()', () {
    test('성공: responseBody["data"]를 UserProfileModel로 파싱해 반환한다', () async {
      final repo = build((o) => MockReply(200, {'data': userProfileJson()}));

      final result = await repo.getMyProfile();

      expect(result.userId, 'u1');
      expect(result.name, '홍길동');
      expect(result.role, 'USER');
    });

    test('요청 경로가 /users/me 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': userProfileJson()});
      });

      await repo.getMyProfile();

      expect(calledPath, '/users/me');
    });

    test('에러: 서버 메시지가 있으면 그 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': '서버 오류 발생'}));

      await expectLater(
        repo.getMyProfile(),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', '서버 오류 발생'),
        ),
      );
    });

    test('에러: 401 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(401, {'message': null}));

      await expectLater(repo.getMyProfile(), throwsA(isA<AppException>()));
    });

    test('에러: 연결 타임아웃이면 시간 초과 안내 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.getMyProfile(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });

    test('에러: connectionError이면 연결 불가 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.getMyProfile(),
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

  // ==========================================================================
  // 2. getAccessibleAccounts() — GET /accounts/accessible
  //    핵심 검증: limit 파라미터를 넘겨도 실제 쿼리는 AppConfig.defaultLimit(20) 사용
  // ==========================================================================
  group('getAccessibleAccounts()', () {
    test('성공: AccountResponse를 파싱해 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {'data': accountResponseJson()}),
      );

      final result = await repo.getAccessibleAccounts();

      expect(result.summary.totalCount, 1);
      expect(result.list.length, 1);
      expect(result.list.first.accountName, '테스트계좌');
    });

    test('요청 경로가 /accounts/accessible 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.getAccessibleAccounts();

      expect(calledPath, '/accounts/accessible');
    });

    test(
      '[limit 무시] limit 인자를 전달해도 쿼리에는 AppConfig.defaultLimit(20)이 사용된다',
      () async {
        // limit: 5를 넘기지만 실제 쿼리는 AppConfig.defaultLimit(=20)이어야 함
        int? capturedLimit;
        final repo = build((o) {
          capturedLimit = o.queryParameters['limit'] as int?;
          return MockReply(200, {'data': accountResponseJson()});
        });

        await repo.getAccessibleAccounts(page: 1, limit: 5);

        expect(capturedLimit, AppConfig.defaultLimit); // 20
        expect(capturedLimit, isNot(5));
      },
    );

    test('page 파라미터가 쿼리에 그대로 전달된다', () async {
      int? capturedPage;
      final repo = build((o) {
        capturedPage = o.queryParameters['page'] as int?;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.getAccessibleAccounts(page: 3);

      expect(capturedPage, 3);
    });

    test('에러: 500 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      await expectLater(
        repo.getAccessibleAccounts(),
        throwsA(isA<AppException>()),
      );
    });

    test('에러: 연결 에러이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.getAccessibleAccounts(),
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

  // ==========================================================================
  // 3. getViewerAccounts() — GET /accounts/viewer
  //    핵심 검증: limit 파라미터 무시, AppConfig.defaultLimit 사용
  // ==========================================================================
  group('getViewerAccounts()', () {
    test('성공: AccountResponse를 파싱해 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {'data': accountResponseJson()}),
      );

      final result = await repo.getViewerAccounts();

      expect(result.summary.totalCount, 1);
      expect(result.list.length, 1);
    });

    test('요청 경로가 /accounts/viewer 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.getViewerAccounts();

      expect(calledPath, '/accounts/viewer');
    });

    test(
      '[limit 무시] limit 인자를 전달해도 쿼리에는 AppConfig.defaultLimit(20)이 사용된다',
      () async {
        int? capturedLimit;
        final repo = build((o) {
          capturedLimit = o.queryParameters['limit'] as int?;
          return MockReply(200, {'data': accountResponseJson()});
        });

        await repo.getViewerAccounts(page: 1, limit: 99);

        expect(capturedLimit, AppConfig.defaultLimit); // 20
        expect(capturedLimit, isNot(99));
      },
    );

    test('에러: 403 응답이면 서버 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(403, {'message': '접근 권한이 없습니다.'}));

      await expectLater(
        repo.getViewerAccounts(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '접근 권한이 없습니다.',
          ),
        ),
      );
    });

    test('에러: 연결 타임아웃이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(repo.getViewerAccounts(), throwsA(isA<AppException>()));
    });
  });

  // ==========================================================================
  // 4. requestPermissionChange() — POST /accounts/permissions/request
  //    핵심 검증: Permission 객체가 {userId, type} 으로 매핑됨 (userName 제외)
  // ==========================================================================
  group('requestPermissionChange()', () {
    test('성공: 정상 응답이면 예외 없이 완료된다', () async {
      final repo = build((o) => MockReply(200, {'success': true}));

      await expectLater(
        repo.requestPermissionChange(
          targetAccountNo: 'ACC001',
          auditEnabled: true,
          permissions: [],
        ),
        completes,
      );
    });

    test('요청 경로가 /accounts/permissions/request 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {});
      });

      await repo.requestPermissionChange(
        targetAccountNo: 'ACC001',
        auditEnabled: false,
        permissions: [],
      );

      expect(calledPath, '/accounts/permissions/request');
    });

    test('[DTO 매핑] permissions가 {userId, type}만 포함된다 (userName 제외)', () async {
      Map<String, dynamic>? capturedData;
      final repo = build((o) {
        capturedData = Map<String, dynamic>.from(o.data as Map);
        return MockReply(200, {});
      });

      // Permission에는 userName이 있지만, 전송 데이터에서 제거되어야 함
      const perm = Permission(userId: 'u1', userName: '홍길동', type: 'ALL');
      await repo.requestPermissionChange(
        targetAccountNo: 'ACC001',
        auditEnabled: true,
        permissions: [perm],
      );

      final sentPermissions = capturedData!['permissions'] as List;
      expect(sentPermissions, hasLength(1));
      expect(sentPermissions.first, {'userId': 'u1', 'type': 'ALL'});
      expect((sentPermissions.first as Map).containsKey('userName'), isFalse);
    });

    test('targetAccountNo와 auditEnabled가 request body에 포함된다', () async {
      Map<String, dynamic>? capturedData;
      final repo = build((o) {
        capturedData = Map<String, dynamic>.from(o.data as Map);
        return MockReply(200, {});
      });

      await repo.requestPermissionChange(
        targetAccountNo: 'ACC-XYZ',
        auditEnabled: false,
        permissions: [],
      );

      expect(capturedData!['targetAccountNo'], 'ACC-XYZ');
      expect(capturedData!['auditEnabled'], false);
    });

    test('permissions가 여러 개일 때 각각 {userId, type}으로 매핑된다', () async {
      Map<String, dynamic>? capturedData;
      final repo = build((o) {
        capturedData = Map<String, dynamic>.from(o.data as Map);
        return MockReply(200, {});
      });

      const perms = [
        Permission(userId: 'u1', userName: '홍길동', type: 'ALL'),
        Permission(userId: 'u2', userName: '김철수', type: 'VIEW'),
      ];
      await repo.requestPermissionChange(
        targetAccountNo: 'ACC001',
        auditEnabled: true,
        permissions: perms,
      );

      final sentPermissions = capturedData!['permissions'] as List;
      expect(sentPermissions, hasLength(2));
      expect(sentPermissions[0], {'userId': 'u1', 'type': 'ALL'});
      expect(sentPermissions[1], {'userId': 'u2', 'type': 'VIEW'});
    });

    test('에러: 400 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '잘못된 요청입니다.'}));

      await expectLater(
        repo.requestPermissionChange(
          targetAccountNo: 'ACC001',
          auditEnabled: true,
          permissions: [],
        ),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', '잘못된 요청입니다.'),
        ),
      );
    });
  });

  // ==========================================================================
  // 5. searchUserForPermission() — GET /users/search
  //    핵심 특수 케이스:
  //    - 404 → null 반환 (에러가 아님)
  //    - 404 외 DioException → ApiErrorHandler.parse → AppException
  //    - 비-DioException(파싱 오류) → AppException("데이터 처리 중 오류가 발생했습니다.")
  // ==========================================================================
  group('searchUserForPermission()', () {
    test('성공(200): User 객체를 반환한다', () async {
      final repo = build((o) => MockReply(200, {'data': userJson()}));

      final result = await repo.searchUserForPermission('u1');

      expect(result, isNotNull);
      expect(result!.userId, 'u1');
      expect(result.name, '홍길동');
    });

    test('요청 쿼리에 userId가 포함된다', () async {
      String? capturedUserId;
      final repo = build((o) {
        capturedUserId = o.queryParameters['userId'] as String?;
        return MockReply(200, {'data': userJson()});
      });

      await repo.searchUserForPermission('testUser');

      expect(capturedUserId, 'testUser');
    });

    test('요청 경로가 /users/search 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': userJson()});
      });

      await repo.searchUserForPermission('u1');

      expect(calledPath, '/users/search');
    });

    test('[404→null] 404 응답이면 null을 반환한다 (throw 아님)', () async {
      // 핵심: 사용자를 찾지 못한 경우 예외 대신 null 반환
      final repo = build(respondsWith(404, {'message': 'User not found'}));

      final result = await repo.searchUserForPermission('unknown_user');

      expect(result, isNull);
    });

    test('에러: 404 외 DioException(500)이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': '서버 오류'}));

      await expectLater(
        repo.searchUserForPermission('u1'),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', '서버 오류'),
        ),
      );
    });

    test('에러: 403 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(403, {'message': null}));

      await expectLater(
        repo.searchUserForPermission('u1'),
        throwsA(isA<AppException>()),
      );
    });

    test('에러: 연결 타임아웃이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.searchUserForPermission('u1'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });

    test(
      '[비-DioException] 응답 파싱 실패(data가 Map이 아님)이면 "데이터 처리 중 오류" AppException을 throw한다',
      () async {
        // data가 String이면 User.fromJson(String) → TypeError(비-DioException)
        // → catch(e) 블록에서 AppException("데이터 처리 중 오류가 발생했습니다.") throw
        final repo = build(
          (o) => MockReply(200, {'data': 'invalid_not_a_map'}),
        );

        await expectLater(
          repo.searchUserForPermission('u1'),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              '데이터 처리 중 오류가 발생했습니다.',
            ),
          ),
        );
      },
    );
  });

  // ==========================================================================
  // 6. getPermissions() — GET /accounts/{accountNumber}/permissions
  //    핵심 검증: 경로에 accountNumber가 포함됨
  // ==========================================================================
  group('getPermissions()', () {
    test('성공: AccountAuthorityResponse를 파싱해 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {'data': authorityResponseJson()}),
      );

      final result = await repo.getPermissions(accountNumber: 'ACC001');

      expect(result.accountNumber, 'ACC001');
      expect(result.isAuditorAllowed, true);
      expect(result.isPending, false);
      expect(result.permissions.length, 1);
      expect(result.permissions.first.userId, 'u1');
      expect(result.permissions.first.type, 'ALL');
    });

    test('[경로 포함] 요청 경로에 accountNumber가 삽입된다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': authorityResponseJson()});
      });

      await repo.getPermissions(accountNumber: 'ACC001');

      expect(calledPath, '/accounts/ACC001/permissions');
    });

    test('다른 accountNumber를 쓰면 경로도 다르다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {
          'data': {...authorityResponseJson(), 'accountNumber': '9999-0000'},
        });
      });

      await repo.getPermissions(accountNumber: '9999-0000');

      expect(calledPath, '/accounts/9999-0000/permissions');
    });

    test('에러: 404 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(404, {'message': null}));

      await expectLater(
        repo.getPermissions(accountNumber: 'ACC001'),
        throwsA(isA<AppException>()),
      );
    });

    test('에러: 연결 타임아웃이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.getPermissions(accountNumber: 'ACC001'),
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

  // ==========================================================================
  // 7. createPersonalAccount() — POST /accounts/createPersonal
  // ==========================================================================
  group('createPersonalAccount()', () {
    test('성공: 정상 응답이면 예외 없이 완료된다', () async {
      final repo = build((o) => MockReply(200, {'success': true}));

      await expectLater(
        repo.createPersonalAccount(
          accountName: '내 계좌',
          isAuditorAllowed: false,
        ),
        completes,
      );
    });

    test('요청 경로가 /accounts/createPersonal 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {});
      });

      await repo.createPersonalAccount(
        accountName: '내 계좌',
        isAuditorAllowed: false,
      );

      expect(calledPath, '/accounts/createPersonal');
    });

    test('accountName과 isAuditorAllowed가 request body에 포함된다', () async {
      Map<String, dynamic>? capturedData;
      final repo = build((o) {
        capturedData = Map<String, dynamic>.from(o.data as Map);
        return MockReply(200, {});
      });

      await repo.createPersonalAccount(
        accountName: '급여계좌',
        isAuditorAllowed: true,
      );

      expect(capturedData!['accountName'], '급여계좌');
      expect(capturedData!['isAuditorAllowed'], true);
    });

    test('에러: 409 응답이면 서버 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(409, {'message': '이미 존재하는 계좌입니다.'}));

      await expectLater(
        repo.createPersonalAccount(
          accountName: '중복계좌',
          isAuditorAllowed: false,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '이미 존재하는 계좌입니다.',
          ),
        ),
      );
    });

    test('에러: 연결 에러이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.createPersonalAccount(accountName: '계좌', isAuditorAllowed: false),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('연결할 수 없습니다'),
          ),
        ),
      );
    });

    test('에러: 서버 500이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      await expectLater(
        repo.createPersonalAccount(accountName: '계좌', isAuditorAllowed: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==========================================================================
  // 8. fetchMyAccounts() — GET /accounts/accountList
  // ==========================================================================
  group('fetchMyAccounts()', () {
    test('성공: AccountResponse를 파싱해 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {'data': accountResponseJson()}),
      );

      final result = await repo.fetchMyAccounts();

      expect(result.summary.totalCount, 1);
      expect(result.list.length, 1);
      expect(result.list.first.accountNumber, '1234-5678');
    });

    test('요청 경로가 /accounts/accountList 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.fetchMyAccounts();

      expect(calledPath, '/accounts/accountList');
    });

    test('쿼리에 page가 전달된다', () async {
      int? capturedPage;
      final repo = build((o) {
        capturedPage = o.queryParameters['page'] as int?;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.fetchMyAccounts(page: 2);

      expect(capturedPage, 2);
    });

    test('쿼리의 limit이 AppConfig.defaultLimit(20)이다', () async {
      int? capturedLimit;
      final repo = build((o) {
        capturedLimit = o.queryParameters['limit'] as int?;
        return MockReply(200, {'data': accountResponseJson()});
      });

      await repo.fetchMyAccounts();

      expect(capturedLimit, AppConfig.defaultLimit); // 20
    });

    test('에러: 500 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      await expectLater(repo.fetchMyAccounts(), throwsA(isA<AppException>()));
    });

    test('에러: 연결 타임아웃이면 AppException을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.fetchMyAccounts(),
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
