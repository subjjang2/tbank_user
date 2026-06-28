import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import 'package:tbank_user/repository/account_repository.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/home/view/viewer_view.dart';

// =============================================================================
// 목적: 조회권한(조회 탭) 로드 실패 시 "에러 UI가 노출되는가?"를 화면 단에서 검증.
//   - viewer_view.dart 에 에러 분기(_buildBody)와 SnackBar 리스너를 추가한 뒤의 회귀 가드.
// =============================================================================

class ThrowingAccountRepository implements AccountRepository {
  @override
  Future<AccountResponse> getViewerAccounts({
    int page = 1,
    int limit = 10,
  }) async {
    throw AppException('서버 연결 실패');
  }

  // ---- 미사용 stub ----
  @override
  Future<UserProfileModel> getMyProfile() => throw UnimplementedError();
  @override
  Future<AccountResponse> getAccessibleAccounts({
    int page = 1,
    int limit = 10,
  }) => throw UnimplementedError();
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
  testWidgets('조회권한 계좌 로드 실패 시 에러 화면("데이터를 불러올 수 없습니다.")이 노출되어야 한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            ThrowingAccountRepository(),
          ),
        ],
        child: const MaterialApp(home: ViewerAccountsView()),
      ),
    );

    // initState 의 postFrameCallback -> refresh() -> repo throw -> 에러 상태 반영
    await tester.pumpAndSettle();

    expect(
      find.textContaining('데이터를 불러올 수 없습니다'),
      findsOneWidget,
      reason: '로드 실패 시 에러 화면이 떠야 한다 (accounts.isEmpty && isError 분기).',
    );
    // '다시 시도' 버튼도 함께 노출
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
