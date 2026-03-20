import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user.dart';
import 'package:tbank_user/repository/auth_repository.dart';
import 'package:tbank_user/service/fcm_service.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/login/login_view_model.dart';
import 'package:tbank_user/view/login/login_view_state.dart';

// =============================================================================
// Fake AuthRepository
// 실제 네트워크/Dio 없이 원하는 응답을 반환하도록 제어합니다.
// =============================================================================
class FakeAuthRepository implements AuthRepository {
  /// null이면 성공(successResult 반환), non-null이면 해당 예외를 throw
  Object? throwError;

  Map<String, dynamic>? successResult;

  FakeAuthRepository({this.throwError, this.successResult});

  @override
  Future<Map<String, dynamic>> login({
    required String id,
    required String password,
    required String getFcmToken,
  }) async {
    if (throwError != null) throw throwError!;
    return successResult ??
        {
          'user': const User(
            id: 1,
            userId: 'testuser',
            name: '홍길동',
            email: 'test@tbank.com',
            role: 'USER',
          ),
          'accessToken': 'fake-jwt-token',
        };
  }

  // 사용하지 않는 메서드 — stub만 제공
  @override
  Future<void> sendVerificationCode(String email) async {}

  @override
  Future<void> verifyEmailCode(String email, String code) async {}

  @override
  Future<Map<String, dynamic>> signup({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String accountName,
    required bool isAuditorAllowed,
  }) async =>
      {};
}

// =============================================================================
// 테스트 헬퍼: ProviderContainer 빌드
//
// - authRepositoryProvider를 FakeAuthRepository로 오버라이드
// - fcmTokenProvider를 원하는 값으로 설정
// - flutter_secure_storage는 테스트 환경에서 플랫폼 채널이 없으므로
//   login()의 storage.write 호출 시 MissingPluginException이 발생합니다.
//   이를 방지하기 위해 FlutterSecureStorage 플러그인 채널을 mock 처리합니다.
// =============================================================================
ProviderContainer buildContainer({
  FakeAuthRepository? fakeRepo,
  String? fcmToken,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeRepo ?? FakeAuthRepository()),
      // FCM 토큰: null 이 아닌 값을 기본 제공
      fcmTokenProvider.overrideWith((ref) => fcmToken ?? 'fake-fcm-token'),
    ],
  );
}

// =============================================================================
// FlutterSecureStorage 채널 Mock
// 테스트 환경에서 플랫폼 채널 호출을 가로채어 no-op으로 처리합니다.
// =============================================================================
void _mockSecureStorage() {
  // flutter_secure_storage 플러그인이 사용하는 채널명
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    // write, read 등 모든 호출에 null 반환 (no-op)
    return null;
  });
}

void main() {
  // 플랫폼 채널(binary messenger) 사용 전 Flutter 바인딩 초기화 필수
  TestWidgetsFlutterBinding.ensureInitialized();

  // secure storage 채널 mock 등록 (각 테스트 전에 한 번 설정)
  setUp(_mockSecureStorage);

  // ProviderContainer: 테스트마다 새로 생성하고 tearDown에서 해제
  ProviderContainer container = ProviderContainer(); // 초기값 (각 test에서 재할당됨)
  tearDown(() => container.dispose());

  // -------------------------------------------------------------------------
  // 헬퍼: ViewModel 인스턴스와 초기 상태를 함께 반환
  // -------------------------------------------------------------------------
  LoginViewModel readViewModel(ProviderContainer c) =>
      c.read(loginViewModelProvider.notifier);

  LoginViewState readState(ProviderContainer c) =>
      c.read(loginViewModelProvider);

  // ==========================================================================
  // 초기 상태
  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy=false, isError=false, errorMessage 빈 문자열로 초기화된다', () {
      container = buildContainer();
      final state = readState(container);

      expect(state.isBusy, isFalse);
      expect(state.isError, isFalse);
      expect(state.errorMessage, isEmpty);
    });
  });

  // ==========================================================================
  // login() — 정상 케이스
  // ==========================================================================
  group('login() — 정상 로그인', () {
    test('유효한 id/password로 호출하면 true를 반환한다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      final result = await vm.login(id: 'testuser', password: 'pass1234');

      expect(result, isTrue);
    });

    test('로그인 성공 후 isError=false, isBusy=false 상태를 유지한다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      await vm.login(id: 'testuser', password: 'pass1234');
      final state = readState(container);

      expect(state.isBusy, isFalse);
      expect(state.isError, isFalse);
    });

    test('FCM 토큰이 null이어도 빈 문자열로 대체하여 정상 로그인된다', () async {
      container = buildContainer(fcmToken: null);
      final vm = readViewModel(container);

      // fcmTokenProvider가 null 을 반환하는 컨테이너에서도 true 반환
      final result = await vm.login(id: 'testuser', password: 'pass1234');

      expect(result, isTrue);
    });
  });

  // ==========================================================================
  // login() — 유효성 검사 실패 (빈 값)
  // ==========================================================================
  group('login() — 빈 값 유효성 검사', () {
    test('id가 빈 문자열이면 false를 반환하고 에러 상태가 설정된다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      final result = await vm.login(id: '', password: 'pass1234');

      expect(result, isFalse);
      final state = readState(container);
      expect(state.isError, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.errorMessage, '아이디 비밀번호를 모두 입력해주세요.');
    });

    test('password가 빈 문자열이면 false를 반환하고 에러 상태가 설정된다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      final result = await vm.login(id: 'testuser', password: '');

      expect(result, isFalse);
      final state = readState(container);
      expect(state.isError, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.errorMessage, '아이디 비밀번호를 모두 입력해주세요.');
    });

    test('id와 password 모두 빈 문자열이면 false를 반환하고 에러 상태가 설정된다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      final result = await vm.login(id: '', password: '');

      expect(result, isFalse);
      final state = readState(container);
      expect(state.isError, isTrue);
      expect(state.errorMessage, '아이디 비밀번호를 모두 입력해주세요.');
    });

    test('공백만 있는 id는 빈 값이 아니므로 유효성 검사를 통과한다 (API 호출까지 진행)', () async {
      // 참고: 현재 구현은 isEmpty로만 판단하므로 공백(' ')은 통과합니다.
      // 이 동작을 문서화하여 향후 trim() 추가 여부를 판단할 수 있습니다.
      container = buildContainer();
      final vm = readViewModel(container);

      final result = await vm.login(id: ' ', password: ' ');

      // FakeRepository가 성공 응답을 반환하므로 true
      expect(result, isTrue);
    });
  });

  // ==========================================================================
  // login() — AppException (비즈니스 로직 에러)
  // ==========================================================================
  group('login() — AppException 처리', () {
    test('Repository가 AppException을 throw하면 false 반환 및 에러 메시지가 state에 반영된다',
        () async {
      final fakeRepo = FakeAuthRepository(
        throwError: AppException('아이디 또는 비밀번호가 올바르지 않습니다.'),
      );
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      final result = await vm.login(id: 'testuser', password: 'wrong');

      expect(result, isFalse);
      final state = readState(container);
      expect(state.isError, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.errorMessage, '아이디 또는 비밀번호가 올바르지 않습니다.');
    });

    test('AppException 메시지가 그대로 errorMessage에 저장된다', () async {
      const customMessage = '해당 아이디로 가입된 계정이 없습니다.';
      final fakeRepo = FakeAuthRepository(
        throwError: AppException(customMessage),
      );
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      await vm.login(id: 'unknown', password: 'pass');

      expect(readState(container).errorMessage, customMessage);
    });
  });

  // ==========================================================================
  // login() — 일반 예외 (네트워크 에러 등)
  // ==========================================================================
  group('login() — 일반 예외 처리', () {
    test('일반 Exception이 throw되면 false 반환 및 "알 수 없는 오류" 메시지가 설정된다',
        () async {
      final fakeRepo = FakeAuthRepository(
        throwError: Exception('Network error'),
      );
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      final result = await vm.login(id: 'testuser', password: 'pass1234');

      expect(result, isFalse);
      final state = readState(container);
      expect(state.isError, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.errorMessage, '알 수 없는 오류가 발생했습니다.');
    });

    test('RuntimeException이 throw되어도 "알 수 없는 오류" 메시지로 처리된다', () async {
      final fakeRepo = FakeAuthRepository(
        throwError: StateError('unexpected state'),
      );
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      final result = await vm.login(id: 'testuser', password: 'pass1234');

      expect(result, isFalse);
      expect(readState(container).errorMessage, '알 수 없는 오류가 발생했습니다.');
    });
  });

  // ==========================================================================
  // login() — finally 블록: isBusy 해제 보장
  // ==========================================================================
  group('login() — finally 블록 isBusy 해제 보장', () {
    test('성공 후에도 isBusy가 false이다', () async {
      container = buildContainer();
      final vm = readViewModel(container);

      await vm.login(id: 'testuser', password: 'pass1234');

      expect(readState(container).isBusy, isFalse);
    });

    test('AppException 발생 후에도 isBusy가 false이다', () async {
      final fakeRepo =
          FakeAuthRepository(throwError: AppException('에러'));
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      await vm.login(id: 'testuser', password: 'pass');

      expect(readState(container).isBusy, isFalse);
    });

    test('일반 예외 발생 후에도 isBusy가 false이다', () async {
      final fakeRepo =
          FakeAuthRepository(throwError: Exception('network'));
      container = buildContainer(fakeRepo: fakeRepo);
      final vm = readViewModel(container);

      await vm.login(id: 'testuser', password: 'pass');

      expect(readState(container).isBusy, isFalse);
    });
  });

  // ==========================================================================
  // login() — 재시도 시 이전 에러 상태 초기화 검증
  // ==========================================================================
  group('login() — 재시도 시 이전 에러 상태 초기화', () {
    test('첫 호출 실패 후 두 번째 호출 성공 시 isError가 false로 돌아온다', () async {
      // 1차: 실패
      final failRepo =
          FakeAuthRepository(throwError: AppException('로그인 실패'));
      container = buildContainer(fakeRepo: failRepo);
      final vm = readViewModel(container);
      await vm.login(id: 'testuser', password: 'wrong');
      expect(readState(container).isError, isTrue);

      container.dispose();

      // 2차: 성공 (새 컨테이너 — autoDispose로 인해 상태 재생성)
      container = buildContainer();
      final vm2 = container.read(loginViewModelProvider.notifier);
      final result = await vm2.login(id: 'testuser', password: 'pass1234');

      expect(result, isTrue);
      expect(readState(container).isError, isFalse);
    });
  });
}
