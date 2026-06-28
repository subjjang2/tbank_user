import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/auth_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/register/register_view_model.dart';
import 'package:tbank_user/view/register/register_view_state.dart';

// =============================================================================
// Fake AuthRepository
// signup() 제어. 나머지 메서드(login)는 UnimplementedError stub.
// =============================================================================
class FakeAuthRepository implements AuthRepository {
  Object? signupThrow;
  bool signupCalled = false;
  Map<String, dynamic>? lastSignupArgs;

  FakeAuthRepository({this.signupThrow});

  @override
  Future<Map<String, dynamic>> signup({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String accountName,
    required bool isAuditorAllowed,
  }) async {
    signupCalled = true;
    lastSignupArgs = {
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'accountName': accountName,
      'isAuditorAllowed': isAuditorAllowed,
    };
    if (signupThrow != null) throw signupThrow!;
    return {};
  }

  // RegisterViewModel은 sendVerificationCode/verifyEmailCode를 직접 호출하지 않으므로
  // 실제 로직 없이 빈 구현 제공 (Repository 인터페이스 충족)
  @override
  Future<void> sendVerificationCode(String email) async {}

  @override
  Future<void> verifyEmailCode(String email, String code) async {}

  @override
  Future<Map<String, dynamic>> login({
    required String id,
    required String password,
    required String getFcmToken,
  }) {
    throw UnimplementedError();
  }
}

// =============================================================================
// 헬퍼: ProviderContainer 빌드
// autoDispose 방지를 위해 registerViewModelProvider에 리스너 등록 필수.
// =============================================================================
ProviderContainer buildContainer({FakeAuthRepository? fakeRepo}) {
  final c = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        fakeRepo ?? FakeAuthRepository(),
      ),
    ],
  );
  // autoDispose 유지: 비동기 실행 중 notifier 폐기 방지
  c.listen(registerViewModelProvider, (_, __) {});
  return c;
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  RegisterViewModel readVm(ProviderContainer c) =>
      c.read(registerViewModelProvider.notifier);
  RegisterViewState readState(ProviderContainer c) =>
      c.read(registerViewModelProvider);

  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy/isError=false, errorMessage 빈 문자열, isAuditorAllowed=true', () {
      container = buildContainer();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
      expect(s.isAuditorAllowed, isTrue);
      expect(s.codeSent, isFalse);
      expect(s.showVerificationUI, isFalse);
      expect(s.codeSentOk, isTrue);
    });
  });

  // ==========================================================================
  group('toggleAuditorAllowed()', () {
    test('false로 호출하면 isAuditorAllowed=false로 변경된다', () {
      container = buildContainer();
      final vm = readVm(container);

      vm.toggleAuditorAllowed(false);

      expect(readState(container).isAuditorAllowed, isFalse);
    });

    test('true로 재호출하면 isAuditorAllowed=true로 복원된다', () {
      container = buildContainer();
      final vm = readVm(container);

      vm.toggleAuditorAllowed(false);
      vm.toggleAuditorAllowed(true);

      expect(readState(container).isAuditorAllowed, isTrue);
    });

    test('null을 전달하면 상태가 변경되지 않는다', () {
      container = buildContainer();
      final vm = readVm(container);

      vm.toggleAuditorAllowed(false); // 먼저 false로 변경
      vm.toggleAuditorAllowed(null); // null → 아무 변화 없음

      expect(readState(container).isAuditorAllowed, isFalse);
    });
  });

  // ==========================================================================
  group('sendVerificationCode() — 플레이스홀더', () {
    test('null을 반환한다 (성공으로 처리)', () async {
      container = buildContainer();
      final vm = readVm(container);

      final result = await vm.sendVerificationCode('test@test.com');

      expect(result, isNull);
    });
  });

  // ==========================================================================
  group('verifyEmailCode() — 플레이스홀더', () {
    test('예외 없이 정상 완료된다', () async {
      container = buildContainer();
      final vm = readVm(container);

      // 예외가 발생하지 않으면 테스트 통과
      await vm.verifyEmailCode('test@test.com', '123456');
    });
  });

  // ==========================================================================
  group('signup() — 성공', () {
    test('성공 시 null을 반환한다', () async {
      container = buildContainer();
      final vm = readVm(container);

      final result = await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(result, isNull);
    });

    test('성공 후 isBusy=false로 해제된다', () async {
      container = buildContainer();
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(readState(container).isBusy, isFalse);
    });

    test('signup()은 state.isError/errorMessage를 변경하지 않는다 (초기값 유지)', () async {
      // 설계 문서화: signup()의 에러 정보는 반환값(String?)으로만 전달되며,
      // state.isError / state.errorMessage 는 업데이트하지 않는다.
      container = buildContainer();
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );
      final s = readState(container);

      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
    });
  });

  // ==========================================================================
  group('signup() — AppException 처리', () {
    test('AppException 발생 시 e.message 문자열이 반환된다', () async {
      final repo = FakeAuthRepository(
        signupThrow: AppException('이미 사용 중인 아이디입니다.'),
      );
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      final result = await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(result, '이미 사용 중인 아이디입니다.');
    });

    test('AppException 발생 후에도 isBusy=false로 해제된다', () async {
      final repo = FakeAuthRepository(signupThrow: AppException('오류'));
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(readState(container).isBusy, isFalse);
    });

    test('AppException 발생 시 state.isError는 변경되지 않는다', () async {
      // signup()은 catch 블록에서 state.isError를 설정하지 않는다.
      final repo = FakeAuthRepository(signupThrow: AppException('오류'));
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(readState(container).isError, isFalse);
    });
  });

  // ==========================================================================
  group('signup() — 일반 예외 처리', () {
    test('일반 Exception 발생 시 "Exception: message" 형식의 String이 반환된다', () async {
      final repo = FakeAuthRepository(signupThrow: Exception('네트워크 오류'));
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      final result = await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(result, 'Exception: 네트워크 오류');
    });

    test('일반 예외 발생 후에도 isBusy=false로 해제된다', () async {
      final repo = FakeAuthRepository(signupThrow: Exception('서버 오류'));
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(readState(container).isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('signup() — isAuditorAllowed 상태 전달', () {
    test('기본값(true) 상태에서 signup 호출 시 true가 Repository로 전달된다', () async {
      final repo = FakeAuthRepository();
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.signup(
        userId: 'user1',
        name: '홍길동',
        email: 'test@test.com',
        password: 'pass1234',
        accountName: '내 계좌',
      );

      expect(repo.lastSignupArgs?['isAuditorAllowed'], isTrue);
    });

    test(
      'toggleAuditorAllowed(false) 후 signup 호출 시 false가 Repository로 전달된다',
      () async {
        final repo = FakeAuthRepository();
        container = buildContainer(fakeRepo: repo);
        final vm = readVm(container);

        vm.toggleAuditorAllowed(false);
        await vm.signup(
          userId: 'user1',
          name: '홍길동',
          email: 'test@test.com',
          password: 'pass1234',
          accountName: '내 계좌',
        );

        expect(repo.lastSignupArgs?['isAuditorAllowed'], isFalse);
      },
    );

    test('signup 인자가 Repository로 그대로 전달된다', () async {
      final repo = FakeAuthRepository();
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.signup(
        userId: 'myuser',
        name: '김철수',
        email: 'kim@test.com',
        password: 'secret',
        accountName: '급여 계좌',
      );

      expect(repo.lastSignupArgs?['userId'], 'myuser');
      expect(repo.lastSignupArgs?['name'], '김철수');
      expect(repo.lastSignupArgs?['email'], 'kim@test.com');
      expect(repo.lastSignupArgs?['password'], 'secret');
      expect(repo.lastSignupArgs?['accountName'], '급여 계좌');
    });
  });
}
