import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/account_repository.dart';
import '../../repository/response/account_search/account_searchtype_response.dart';
import '../../repository/system_repository.dart';
import '../../repository/transfer_repository.dart';
import '../../util/helper/app_exception.dart';
import '../base_view_model.dart';
import 'account_info_view_state.dart';


// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 이체 화면을 나가면 조회했던 예금주 정보 등을 메모리에서 해제합니다.
final accountInfoViewModelProvider = NotifierProvider.autoDispose<AccountInfoViewModel, AccountInfoViewState>(
    AccountInfoViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class AccountInfoViewModel extends BaseViewModel<AccountInfoViewState> {


  @override
  AccountInfoViewState build() {
    // 초기 상태 (로딩 X, 에러 X)
    return const AccountInfoViewState(isBusy: false, isError: false, errorMessage: '');
  }

  /// --------------------------------------------------------------------------
  /// 🔹 [계좌 실명 조회]
  /// 입력받은 계좌번호로 서버에 예금주 정보를 요청합니다.
  /// --------------------------------------------------------------------------
  Future<void> accountInfo(String accountNumber) async {

    // 1. 로딩 시작 & 상태 초기화
    // (이전 조회 결과나 에러 메시지가 남아있지 않도록 정리)
    state = state.copyWith(
      isBusy: true,
      errorMessage: null,
      isError: false,
    );

    try {
      // 2. Repository 호출 (계좌 조회 API)
      // type: AccountSearchType.info -> 단순 정보 조회용
      AccountSearchResponse? accountSearchResponse = await ref
          .read(transRepositoryProvider)
          .searchAccount(accountNumber: accountNumber, type: AccountSearchType.info);

      // 3. 성공 시 상태 업데이트
      if (accountSearchResponse != null) {
        state = state.copyWith(
          isBusy: false,
          accountSearchResponse: accountSearchResponse, // 조회된 예금주 정보 저장
        );
      }

    } on AppException catch (e) {
      // 4. 비즈니스 로직 에러 (예: 존재하지 않는 계좌)
      state = state.copyWith(errorMessage: e.message, isBusy: false, isError: true);

    } catch (e) {
      // 5. 시스템 에러 (네트워크 오류 등)
      state = state.copyWith(
          isBusy: false,
          errorMessage: "서버 통신 중 오류가 발생했습니다.",
          isError: true
      );
    }
  }
}