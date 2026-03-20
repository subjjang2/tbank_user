import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/account_repository.dart';
import '../base_view_model.dart';
import 'create_account_view_state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 계좌 개설 화면을 나가면(pop) 상태를 초기화합니다.
// (다음에 들어올 때 체크박스나 입력값이 초기화된 상태로 시작)
final createAccountViewModelProvider = NotifierProvider.autoDispose<CreateAccountViewModel, CreateAccountState>(
    CreateAccountViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class CreateAccountViewModel extends BaseViewModel<CreateAccountState> {

  @override
  CreateAccountState build() {
    // 초기 상태 반환 (로딩 X, 에러 X, 성공 X)
    return const CreateAccountState(
        isBusy: false, isError: false, errorMessage: "", isSuccess: false);
  }

  // ---------------------------------------------------------------------------
  // [UI 로직] 감찰 허용 체크박스 토글
  // ---------------------------------------------------------------------------
  void toggleAuditorAllowed(bool value) {
    state = state.copyWith(isAuditorAllowed: value);
  }

  // ---------------------------------------------------------------------------
  // [API 로직] 계좌 개설 요청
  // ---------------------------------------------------------------------------
  Future<String?> createAccount({
    required String accountName,
  }) async {
    // 1. 로딩 시작 (UI 잠금 및 에러/성공 상태 초기화)
    state = state.copyWith(isBusy: true, errorMessage: null, isSuccess: false, isError: false);

    try {
      // 2. Repository 호출 (API 요청)
      // state.isAuditorAllowed(체크박스 값)도 함께 전송
      await ref
          .read(accountRepositoryProvider)
          .createPersonalAccount(
        accountName: accountName,
        isAuditorAllowed: state.isAuditorAllowed,
      );

      // 3. 성공 처리
      // isSuccess를 true로 변경하여 View에서 팝업을 띄우거나 화면을 이동하도록 함
      state = state.copyWith(isBusy: false, isSuccess: true);
      return null; // 에러 없음

    } catch (e) {
      // 4. 실패 처리
      state = state.copyWith(
          isBusy: false,
          errorMessage: e.toString(),
          isSuccess: false,
          isError: true
      );
      return e.toString(); // 에러 메시지 반환
    }
  }
}