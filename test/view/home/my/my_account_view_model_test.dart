import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/home/my/my_account_view_model.dart';
import 'package:tbank_user/view/home/my/my_account_view_state.dart';

// =============================================================================
// 테스트 헬퍼 — 데이터 생성
// =============================================================================
Account _fakeAccount(int id) => Account(
  id: id,
  accountName: '테스트계좌$id',
  accountNumber: '111-$id',
  balance: '10000',
  type: 'PERSONAL',
  status: 'ACTIVE',
  owner: const User(userId: 'u1', name: '테스트유저'),
);

AccountResponse _responseWith(List<Account> list, {int totalCount = 0}) =>
    AccountResponse(
      summary: AccountSummary(
        totalBalance: '0',
        totalCount: totalCount,
        totalPage: 1,
        currentPage: 1,
      ),
      list: list,
    );

AccountResponse _emptyResponse() => const AccountResponse(
  summary: AccountSummary(
    totalBalance: '0',
    totalCount: 0,
    totalPage: 1,
    currentPage: 1,
  ),
);

// =============================================================================
// Fake AccountRepository
// MyAccountViewModel이 사용하는 getMyProfile / fetchMyAccounts만 구현
// =============================================================================
class FakeMyAccountRepository implements AccountRepository {
  UserProfileModel? profileResult;
  Object? profileThrow;
  AccountResponse? accountsResult;
  Object? accountsThrow;
  int getMyProfileCallCount = 0;
  int fetchMyAccountsCallCount = 0;

  FakeMyAccountRepository({
    this.profileResult,
    this.profileThrow,
    this.accountsResult,
    this.accountsThrow,
  });

  @override
  Future<UserProfileModel> getMyProfile() async {
    getMyProfileCallCount++;
    if (profileThrow != null) throw profileThrow!;
    return profileResult ??
        UserProfileModel(userId: 'u01', name: '홍길동', role: 'USER');
  }

  @override
  Future<AccountResponse> fetchMyAccounts({int page = 1}) async {
    fetchMyAccountsCallCount++;
    if (accountsThrow != null) throw accountsThrow!;
    return accountsResult ?? _emptyResponse();
  }

  // ─── 미사용 메서드 stubs ──────────────────────────────────────────────────
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
  Future<void> createPersonalAccount({
    required String accountName,
    required bool isAuditorAllowed,
  }) => throw UnimplementedError();
}

// =============================================================================
// ProviderContainer 빌더
// autoDispose notifier가 비동기 대기 중 폐기되지 않도록 listen으로 keep-alive
// =============================================================================
ProviderContainer buildContainer({FakeMyAccountRepository? repo}) {
  final c = ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(
        repo ?? FakeMyAccountRepository(),
      ),
    ],
  );
  // Future.delayed(AppConfig.minLoadingDuration) 실행 중 notifier 폐기 방지
  c.listen(myAccountViewModelProvider, (_, __) {});
  return c;
}

MyAccountViewModel readVm(ProviderContainer c) =>
    c.read(myAccountViewModelProvider.notifier);

AccountViewState readState(ProviderContainer c) =>
    c.read(myAccountViewModelProvider);

// =============================================================================
void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy=false, isError=false, errorMessage 빈 문자열, 계좌 목록 빈 리스트', () {
      container = buildContainer();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
      expect(s.isHeaderRefreshing, isFalse);
      expect(s.accounts, isEmpty);
      expect(s.page, 1);
      expect(s.totalCount, 0);
    });
  });

  // ==========================================================================
  group('refresh() — 성공', () {
    test('계좌 목록과 프로필 정보가 상태에 반영된다', () async {
      final accounts = [_fakeAccount(1), _fakeAccount(2)];
      final repo = FakeMyAccountRepository(
        profileResult: UserProfileModel(
          userId: 'u01',
          name: '홍길동',
          role: 'USER',
        ),
        accountsResult: _responseWith(accounts, totalCount: 5),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();
      final s = readState(container);

      expect(s.accounts, hasLength(2));
      expect(s.totalCount, 5);
      expect(s.page, 1);
      expect(s.userName, '홍길동');
      expect(s.userId, 'u01');
      expect(s.isAdmin, isFalse);
      expect(s.isAuditor, isFalse);
      expect(s.isBusy, isFalse);
      expect(s.isHeaderRefreshing, isFalse);
      expect(s.isError, isFalse);
    });

    test('role=ADMIN이면 isAdmin=true로 업데이트된다', () async {
      final repo = FakeMyAccountRepository(
        profileResult: UserProfileModel(
          userId: 'admin01',
          name: '관리자',
          role: 'ADMIN',
        ),
        accountsResult: _emptyResponse(),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();

      expect(readState(container).isAdmin, isTrue);
      expect(readState(container).isAuditor, isFalse);
    });

    test('role=AUDITOR이면 isAuditor=true로 업데이트된다', () async {
      final repo = FakeMyAccountRepository(
        profileResult: UserProfileModel(
          userId: 'aud01',
          name: '감찰관',
          role: 'AUDITOR',
        ),
        accountsResult: _emptyResponse(),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();

      expect(readState(container).isAuditor, isTrue);
      expect(readState(container).isAdmin, isFalse);
    });
  });

  // ==========================================================================
  group('refresh() — isBusy 가드', () {
    test('이미 로딩 중이면 두 번째 refresh()를 무시한다 (getMyProfile 1회만 호출)', () async {
      final repo = FakeMyAccountRepository(accountsResult: _emptyResponse());
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // 첫 호출: await 없이 시작 → 동기 구간에서 isBusy=true 설정 후 suspend
      final firstCall = vm.refresh();
      // 두 번째 호출: guard에 걸려 즉시 리턴
      await vm.refresh();
      await firstCall;

      // 실제로 API를 1회만 호출했는지 callCount로 검증
      expect(repo.getMyProfileCallCount, 1);
    });
  });

  // ==========================================================================
  group('refresh() — 에러 처리', () {
    test('getMyProfile AppException → isError=true, errorMessage 설정', () async {
      final repo = FakeMyAccountRepository(
        profileThrow: AppException('프로필 조회 실패'),
        accountsResult: _emptyResponse(),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.isBusy, isFalse);
      expect(s.isHeaderRefreshing, isFalse);
      expect(s.errorMessage, '데이터 로드 실패: 프로필 조회 실패');
    });

    test(
      'fetchMyAccounts AppException → isError=true, errorMessage 설정',
      () async {
        final repo = FakeMyAccountRepository(
          accountsThrow: AppException('계좌 조회 실패'),
        );
        container = buildContainer(repo: repo);

        await readVm(container).refresh();
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.isBusy, isFalse);
        expect(s.isHeaderRefreshing, isFalse);
        expect(s.errorMessage, '데이터 로드 실패: 계좌 조회 실패');
      },
    );

    test(
      '일반 Exception → isError=true, errorMessage에 Exception 문자열 포함',
      () async {
        final repo = FakeMyAccountRepository(
          profileThrow: Exception('네트워크 오류'),
        );
        container = buildContainer(repo: repo);

        await readVm(container).refresh();
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.isBusy, isFalse);
        // Exception.toString()은 "Exception: <message>" 형식
        expect(s.errorMessage, contains('데이터 로드 실패:'));
      },
    );
  });

  // ==========================================================================
  group('loadMore() — hasMore=false 가드', () {
    test(
      '초기 상태(accounts=[], totalCount=0)에서 loadMore()를 호출하면 아무 변화 없다',
      () async {
        container = buildContainer();
        final vm = readVm(container);

        await vm.loadMore();
        final s = readState(container);

        expect(s.isBusy, isFalse);
        expect(s.accounts, isEmpty);
      },
    );
  });

  // ==========================================================================
  group('loadMore() — 성공 (페이지 병합)', () {
    test('다음 페이지 데이터를 기존 리스트 뒤에 병합하고 page가 증가한다', () async {
      final page1Accounts = [_fakeAccount(1), _fakeAccount(2)];
      final repo = FakeMyAccountRepository(
        accountsResult: _responseWith(page1Accounts, totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // 1. refresh()로 초기 데이터 로드 → hasMore=true (2 < 10)
      await vm.refresh();
      expect(readState(container).accounts, hasLength(2));
      expect(readState(container).hasMore, isTrue);

      // 2. loadMore() → 같은 fake가 page2도 2개 반환 → 병합
      await vm.loadMore();
      final s = readState(container);

      expect(s.accounts, hasLength(4));
      expect(s.page, 2);
      expect(s.totalCount, 10);
      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });
  });

  // ==========================================================================
  group('loadMore() — isBusy 가드', () {
    test('이미 로딩 중이면 두 번째 loadMore()를 무시한다', () async {
      final repo = FakeMyAccountRepository(
        accountsResult: _responseWith([_fakeAccount(1)], totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // refresh()로 hasMore=true 상태 진입
      await vm.refresh();
      expect(readState(container).hasMore, isTrue);

      final callCountBefore = repo.fetchMyAccountsCallCount;

      // 두 호출을 거의 동시에 시작 → 두 번째는 guard에 걸림
      final first = vm.loadMore();
      await vm.loadMore(); // guard triggered
      await first;

      // loadMore 전용 호출: callCountBefore+1 이어야 함 (두 번째 무시)
      expect(repo.fetchMyAccountsCallCount, callCountBefore + 1);
    });
  });

  // ==========================================================================
  group('loadMore() — 에러 처리', () {
    test('AppException 발생 시 errorMessage 설정, isBusy=false', () async {
      final repo = FakeMyAccountRepository(
        accountsResult: _responseWith([_fakeAccount(1)], totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // refresh()로 hasMore=true 진입
      await vm.refresh();

      // 이후 loadMore()에서 오류 발생하도록 throw 설정
      repo.accountsThrow = AppException('추가 로드 서버 오류');
      await vm.loadMore();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      // loadMore catch는 isError를 설정하지 않으므로 false 유지
      expect(s.isError, isFalse);
      expect(s.errorMessage, '추가 로드 실패: 추가 로드 서버 오류');
    });
  });
}
