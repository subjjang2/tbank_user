import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/home/all/accessible_view_model.dart';
import 'package:tbank_user/view/home/all/access_state.dart';

// =============================================================================
// 테스트 헬퍼 — 데이터 생성
// =============================================================================
Account _fakeAccount(int id) => Account(
  id: id,
  accountName: '공유계좌$id',
  accountNumber: '222-$id',
  balance: '5000',
  type: 'SHARED',
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
// AccessibleAccountsViewModel이 사용하는 getAccessibleAccounts만 구현
// =============================================================================
class FakeAccessibleRepository implements AccountRepository {
  AccountResponse? accountsResult;
  Object? accountsThrow;
  int getAccessibleCallCount = 0;

  FakeAccessibleRepository({this.accountsResult, this.accountsThrow});

  @override
  Future<AccountResponse> getAccessibleAccounts({
    int page = 1,
    int limit = 10,
  }) async {
    getAccessibleCallCount++;
    if (accountsThrow != null) throw accountsThrow!;
    return accountsResult ?? _emptyResponse();
  }

  // ─── 미사용 메서드 stubs ──────────────────────────────────────────────────
  @override
  Future<UserProfileModel> getMyProfile() => throw UnimplementedError();
  @override
  Future<AccountResponse> fetchMyAccounts({int page = 1}) =>
      throw UnimplementedError();
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
// autoDispose notifier가 Future.delayed 중 폐기되지 않도록 keep-alive
// =============================================================================
ProviderContainer buildContainer({FakeAccessibleRepository? repo}) {
  final c = ProviderContainer(
    overrides: [
      accountRepositoryProvider.overrideWithValue(
        repo ?? FakeAccessibleRepository(),
      ),
    ],
  );
  c.listen(accessibleAccountsViewModelProvider, (_, __) {});
  return c;
}

AccessibleAccountsViewModel readVm(ProviderContainer c) =>
    c.read(accessibleAccountsViewModelProvider.notifier);

AccessibleAccountsState readState(ProviderContainer c) =>
    c.read(accessibleAccountsViewModelProvider);

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
    test('계좌 목록이 교체되고 page=1, totalCount가 반영된다', () async {
      final accounts = [_fakeAccount(1), _fakeAccount(2), _fakeAccount(3)];
      final repo = FakeAccessibleRepository(
        accountsResult: _responseWith(accounts, totalCount: 8),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();
      final s = readState(container);

      expect(s.accounts, hasLength(3));
      expect(s.totalCount, 8);
      expect(s.page, 1);
      expect(s.isBusy, isFalse);
      expect(s.isHeaderRefreshing, isFalse);
      expect(s.isError, isFalse);
    });

    test('빈 응답이 오면 accounts=[], totalCount=0으로 교체된다', () async {
      final repo = FakeAccessibleRepository(accountsResult: _emptyResponse());
      container = buildContainer(repo: repo);

      await readVm(container).refresh();
      final s = readState(container);

      expect(s.accounts, isEmpty);
      expect(s.totalCount, 0);
      expect(s.isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('refresh() — isBusy 가드', () {
    test('이미 로딩 중이면 두 번째 refresh()를 무시한다 (API 1회만 호출)', () async {
      final repo = FakeAccessibleRepository(accountsResult: _emptyResponse());
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // 첫 호출: 동기 구간에서 isBusy=true 설정 후 suspend
      final firstCall = vm.refresh();
      // 두 번째 호출: guard에 걸려 즉시 리턴
      await vm.refresh();
      await firstCall;

      expect(repo.getAccessibleCallCount, 1);
    });
  });

  // ==========================================================================
  group('refresh() — 에러 처리', () {
    test(
      'AppException → errorMessage 설정, isBusy=false, isHeaderRefreshing=false',
      () async {
        // accessible_view_model.dart refresh() catch는 isError=true를 설정한다.
        // (View가 accounts.isEmpty && isError 조건으로 에러 화면을 그린다)
        final repo = FakeAccessibleRepository(
          accountsThrow: AppException('이체가능 계좌 조회 실패'),
        );
        container = buildContainer(repo: repo);

        await readVm(container).refresh();
        final s = readState(container);

        expect(s.isBusy, isFalse);
        expect(s.isHeaderRefreshing, isFalse);
        expect(s.errorMessage, '데이터 로드 실패: 이체가능 계좌 조회 실패');
        // refresh() catch에서 isError=true를 설정한다 (View 에러 UI 트리거 조건)
        expect(s.isError, isTrue);
      },
    );

    test('일반 Exception → errorMessage에 오류 문자열 포함', () async {
      final repo = FakeAccessibleRepository(
        accountsThrow: Exception('timeout'),
      );
      container = buildContainer(repo: repo);

      await readVm(container).refresh();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.errorMessage, contains('데이터 로드 실패:'));
    });
  });

  // ==========================================================================
  group('loadMore() — hasMore=false 가드', () {
    test(
      '초기 상태(accounts=[], totalCount=0)에서 loadMore()를 호출하면 아무 변화 없다',
      () async {
        container = buildContainer();

        await readVm(container).loadMore();
        final s = readState(container);

        expect(s.isBusy, isFalse);
        expect(s.accounts, isEmpty);
      },
    );

    test(
      'accounts.length == totalCount이면 loadMore()를 무시한다 (hasMore=false)',
      () async {
        final repo = FakeAccessibleRepository(
          accountsResult: _responseWith([_fakeAccount(1)], totalCount: 1),
        );
        container = buildContainer(repo: repo);
        final vm = readVm(container);

        // refresh: accounts=[a1], totalCount=1 → hasMore = 1<1 = false
        await vm.refresh();
        expect(readState(container).hasMore, isFalse);

        final callCountBefore = repo.getAccessibleCallCount;
        await vm.loadMore(); // guard: hasMore=false → 즉시 리턴

        expect(repo.getAccessibleCallCount, callCountBefore); // 추가 호출 없음
      },
    );
  });

  // ==========================================================================
  group('loadMore() — 성공 (페이지 병합)', () {
    test('다음 페이지 계좌를 기존 리스트 뒤에 이어붙이고 page가 증가한다', () async {
      final repo = FakeAccessibleRepository(
        accountsResult: _responseWith([
          _fakeAccount(1),
          _fakeAccount(2),
        ], totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      // refresh: accounts=[a1,a2], page=1, hasMore=true (2<10)
      await vm.refresh();
      expect(readState(container).hasMore, isTrue);

      // loadMore: fetches page2 → 같은 fake가 [a1,a2] 반환 → 병합
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
      final repo = FakeAccessibleRepository(
        accountsResult: _responseWith([_fakeAccount(1)], totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      await vm.refresh();
      expect(readState(container).hasMore, isTrue);

      final callCountBefore = repo.getAccessibleCallCount;

      // 참고: AccessibleAccountsViewModel.loadMore()는 isBusy=true를
      // try 블록 밖에서 동기적으로 설정한다
      final first = vm.loadMore();
      await vm.loadMore(); // guard: isBusy=true → 즉시 리턴
      await first;

      expect(repo.getAccessibleCallCount, callCountBefore + 1);
    });
  });

  // ==========================================================================
  group('loadMore() — 에러 처리', () {
    test('AppException 발생 시 errorMessage 설정, isBusy=false', () async {
      final repo = FakeAccessibleRepository(
        accountsResult: _responseWith([_fakeAccount(1)], totalCount: 10),
      );
      container = buildContainer(repo: repo);
      final vm = readVm(container);

      await vm.refresh();

      repo.accountsThrow = AppException('페이지 로드 실패');
      await vm.loadMore();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.errorMessage, '추가 로드 실패: 페이지 로드 실패');
      // loadMore catch에서도 isError=true를 설정한다
      expect(s.isError, isTrue);
    });
  });
}
