import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user.dart';
import 'package:tbank_user/repository/auth_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';

import 'mock_dio.dart';

// =============================================================================
// AuthRepository 단위 테스트
//
// 대상 메서드:
//   - sendVerificationCode(email)  : POST /auth/send-code  (try/catch 없음 → DioException 그대로 throw)
//   - verifyEmailCode(email, code) : POST /auth/verify-code (try/catch 없음 → DioException 그대로 throw)
//   - signup(...)                  : POST /users/signup    (try/catch 있음 → AppException throw)
//   - login(...)                   : POST /users/login     (try/catch 있음 → AppException throw)
// =============================================================================

void main() {
  // Repository 생성 헬퍼 — Provider 없이 Dio 직접 주입
  AuthRepository build(MockHandler handler) =>
      AuthRepository(buildMockDio(handler));

  // ============================================================================
  // sendVerificationCode()
  // ============================================================================
  group('sendVerificationCode() — 정상 응답', () {
    test('200 응답이면 정상 완료(void)된다', () async {
      final repo = build((o) => MockReply(200, {'success': true}));
      await expectLater(repo.sendVerificationCode('test@test.com'), completes);
    });

    test('요청 경로가 /auth/send-code 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'success': true});
      });
      await repo.sendVerificationCode('test@test.com');
      expect(calledPath, '/auth/send-code');
    });

    test('요청 body에 email이 포함된다', () async {
      dynamic sentData;
      final repo = build((o) {
        sentData = o.data;
        return MockReply(200, {'success': true});
      });
      await repo.sendVerificationCode('user@bank.com');
      expect((sentData as Map)['email'], 'user@bank.com');
    });
  });

  // try/catch 없음 → DioException이 그대로 throw됨 (AppException 아님)
  group(
    'sendVerificationCode() — 에러 계약 (try/catch 없음: DioException throw)',
    () {
      test('400 응답이면 DioException(badResponse)을 throw한다', () async {
        final repo = build(respondsWith(400, {'message': '이메일 형식이 잘못되었습니다.'}));
        await expectLater(
          repo.sendVerificationCode('bad-email'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.badResponse,
            ),
          ),
        );
      });

      test('500 응답이면 DioException(badResponse)을 throw한다', () async {
        final repo = build(respondsWith(500, {'message': '서버 오류'}));
        await expectLater(
          repo.sendVerificationCode('test@test.com'),
          throwsA(isA<DioException>()),
        );
      });

      test('연결 타임아웃이면 DioException(connectionTimeout)을 throw한다', () async {
        final repo = build(throwsDioType(DioExceptionType.connectionTimeout));
        await expectLater(
          repo.sendVerificationCode('test@test.com'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.connectionTimeout,
            ),
          ),
        );
      });

      test(
        '연결 실패(connectionError)이면 DioException(connectionError)을 throw한다',
        () async {
          final repo = build(throwsDioType(DioExceptionType.connectionError));
          await expectLater(
            repo.sendVerificationCode('test@test.com'),
            throwsA(
              isA<DioException>().having(
                (e) => e.type,
                'type',
                DioExceptionType.connectionError,
              ),
            ),
          );
        },
      );
    },
  );

  // ============================================================================
  // verifyEmailCode()
  // ============================================================================
  group('verifyEmailCode() — 정상 응답', () {
    test('200 응답이면 정상 완료(void)된다', () async {
      final repo = build((o) => MockReply(200, {'success': true}));
      await expectLater(
        repo.verifyEmailCode('test@test.com', '123456'),
        completes,
      );
    });

    test('요청 경로가 /auth/verify-code 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {'success': true});
      });
      await repo.verifyEmailCode('test@test.com', '123456');
      expect(calledPath, '/auth/verify-code');
    });

    test('요청 body에 email과 code가 모두 포함된다', () async {
      dynamic sentData;
      final repo = build((o) {
        sentData = o.data;
        return MockReply(200, {'success': true});
      });
      await repo.verifyEmailCode('user@bank.com', '999888');
      final d = sentData as Map;
      expect(d['email'], 'user@bank.com');
      expect(d['code'], '999888');
    });
  });

  // try/catch 없음 → DioException이 그대로 throw됨 (AppException 아님)
  group('verifyEmailCode() — 에러 계약 (try/catch 없음: DioException throw)', () {
    test('400 응답이면 DioException(badResponse)을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '인증코드가 일치하지 않습니다.'}));
      await expectLater(
        repo.verifyEmailCode('test@test.com', 'wrong'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
    });

    test('연결 타임아웃이면 DioException(connectionTimeout)을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));
      await expectLater(
        repo.verifyEmailCode('test@test.com', '123456'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionTimeout,
          ),
        ),
      );
    });

    test(
      '연결 실패(connectionError)이면 DioException(connectionError)을 throw한다',
      () async {
        final repo = build(throwsDioType(DioExceptionType.connectionError));
        await expectLater(
          repo.verifyEmailCode('test@test.com', '123456'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.connectionError,
            ),
          ),
        );
      },
    );
  });

  // ============================================================================
  // signup()
  // ============================================================================
  group('signup() — 정상 응답', () {
    test('200 응답이면 res.data[\'data\']를 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'success': true,
          'message': '회원가입 성공',
          'data': {'userId': 'newuser', 'accountNumber': '123-456'},
        }),
      );

      final result = await repo.signup(
        userId: 'newuser',
        name: '홍길동',
        email: 'hong@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
        isAuditorAllowed: false,
      );

      expect(result['userId'], 'newuser');
      expect(result['accountNumber'], '123-456');
    });

    test('요청 경로가 /users/signup 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {
          'success': true,
          'data': {'userId': 'u'},
        });
      });

      await repo.signup(
        userId: 'u',
        name: '이름',
        email: 'e@e.com',
        password: 'pw',
        accountName: 'acc',
        isAuditorAllowed: true,
      );

      expect(calledPath, '/users/signup');
    });

    test('요청 body에 6개 필드가 모두 포함된다', () async {
      dynamic sentData;
      final repo = build((o) {
        sentData = o.data;
        return MockReply(200, {'success': true, 'data': {}});
      });

      await repo.signup(
        userId: 'testuser',
        name: '테스터',
        email: 'tester@bank.com',
        password: 'secret',
        accountName: '주거래 계좌',
        isAuditorAllowed: true,
      );

      final d = sentData as Map;
      expect(d['userId'], 'testuser');
      expect(d['name'], '테스터');
      expect(d['email'], 'tester@bank.com');
      expect(d['password'], 'secret');
      expect(d['accountName'], '주거래 계좌');
      expect(d['isAuditorAllowed'], true);
    });
  });

  group('signup() — 에러 계약 (AppException throw)', () {
    test('서버가 message를 주면 그 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '이미 존재하는 아이디입니다.'}));

      await expectLater(
        repo.signup(
          userId: 'dup',
          name: '이름',
          email: 'e@e.com',
          password: 'pw',
          accountName: 'acc',
          isAuditorAllowed: false,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '이미 존재하는 아이디입니다.',
          ),
        ),
      );
    });

    test('500 응답(message 없음)이면 AppException(서버 내부 오류)을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      await expectLater(
        repo.signup(
          userId: 'u',
          name: 'n',
          email: 'e@e.com',
          password: 'pw',
          accountName: 'acc',
          isAuditorAllowed: false,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('서버 내부 오류'),
          ),
        ),
      );
    });

    test('연결 타임아웃이면 AppException(시간 초과 메시지)을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.signup(
          userId: 'u',
          name: 'n',
          email: 'e@e.com',
          password: 'pw',
          accountName: 'acc',
          isAuditorAllowed: false,
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

    test('연결 실패(connectionError)면 AppException(서버 연결 불가)을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.signup(
          userId: 'u',
          name: 'n',
          email: 'e@e.com',
          password: 'pw',
          accountName: 'acc',
          isAuditorAllowed: false,
        ),
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

  // ============================================================================
  // login()
  // ============================================================================
  group('login() — 정상 응답', () {
    test('success=true이면 user(User)와 accessToken을 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 1,
              'userId': 'testuser',
              'name': '홍길동',
              'email': 'hong@test.com',
              'role': 'USER',
            },
            'accessToken': 'jwt-token-xyz',
          },
        }),
      );

      final result = await repo.login(
        id: 'testuser',
        password: 'pass1234',
        getFcmToken: 'fcm-token-abc',
      );

      expect(result['accessToken'], 'jwt-token-xyz');
      expect(result['user'], isA<User>());
      final user = result['user'] as User;
      expect(user.userId, 'testuser');
      expect(user.name, '홍길동');
      expect(user.id, 1);
    });

    test('요청 경로가 /users/login 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 1,
              'userId': 'u',
              'name': 'n',
              'email': 'e@e.com',
              'role': 'USER',
            },
            'accessToken': 'token',
          },
        });
      });

      await repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm');
      expect(calledPath, '/users/login');
    });

    test('요청 body에 userId, password, fcmToken이 포함된다', () async {
      dynamic sentData;
      final repo = build((o) {
        sentData = o.data;
        return MockReply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 1,
              'userId': 'u',
              'name': 'n',
              'email': 'e@e.com',
              'role': 'USER',
            },
            'accessToken': 'token',
          },
        });
      });

      await repo.login(id: 'myid', password: 'mypass', getFcmToken: 'myfcm');

      final d = sentData as Map;
      expect(d['userId'], 'myid');
      expect(d['password'], 'mypass');
      expect(d['fcmToken'], 'myfcm');
    });

    test('User 객체가 올바르게 파싱된다 (ADMIN role 포함)', () async {
      final repo = build(
        (o) => MockReply(200, {
          'success': true,
          'data': {
            'user': {
              'id': 42,
              'userId': 'admin_user',
              'name': '관리자',
              'email': 'admin@bank.com',
              'role': 'ADMIN',
            },
            'accessToken': 'admin-token',
          },
        }),
      );

      final result = await repo.login(
        id: 'admin_user',
        password: 'adminpass',
        getFcmToken: 'fcm',
      );

      final user = result['user'] as User;
      expect(user.id, 42);
      expect(user.role, 'ADMIN');
      expect(user.email, 'admin@bank.com');
    });
  });

  // success=false 또는 success 키 누락 → AppException("서버 응답이 올바르지 않습니다.")
  // 내부에서 throw AppException(...)이 catch에 걸려 ApiErrorHandler.parse 경유.
  // ApiErrorHandler는 AppException을 그대로 반환하므로 동일 메시지가 유지된다.
  group('login() — success=false / 비정상 응답 (AppException throw)', () {
    test(
      'success=false이면 AppException("서버 응답이 올바르지 않습니다.")을 throw한다',
      () async {
        final repo = build(
          (o) => MockReply(200, {'success': false, 'data': {}}),
        );

        await expectLater(
          repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm'),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              '서버 응답이 올바르지 않습니다.',
            ),
          ),
        );
      },
    );

    test('success 키가 없으면 AppException("서버 응답이 올바르지 않습니다.")을 throw한다', () async {
      final repo = build((o) => MockReply(200, {'data': {}}));

      await expectLater(
        repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '서버 응답이 올바르지 않습니다.',
          ),
        ),
      );
    });
  });

  group('login() — HTTP/네트워크 에러 계약 (AppException throw)', () {
    test('401 응답(message 없음)이면 AppException(로그인 정보 만료)을 throw한다', () async {
      final repo = build(respondsWith(401, {'message': null}));

      await expectLater(
        repo.login(id: 'u', password: 'wrong', getFcmToken: 'fcm'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('로그인 정보가 만료'),
          ),
        ),
      );
    });

    test('서버가 message를 주면 그 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '비밀번호가 틀립니다.'}));

      await expectLater(
        repo.login(id: 'u', password: 'wrong', getFcmToken: 'fcm'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '비밀번호가 틀립니다.',
          ),
        ),
      );
    });

    test('500 응답(message 없음)이면 AppException(서버 내부 오류)을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      await expectLater(
        repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('서버 내부 오류'),
          ),
        ),
      );
    });

    test('연결 타임아웃이면 AppException(시간 초과 메시지)을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });

    test('연결 실패(connectionError)면 AppException(서버 연결 불가)을 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.login(id: 'u', password: 'pw', getFcmToken: 'fcm'),
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
}
