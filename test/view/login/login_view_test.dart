import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user.dart';
import 'package:tbank_user/repository/auth_repository.dart';
import 'package:tbank_user/service/fcm_service.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/util/route_path.dart';
import 'package:tbank_user/view/login/login_view.dart';
import 'package:tbank_user/view/login/login_view_model.dart';
import 'package:tbank_user/view/login/login_view_state.dart';

// =============================================================================
// Fake AuthRepository (위젯 테스트용)
// =============================================================================
class FakeAuthRepository implements AuthRepository {
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
// FlutterSecureStorage 채널 Mock
// =============================================================================
void _mockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return null;
  });
}

// =============================================================================
// 테스트 앱 빌더
//
// - ProviderScope에서 필요한 provider를 오버라이드합니다.
// - MaterialApp + onGenerateRoute를 사용하여 Navigator 이동을 검증합니다.
// - 홈 화면 라우트는 빈 Scaffold로 스텁 처리합니다.
// =============================================================================
Widget buildTestApp({
  FakeAuthRepository? fakeRepo,
  String? fcmToken,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider
          .overrideWithValue(fakeRepo ?? FakeAuthRepository()),
      fcmTokenProvider.overrideWith((ref) => fcmToken ?? 'fake-fcm-token'),
    ],
    child: MaterialApp(
      // LoginView를 초기 화면으로 설정
      home: const LoginView(),
      // 라우트 스텁: 이동 여부를 확인하기 위해 간단한 텍스트만 표시
      onGenerateRoute: (settings) {
        if (settings.name == RoutePath.home) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('HomeView')),
          );
        }
        if (settings.name == RoutePath.register) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('RegisterView')),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  setUp(_mockSecureStorage);

  // ==========================================================================
  // 화면 렌더링 — 초기 UI 요소 확인
  // ==========================================================================
  group('LoginView — 초기 렌더링', () {
    testWidgets('T-Bank 로고 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('T-Bank'), findsOneWidget);
    });

    testWidgets('ID / Password 레이블이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('로그인 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('로그인'), findsOneWidget);
    });

    testWidgets('회원가입 링크 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.textContaining('회원가입하기'), findsOneWidget);
    });

    testWidgets('초기 상태에서는 에러 아이콘이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('ID / Password 힌트 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('아이디를 입력하세요'), findsOneWidget);
      expect(find.text('비밀번호를 입력하세요'), findsOneWidget);
    });
  });

  // ==========================================================================
  // 에러 메시지 표시
  // ==========================================================================
  group('LoginView — 에러 메시지 표시', () {
    testWidgets('로그인 실패 시 에러 아이콘과 메시지가 표시된다', (tester) async {
      final fakeRepo = FakeAuthRepository(
        throwError: AppException('아이디 비밀번호를 모두 입력해주세요.'),
      );
      await tester.pumpWidget(buildTestApp(fakeRepo: fakeRepo));
      await tester.pump();

      // 로그인 버튼 탭
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('아이디 비밀번호를 모두 입력해주세요.'), findsOneWidget);
    });

    testWidgets('빈 id/password로 로그인 시 유효성 에러 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // 아무것도 입력하지 않고 로그인 버튼 탭
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('아이디 비밀번호를 모두 입력해주세요.'), findsOneWidget);
    });

    testWidgets('일반 예외 발생 시 "알 수 없는 오류" 메시지가 표시된다', (tester) async {
      final fakeRepo = FakeAuthRepository(
        throwError: Exception('network failure'),
      );
      await tester.pumpWidget(buildTestApp(fakeRepo: fakeRepo));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '아이디를 입력하세요'), 'user');
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호를 입력하세요'), 'pass');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      expect(find.text('알 수 없는 오류가 발생했습니다.'), findsOneWidget);
    });

    testWidgets('에러 메시지는 빨간색으로 표시된다', (tester) async {
      final fakeRepo = FakeAuthRepository(
        throwError: AppException('로그인 실패'),
      );
      await tester.pumpWidget(buildTestApp(fakeRepo: fakeRepo));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '아이디를 입력하세요'), 'user');
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호를 입력하세요'), 'wrong');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(errorIcon.color, Colors.red);
    });

    testWidgets(
        'isError=true이고 errorMessage가 빈 문자열이면 빈 문자열이 그대로 표시된다'
        ' (errorMessage는 non-nullable String이므로 ?? 폴백은 동작하지 않음)',
        (tester) async {
      // loginViewModelProvider를 직접 오버라이드하여 isError=true, errorMessage='' 상태 주입
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginViewModelProvider.overrideWith(() => _ErrorWithEmptyMessageViewModel()),
            fcmTokenProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(home: const LoginView()),
        ),
      );
      await tester.pump();

      // isError=true 이면 에러 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // errorMessage가 '' 이므로 폴백 텍스트는 표시되지 않는다
      // (String은 null이 될 수 없으므로 ?? 연산자는 항상 왼쪽 값을 사용)
      expect(find.text('로그인에 실패했습니다.'), findsNothing);
    });
  });

  // ==========================================================================
  // 로그인 성공 — 화면 이동
  // ==========================================================================
  group('LoginView — 로그인 성공 후 홈 이동', () {
    testWidgets('id/password 입력 후 로그인 성공 시 홈 화면으로 이동한다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '아이디를 입력하세요'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호를 입력하세요'), 'pass1234');
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      // 홈 화면 스텁 텍스트가 표시되어야 한다
      expect(find.text('HomeView'), findsOneWidget);
      // 로그인 화면 버튼이 더 이상 없어야 한다 (pushReplacementNamed)
      expect(find.text('로그인'), findsNothing);
    });
  });

  // ==========================================================================
  // 회원가입 이동
  // ==========================================================================
  group('LoginView — 회원가입 링크', () {
    testWidgets('회원가입 링크 탭 시 회원가입 화면으로 이동한다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.textContaining('회원가입하기'));
      await tester.pumpAndSettle();

      expect(find.text('RegisterView'), findsOneWidget);
    });
  });

  // ==========================================================================
  // 텍스트 입력 — 컨트롤러 연동
  // ==========================================================================
  group('LoginView — 텍스트 필드 입력', () {
    testWidgets('ID 필드에 텍스트를 입력할 수 있다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '아이디를 입력하세요'), 'myid');
      await tester.pump();

      expect(find.text('myid'), findsOneWidget);
    });

    testWidgets('Password 필드에 텍스트를 입력할 수 있다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호를 입력하세요'), 'mypassword');
      await tester.pump();

      expect(find.text('mypassword'), findsOneWidget);
    });

    testWidgets('ID와 Password 필드가 독립적으로 동작한다', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextField, '아이디를 입력하세요'), 'user1');
      await tester.enterText(
          find.widgetWithText(TextField, '비밀번호를 입력하세요'), 'pw1');
      await tester.pump();

      expect(find.text('user1'), findsOneWidget);
      expect(find.text('pw1'), findsOneWidget);
    });
  });
}

// =============================================================================
// 테스트용 ViewModel: isError=true, errorMessage='' 상태를 반환합니다.
// errorMessage는 non-nullable String이므로 ?? 폴백은 실제로 동작하지 않습니다.
// 이 클래스는 그 동작을 문서화하는 테스트에서 사용됩니다.
// =============================================================================
class _ErrorWithEmptyMessageViewModel extends LoginViewModel {
  @override
  LoginViewState build() => const LoginViewState(
        isBusy: false,
        isError: true,
        errorMessage: '',
      );
}
