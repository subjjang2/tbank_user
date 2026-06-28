import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/authority/authority_view.state.dart';
import 'package:tbank_user/view/authority/authority_view_model.dart';

// =============================================================================
// Fake AccountRepository
// authority_view_model이 사용하는 3개 메서드만 제어하고, 나머지는 stub.
//   - searchUserForPermission : 검색 결과(User?) 또는 예외
//   - getPermissions          : 초기 권한 응답 또는 예외
//   - requestPermissionChange : 저장 성공/예외 + 전달된 인자 캡처
// =============================================================================
class FakeAccountRepository implements AccountRepository {
  // --- searchUserForPermission 제어 ---
  User? searchUserResult;
  Object? searchUserThrow;

  // --- getPermissions 제어 ---
  AccountAuthorityResponse? permissionsResult;
  Object? getPermissionsThrow;

  // --- requestPermissionChange 제어 + 인자 캡처 ---
  Object? requestThrow;
  String? lastTargetAccountNo;
  bool? lastAuditEnabled;
  List<Permission>? lastPermissions;

  FakeAccountRepository({
    this.searchUserResult,
    this.searchUserThrow,
    this.permissionsResult,
    this.getPermissionsThrow,
    this.requestThrow,
  });

  @override
  Future<User?> searchUserForPermission(String userId) async {
    if (searchUserThrow != null) throw searchUserThrow!;
    return searchUserResult;
  }

  @override
  Future<AccountAuthorityResponse> getPermissions({
    required String accountNumber,
  }) async {
    if (getPermissionsThrow != null) throw getPermissionsThrow!;
    return permissionsResult ??
        const AccountAuthorityResponse(accountNumber: '110-000');
  }

  @override
  Future<void> requestPermissionChange({
    required String targetAccountNo,
    required bool auditEnabled,
    required List<Permission> permissions,
  }) async {
    lastTargetAccountNo = targetAccountNo;
    lastAuditEnabled = auditEnabled;
    lastPermissions = permissions;
    if (requestThrow != null) throw requestThrow!;
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
  Future<void> createPersonalAccount({
    required String accountName,
    required bool isAuditorAllowed,
  }) => throw UnimplementedError();

  @override
  Future<AccountResponse> fetchMyAccounts({int page = 1}) =>
      throw UnimplementedError();
}

User _user(String userId, String name) => User(userId: userId, name: name);

Permission _perm(String userId, String name, String type) =>
    Permission(userId: userId, userName: name, type: type);

ProviderContainer buildContainer(FakeAccountRepository repo) {
  return ProviderContainer(
    overrides: [accountRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  AuthorityViewModel readVm(ProviderContainer c) =>
      c.read(accountAuthorityViewModelProvider.notifier);
  AccountAuthorityState readState(ProviderContainer c) =>
      c.read(accountAuthorityViewModelProvider);

  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy/isError=false, errorMessage 빈 문자열, permissions 빈 리스트', () {
      container = buildContainer(FakeAccountRepository());
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
      expect(s.isSuccess, isFalse);
      expect(s.permissions, isEmpty);
      expect(s.isAuditorAllowed, isTrue); // 기본값 true
      expect(s.isPending, isFalse);
    });
  });

  // ==========================================================================
  group('toggleAudit()', () {
    test('false로 토글하면 isAuditorAllowed=false', () async {
      container = buildContainer(FakeAccountRepository());
      final vm = readVm(container);

      await vm.toggleAudit(false);

      expect(readState(container).isAuditorAllowed, isFalse);
    });

    test('true로 다시 토글하면 isAuditorAllowed=true', () async {
      container = buildContainer(FakeAccountRepository());
      final vm = readVm(container);

      await vm.toggleAudit(false);
      await vm.toggleAudit(true);

      expect(readState(container).isAuditorAllowed, isTrue);
    });
  });

  // ==========================================================================
  group('fetchPermissions() — 초기 데이터 로드', () {
    test('성공 시 서버 응답으로 isAuditorAllowed/permissions/isPending 반영', () async {
      final repo = FakeAccountRepository(
        permissionsResult: AccountAuthorityResponse(
          accountNumber: '110-1',
          isAuditorAllowed: false,
          isPending: true,
          permissions: [_perm('u1', '김철수', 'VIEW')],
        ),
      );
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.fetchPermissions('110-1');
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isAuditorAllowed, isFalse);
      expect(s.isPending, isTrue);
      expect(s.permissions, hasLength(1));
      expect(s.permissions.first.userId, 'u1');
      expect(s.isError, isFalse);
    });

    test('실패 시 isError=true, errorMessage 설정, isBusy=false', () async {
      final repo = FakeAccountRepository(
        getPermissionsThrow: AppException('조회 실패'),
      );
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.fetchPermissions('110-1');
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '조회 실패');
      expect(s.isBusy, isFalse);
      expect(s.isSuccess, isFalse);
    });
  });

  // ==========================================================================
  group('searchAndAddUser() — 사용자 검색 후 추가', () {
    test('신규 사용자 검색 성공 시 permissions에 추가된다 (CASE B)', () async {
      final repo = FakeAccountRepository(searchUserResult: _user('u1', '김철수'));
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'VIEW');
      final s = readState(container);

      expect(s.permissions, hasLength(1));
      expect(s.permissions.first.userId, 'u1');
      expect(s.permissions.first.userName, '김철수');
      expect(s.permissions.first.type, 'VIEW');
      expect(s.isSuccess, isTrue);
      expect(s.isBusy, isFalse);
    });

    test('이미 존재하는 사용자면 권한 타입만 수정된다 (CASE A, 중복 추가 안 됨)', () async {
      // 1차: VIEW 권한으로 추가
      final repo = FakeAccountRepository(searchUserResult: _user('u1', '김철수'));
      container = buildContainer(repo);
      final vm = readVm(container);
      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'VIEW');

      // 2차: 동일 유저를 ALL 권한으로 재검색
      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'ALL');
      final s = readState(container);

      expect(s.permissions, hasLength(1)); // 중복 추가 X
      expect(s.permissions.first.type, 'ALL'); // 타입만 갱신
    });

    test(
      '사용자를 찾지 못하면(null) userSearchErrorMessage 설정, permissions 변화 없음',
      () async {
        final repo = FakeAccountRepository(searchUserResult: null);
        container = buildContainer(repo);
        final vm = readVm(container);

        await vm.searchAndAddUser(
          targetUserId: 'ghost',
          permissionType: 'VIEW',
        );
        final s = readState(container);

        expect(s.userSearchErrorMessage, contains('사용자를 찾을 수 없습니다'));
        expect(s.permissions, isEmpty);
        expect(s.isBusy, isFalse);
      },
    );

    test('검색 호출이 예외를 던지면 isError=true, errorMessage 설정', () async {
      final repo = FakeAccountRepository(
        searchUserThrow: AppException('네트워크 오류'),
      );
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'VIEW');
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '네트워크 오류');
      expect(s.isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('removeUser() — 로컬 삭제', () {
    test('지정한 userId가 permissions에서 제거된다', () async {
      final repo = FakeAccountRepository(searchUserResult: _user('u1', '김철수'));
      container = buildContainer(repo);
      final vm = readVm(container);
      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'VIEW');
      expect(readState(container).permissions, hasLength(1));

      vm.removeUser('u1');

      expect(readState(container).permissions, isEmpty);
    });

    test('존재하지 않는 userId 삭제는 목록을 변경하지 않는다', () async {
      final repo = FakeAccountRepository(searchUserResult: _user('u1', '김철수'));
      container = buildContainer(repo);
      final vm = readVm(container);
      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'VIEW');

      vm.removeUser('nope');

      expect(readState(container).permissions, hasLength(1));
    });
  });

  // ==========================================================================
  group('submitChanges() — 변경사항 저장', () {
    test('성공 시 true 반환, isSuccess=true, isBusy=false', () async {
      final repo = FakeAccountRepository();
      container = buildContainer(repo);
      final vm = readVm(container);

      final result = await vm.submitChanges('110-1');
      final s = readState(container);

      expect(result, isTrue);
      expect(s.isSuccess, isTrue);
      expect(s.isBusy, isFalse);
    });

    test('현재 state의 isAuditorAllowed/permissions가 Repository로 전달된다', () async {
      final repo = FakeAccountRepository(searchUserResult: _user('u1', '김철수'));
      container = buildContainer(repo);
      final vm = readVm(container);
      await vm.toggleAudit(false);
      await vm.searchAndAddUser(targetUserId: 'u1', permissionType: 'ALL');

      await vm.submitChanges('110-9');

      expect(repo.lastTargetAccountNo, '110-9');
      expect(repo.lastAuditEnabled, isFalse);
      expect(repo.lastPermissions, hasLength(1));
      expect(repo.lastPermissions!.first.userId, 'u1');
    });

    test(
      '실패 시 false 반환, isError=true, errorMessage 설정, isBusy=false',
      () async {
        final repo = FakeAccountRepository(requestThrow: AppException('저장 실패'));
        container = buildContainer(repo);
        final vm = readVm(container);

        final result = await vm.submitChanges('110-1');
        final s = readState(container);

        expect(result, isFalse);
        expect(s.isError, isTrue);
        expect(s.errorMessage, '저장 실패');
        expect(s.isBusy, isFalse);
      },
    );
  });
}
