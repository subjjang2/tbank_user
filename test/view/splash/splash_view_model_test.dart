import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/view/splash/splash_view_model.dart';
import 'package:tbank_user/view/splash/splash_view_state.dart';

// =============================================================================
// FlutterSecureStorage 채널 Mock
//
// SplashViewModel은 FlutterSecureStorage를 직접 생성(Provider DI 없음)하므로
// 플랫폼 채널을 mock하여 read 반환값을 제어합니다.
//
// [주의]
// - readValue != null → 토큰 있음 (로그인 상태)
// - readValue == null → 토큰 없음 (미로그인)
// - 핸들러를 null로 등록 제거 → MissingPluginException 발생 (에러 경로 테스트)
// =============================================================================
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _setupSecureStorageMock({String? readValue}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'read') {
          return readValue;
        }
        return null;
      });
}

/// 핸들러를 제거하면 채널 호출 시 MissingPluginException이 발생하여
/// checkLoginStatus()의 catch 블록으로 진입합니다.
void _removeMockHandler() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, null);
}

// =============================================================================
// 테스트 헬퍼: ProviderContainer 빌드
// autoDispose 폐기 방지를 위해 리스너를 등록합니다.
// =============================================================================
ProviderContainer buildContainer() {
  final c = ProviderContainer();
  c.listen(splashViewModelProvider, (_, __) {});
  return c;
}

void main() {
  // 플랫폼 채널 바인딩 초기화 필수
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  SplashViewModel readVm(ProviderContainer c) =>
      c.read(splashViewModelProvider.notifier);
  SplashViewState readState(ProviderContainer c) =>
      c.read(splashViewModelProvider);

  // ==========================================================================
  // 초기 상태
  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy=true, isError=false, errorMessage 빈 문자열로 초기화된다', () {
      _setupSecureStorageMock();
      container = buildContainer();
      final s = readState(container);

      // 스플래시는 시작 즉시 로딩 상태(isBusy=true)이다.
      expect(s.isBusy, isTrue);
      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
    });
  });

  // ==========================================================================
  // checkLoginStatus() — 토큰 있음 (로그인 상태)
  // ==========================================================================
  group('checkLoginStatus() — 토큰 있음 (로그인 상태)', () {
    setUp(() {
      _setupSecureStorageMock(readValue: 'valid-jwt-token');
    });

    test('accessToken이 존재하면 true를 반환한다', () async {
      container = buildContainer();
      final result = await readVm(container).checkLoginStatus();

      expect(result, isTrue);
    });

    test('checkLoginStatus 완료 후 isBusy=false, isError=false', () async {
      container = buildContainer();
      await readVm(container).checkLoginStatus();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });

    test('토큰 값이 짧은 문자열이어도 non-null이면 true를 반환한다', () async {
      _setupSecureStorageMock(readValue: 'x');
      container = buildContainer();
      final result = await readVm(container).checkLoginStatus();

      expect(result, isTrue);
    });
  });

  // ==========================================================================
  // checkLoginStatus() — 토큰 없음 (미로그인 상태)
  // ==========================================================================
  group('checkLoginStatus() — 토큰 없음 (미로그인 상태)', () {
    setUp(() {
      // read가 null을 반환 → 토큰 없음
      _setupSecureStorageMock(readValue: null);
    });

    test('accessToken이 없으면 false를 반환한다', () async {
      container = buildContainer();
      final result = await readVm(container).checkLoginStatus();

      expect(result, isFalse);
    });

    test('토큰 없음 완료 후 isBusy=false, isError=false', () async {
      container = buildContainer();
      await readVm(container).checkLoginStatus();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });
  });

  // ==========================================================================
  // checkLoginStatus() — 예외 발생 (storage 오류)
  //
  // 채널 핸들러를 제거(null)하면 MethodChannel이 MissingPluginException을 throw.
  // SplashViewModel의 catch(e) 블록이 이를 잡아 isError=true로 처리합니다.
  // ==========================================================================
  group('checkLoginStatus() — storage 예외 발생', () {
    setUp(() {
      _removeMockHandler();
    });

    test('storage 예외 발생 시 false를 반환한다', () async {
      container = buildContainer();
      final result = await readVm(container).checkLoginStatus();

      expect(result, isFalse);
    });

    test('storage 예외 발생 시 isError=true, isBusy=false', () async {
      container = buildContainer();
      await readVm(container).checkLoginStatus();
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.isBusy, isFalse);
    });

    test('예외 발생 시 errorMessage가 비어있지 않다 (e.toString() 저장)', () async {
      container = buildContainer();
      await readVm(container).checkLoginStatus();

      expect(readState(container).errorMessage, isNotEmpty);
    });
  });

  // ==========================================================================
  // 네비게이션 제외 안내
  // ==========================================================================
  // [제외] SplashView의 네비게이션(Navigator.pushReplacementNamed 등)은
  // navigatorKey.currentState를 통해 위젯 트리에 의존하므로
  // ViewModel 단위 테스트 범위에서는 다루지 않습니다.
  // 해당 라우팅 흐름은 integration_test에서 검증해야 합니다.
}
