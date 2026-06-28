import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/create_account/create_account_view_model.dart';
import 'package:tbank_user/view/create_account/create_account_view_state.dart';

// =============================================================================
// Fake AccountRepository
// createPersonalAccount() 제어. 나머지 메서드는 UnimplementedError stub.
// =============================================================================
class FakeAccountRepository implements AccountRepository {
  Object? createAccountThrow;
  bool createAccountCalled = false;
  Map<String, dynamic>? lastCreateArgs;

  FakeAccountRepository({this.createAccountThrow});

  @override
  Future<void> createPersonalAccount({
    required String accountName,
    required bool isAuditorAllowed,
  }) async {
    createAccountCalled = true;
    lastCreateArgs = {
      'accountName': accountName,
      'isAuditorAllowed': isAuditorAllowed,
    };
    if (createAccountThrow != null) throw createAccountThrow!;
  }

  // ---- 사용하지 않는 메서드 stub ----
  @override
  Future<UserProfileModel> getMyProfile() => throw UnimplementedError();

  @override
  Future<AccountResponse> getAccessibleAccounts({
    int page = 1,
    int limit = 10,
  }) => throw UnimplementedError();

  @override
  Future<AccountResponse> getViewerAccounts({int page = 1, int limit = 10}) =>
      throw UnimplementedError();

  @override
  Future<void> requestPermissionChange({
    required String targetAccountNo,
    required bool auditEnabled,
    required List<Permission> permissions,
  }) => throw UnimplementedError();

  @override
  Future<User?> searchUserForPermission(String userId) =>
      throw UnimplementedError();

  @override
  Future<AccountAuthorityResponse> getPermissions({
    required String accountNumber,
  }) => throw UnimplementedError();

  @override
  Future<AccountResponse> fetchMyAccounts({int page = 1}) =>
      throw UnimplementedError();
}

// =============================================================================
// 헬퍼: ProviderContainer 빌드
// autoDispose 방지를 위해 createAccountViewModelProvider에 리스너 등록 필수.
// =============================================================================
ProviderContainer buildContainer({FakeAccountRepository? fakeRepo}) {
  final c = ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(
        fakeRepo ?? FakeAccountRepository(),
      ),
    ],
  );
  // autoDispose 유지: 비동기 실행 중 notifier 폐기 방지
  c.listen(createAccountViewModelProvider, (_, __) {});
  return c;
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  CreateAccountViewModel readVm(ProviderContainer c) =>
      c.read(createAccountViewModelProvider.notifier);
  CreateAccountState readState(ProviderContainer c) =>
      c.read(createAccountViewModelProvider);

  // ==========================================================================
  group('초기 상태 (build)', () {
    test(
      'isBusy/isError=false, errorMessage 빈 문자열, isSuccess=false, isAuditorAllowed=true',
      () {
        container = buildContainer();
        final s = readState(container);

        expect(s.isBusy, isFalse);
        expect(s.isError, isFalse);
        expect(s.errorMessage, isEmpty);
        expect(s.isSuccess, isFalse);
        expect(s.isAuditorAllowed, isTrue);
      },
    );
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
  });

  // ==========================================================================
  group('createAccount() — 성공', () {
    test('성공 시 null을 반환한다', () async {
      container = buildContainer();
      final vm = readVm(container);

      final result = await vm.createAccount(accountName: '테스트 계좌');

      expect(result, isNull);
    });

    test('성공 후 isSuccess=true, isBusy=false, isError=false', () async {
      container = buildContainer();
      final vm = readVm(container);

      await vm.createAccount(accountName: '테스트 계좌');
      final s = readState(container);

      expect(s.isSuccess, isTrue);
      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });
  });

  // ==========================================================================
  group('createAccount() — AppException 처리', () {
    test('AppException 발생 시 e.message 문자열이 반환된다', () async {
      final repo = FakeAccountRepository(
        createAccountThrow: AppException('계좌 개설에 실패했습니다.'),
      );
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      final result = await vm.createAccount(accountName: '테스트 계좌');

      expect(result, '계좌 개설에 실패했습니다.');
    });

    test(
      'AppException 발생 시 isError=true, errorMessage=e.message, isSuccess=false, isBusy=false',
      () async {
        final repo = FakeAccountRepository(
          createAccountThrow: AppException('계좌 개설에 실패했습니다.'),
        );
        container = buildContainer(fakeRepo: repo);
        final vm = readVm(container);

        await vm.createAccount(accountName: '테스트 계좌');
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, '계좌 개설에 실패했습니다.');
        expect(s.isSuccess, isFalse);
        expect(s.isBusy, isFalse);
      },
    );
  });

  // ==========================================================================
  group('createAccount() — 일반 예외 처리', () {
    test('일반 Exception 발생 시 "Exception: message" 형식의 String이 반환된다', () async {
      final repo = FakeAccountRepository(
        createAccountThrow: Exception('네트워크 오류'),
      );
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      final result = await vm.createAccount(accountName: '테스트 계좌');

      expect(result, 'Exception: 네트워크 오류');
    });

    test(
      '일반 예외 발생 시 isError=true, errorMessage="Exception: message", isBusy=false',
      () async {
        final repo = FakeAccountRepository(
          createAccountThrow: Exception('서버 오류'),
        );
        container = buildContainer(fakeRepo: repo);
        final vm = readVm(container);

        await vm.createAccount(accountName: '테스트 계좌');
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, 'Exception: 서버 오류');
        expect(s.isBusy, isFalse);
        expect(s.isSuccess, isFalse);
      },
    );
  });

  // ==========================================================================
  group('createAccount() — isBusy 해제 보장', () {
    test('성공 후에도 isBusy=false이다', () async {
      container = buildContainer();
      final vm = readVm(container);

      await vm.createAccount(accountName: '테스트 계좌');

      expect(readState(container).isBusy, isFalse);
    });

    test('AppException 발생 후에도 isBusy=false이다', () async {
      final repo = FakeAccountRepository(
        createAccountThrow: AppException('오류'),
      );
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.createAccount(accountName: '테스트 계좌');

      expect(readState(container).isBusy, isFalse);
    });

    test('일반 예외 발생 후에도 isBusy=false이다', () async {
      final repo = FakeAccountRepository(createAccountThrow: Exception('오류'));
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.createAccount(accountName: '테스트 계좌');

      expect(readState(container).isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('createAccount() — 인자 및 isAuditorAllowed 전달', () {
    test(
      '기본값(true) 상태에서 호출 시 isAuditorAllowed=true가 Repository로 전달된다',
      () async {
        final repo = FakeAccountRepository();
        container = buildContainer(fakeRepo: repo);
        final vm = readVm(container);

        await vm.createAccount(accountName: '테스트 계좌');

        expect(repo.lastCreateArgs?['isAuditorAllowed'], isTrue);
      },
    );

    test(
      'toggleAuditorAllowed(false) 후 호출 시 isAuditorAllowed=false가 Repository로 전달된다',
      () async {
        final repo = FakeAccountRepository();
        container = buildContainer(fakeRepo: repo);
        final vm = readVm(container);

        vm.toggleAuditorAllowed(false);
        await vm.createAccount(accountName: '테스트 계좌');

        expect(repo.lastCreateArgs?['isAuditorAllowed'], isFalse);
      },
    );

    test('accountName이 Repository로 그대로 전달된다', () async {
      final repo = FakeAccountRepository();
      container = buildContainer(fakeRepo: repo);
      final vm = readVm(container);

      await vm.createAccount(accountName: '급여 통장');

      expect(repo.lastCreateArgs?['accountName'], '급여 통장');
    });
  });
}
