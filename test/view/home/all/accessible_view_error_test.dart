import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/home/all/accessible_view.dart';

// =============================================================================
// 목적: 공유계좌(전체 탭) 로드 실패 시 "에러 UI가 노출되는가?"를 화면 단에서 검증.
//   - accessible_view.dart 는 _buildBody 에서 (accounts.isEmpty && state.isError)
//     조건으로만 에러 화면을 그린다 (L115).
//   - ViewModel.refresh() catch 는 errorMessage 만 채우고 isError 는 켜지 않는다.
//   => 실패해도 isError=false 라 에러 화면 대신 '빈 계좌' 화면이 뜬다는 가설을 검증.
// =============================================================================

class ThrowingAccountRepository implements AccountRepository {
  @override
  Future<AccountResponse> getAccessibleAccounts({
    int page = 1,
    int limit = 10,
  }) async {
    throw AppException('서버 연결 실패');
  }

  // ---- 미사용 stub ----
  @override
  Future<UserProfileModel> getMyProfile() => throw UnimplementedError();
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
  @override
  Future<AccountResponse> fetchMyAccounts({int page = 1}) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('공유계좌 로드 실패 시 에러 화면("데이터를 불러올 수 없습니다.")이 노출되어야 한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            ThrowingAccountRepository(),
          ),
        ],
        child: const MaterialApp(home: AccessibleAccountsView()),
      ),
    );

    // initState 의 postFrameCallback -> refresh() -> repo throw -> 에러 상태 반영
    await tester.pumpAndSettle();

    // [기대] 로드 실패를 사용자에게 알리는 에러 문구가 보여야 한다.
    expect(
      find.textContaining('데이터를 불러올 수 없습니다'),
      findsOneWidget,
      reason:
          '로드 실패 시 에러 화면이 떠야 하지만, ViewModel.refresh() catch가 '
          'isError를 켜지 않아 에러 화면 조건(accounts.isEmpty && isError)이 false가 된다.',
    );
  });
}
