import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/account_repository.dart';
import '../../repository/response/authority/account_authority_response.dart';
import '../base_view_model.dart';
import 'authority_view.state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 권한 설정 화면을 벗어나면 입력했던 상태들을 초기화합니다.
final accountAuthorityViewModelProvider = NotifierProvider.autoDispose<AuthorityViewModel, AccountAuthorityState>(
    AuthorityViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class AuthorityViewModel extends BaseViewModel<AccountAuthorityState> {

  @override
  AccountAuthorityState build() {
    // 초기 상태 반환 (빈 리스트, 로딩 X)
    return AccountAuthorityState(
        isBusy: false, isError: false, errorMessage: "", isSuccess: false, permissions: []);
  }

  // ---------------------------------------------------------------------------
  // [API] 최종 변경사항 저장 (서버 전송)
  // ---------------------------------------------------------------------------
  Future<bool> submitChanges(String accountNumber) async {
    // 1. 로딩 시작
    state = state.copyWith(isBusy: true, errorMessage: null);

    try {
      // 2. 리포지토리 호출
      // 현재 State에 수정된 감찰 설정(isAuditorAllowed)과 권한 목록(permissions)을 모두 전송
      await ref
          .read(accountRepositoryProvider).requestPermissionChange(
        targetAccountNo: accountNumber,
        auditEnabled: state.isAuditorAllowed,
        permissions: state.permissions,
      );

      // 3. 성공 처리
      state = state.copyWith(isBusy: false, isSuccess: true);
      return true;

    } catch (e) {
      // 4. 실패 처리
      state = state.copyWith(
        isBusy: false,
        isError: true,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // [Local] 감찰부 모니터링 토글
  // 서버 통신 없이 UI 상태만 먼저 변경합니다. (저장 버튼 누를 때 반영)
  // ---------------------------------------------------------------------------
  Future<void> toggleAudit(bool isState) async {
    state = state.copyWith(
      isAuditorAllowed: isState,
    );
  }

  // ---------------------------------------------------------------------------
  // [Hybrid] 사용자 검색 및 로컬 리스트 추가
  // 1. API: ID로 사용자 존재 여부 및 이름 확인
  // 2. Local: 결과가 유효하면 리스트에 추가 또는 수정
  // ---------------------------------------------------------------------------
  Future<void> searchAndAddUser({
    required String targetUserId,
    required String permissionType,
  }) async {
    // 에러 메시지 초기화
    state = state.copyWith(isBusy: true, errorMessage: null, clearUserSearchError: true);

    try {
      // 1. 서버 API 호출 (유저 검색)
      final userDto = await ref
          .read(accountRepositoryProvider)
          .searchUserForPermission(targetUserId);

      // [예외 처리] 사용자가 없는 경우
      if (userDto == null) {
        state = state.copyWith(
          isBusy: false,
          userSearchErrorMessage: " [ 사용자를 찾을 수 없습니다! ]", // UI에 표시할 에러
        );
        return; // 중단
      }

      // 2. 로컬 리스트 업데이트 로직
      final currentList = state.permissions;

      // 이미 목록에 있는지 확인
      final isExist = currentList.any((p) => p.userId == targetUserId);
      List<Permission> updatedList;

      if (isExist) {
        // [CASE A] 이미 존재하면 -> 권한 타입만 수정 (예: 조회 -> 이체)
        updatedList = currentList.map((p) {
          if (p.userId == targetUserId) {
            return p.copyWith(
                type: permissionType,
                userName: userDto.name
            );
          }
          return p;
        }).toList();
      } else {
        // [CASE B] 신규 유저면 -> 리스트에 추가
        final newPermission = Permission(
          userId: userDto.userId,
          userName: userDto.name,
          type: permissionType,
        );
        updatedList = [...currentList, newPermission];
      }

      // 3. 상태 반영 (UI 갱신)
      state = state.copyWith(
        isBusy: false,
        permissions: updatedList,
        isSuccess: true,
      );

    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 초기 데이터 로드
  // 화면 진입 시 서버에 저장된 권한 목록을 불러옵니다.
  // ---------------------------------------------------------------------------
  Future<void> fetchPermissions(String accountNumber) async {
    state = state.copyWith(isBusy: true, errorMessage: null, isSuccess: false, isPending: false);

    try {
      // 1. API 호출
      final result = await ref
          .read(accountRepositoryProvider).getPermissions(accountNumber: accountNumber);

      // 2. 상태 업데이트
      state = state.copyWith(
          isBusy: false,
          isAuditorAllowed: result.isAuditorAllowed, // 감찰 설정
          permissions: result.permissions,           // 권한 목록
          isPending: result.isPending                // 관리자 승인 대기 여부
      );

    } catch (e) {
      state = state.copyWith(isBusy: false, isError: true, errorMessage: e.toString(), isSuccess: false);
    }
  }

  // ---------------------------------------------------------------------------
  // [Local] 사용자 삭제
  // 목록에서 특정 유저를 제거합니다. (서버 전송은 '저장' 버튼 시)
  // ---------------------------------------------------------------------------
  void removeUser(String targetUserId) {
    // 해당 ID를 제외한 나머지 리스트만 남김
    final updatedList = state.permissions
        .where((permission) => permission.userId != targetUserId)
        .toList();

    // 상태 업데이트
    state = state.copyWith(
      permissions: updatedList,
    );
  }
}