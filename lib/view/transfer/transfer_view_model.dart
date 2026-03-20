import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/account_repository.dart';
import '../../repository/response/account_search/account_searchtype_response.dart';
import '../../repository/system_repository.dart';
import '../../repository/transfer_repository.dart';
import '../../util/helper/app_exception.dart';
import '../base_view_model.dart';
import 'transfer_view_state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 이체 화면을 나가면 상태를 초기화하여, 다음에 들어올 때 깨끗한 상태로 시작합니다.
final transferViewModelProvider = NotifierProvider.autoDispose<TransferViewModel, TransferViewState>(
    TransferViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class TransferViewModel extends BaseViewModel<TransferViewState> {

  @override
  TransferViewState build() {
    // 초기 상태 설정
    return const TransferViewState(isBusy: false, isError: false, errorMessage: '', isTransferOk: false);
  }

  // ---------------------------------------------------------------------------
  // 🔹 [핵심 기능] 이체 실행
  // ---------------------------------------------------------------------------
  Future<void> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required String amount,
    required String memo,
  }) async {
    // 1. 로딩 시작 & 이전 상태(에러/성공 플래그) 초기화
    state = state.copyWith(
      isBusy: true,
      isError: false,
      isTransferOk: false,
      errorMessage: '',
    );

    try {
      // 2. Repository 호출 (이체 API)
      bool getIsTransferOk = await ref.read(transRepositoryProvider).transfer(
          fromAccountNumber: fromAccountNumber,
          toAccountNumber: toAccountNumber,
          amount: amount,
          memo: memo
      );

      // 3. 성공 여부 상태 업데이트
      state = state.copyWith(
        isBusy: false,
        isTransferOk: getIsTransferOk, // ✨ 화면에서 이 값을 감지해 성공 팝업을 띄움
      );

    } on AppException catch (e) {
      // 4. 비즈니스 로직 에러 (잔액 부족, 계좌 오류 등)
      state = state.copyWith(
        isTransferOk: false,
        isBusy: false,
        isError: true,
        errorMessage: e.message,
      );
    } catch (e) {
      // 5. 기타 시스템 에러
      state = state.copyWith(
        isTransferOk: false,
        isBusy: false,
        isError: true,
        errorMessage: "송금 중 오류가 발생했습니다.",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 [초기 설정] 시스템 수수료 조회
  // ---------------------------------------------------------------------------
  Future<void> fetchSystemConfig() async {
    // 수수료 로딩 상태 표시
    state = state.copyWith(isLoadingFee: true);

    try {
      // Repository에서 설정값 가져오기
      final getFee = await ref.read(systemRepositoryProvider).getSystemConfig();

      if (getFee != null) {
        // 성공 시 수수료 적용
        state = state.copyWith(
          isLoadingFee: false,
          fee: int.tryParse(getFee) ?? 0,
        );
      } else {
        // 실패 시 기본값 0원
        state = state.copyWith(isLoadingFee: false, fee: 0, isError: true);
      }
    } catch (e) {
      state = state.copyWith(isLoadingFee: false, fee: 0, isError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 [검증] 받는 사람 실명 조회
  // ---------------------------------------------------------------------------
  Future<void> checkAccountName(String accountNumber) async {
    // 1. 검증 시작: 로딩 켜기 & 기존에 조회된 이름 지우기(forceClearOwnerName)
    state = state.copyWith(
      isVerifying: true,
      errorMessage: null,
      accountName: null,
      forceClearOwnerName: true,
      isError: false,
    );

    try {
      // 2. Repository 호출 (계좌 조회 API)
      AccountSearchResponse? accountSearchResponse = await ref
          .read(transRepositoryProvider)
          .searchAccount(accountNumber: accountNumber, type: AccountSearchType.check);

      if (accountSearchResponse != null) {
        // 3. 성공 시: 예금주 이름 업데이트 & 로딩 끄기
        state = state.copyWith(
          isVerifying: false,
          accountName: accountSearchResponse.accountName,
        );
      }
    } on AppException catch (e) {
      // 4. 조회 실패 (없는 계좌 등)
      state = state.copyWith(
          errorMessage: e.message,
          isBusy: false,
          isVerifying: false,
          isError: true
      );
    } catch (e) {
      // 5. 통신 에러
      state = state.copyWith(
          isVerifying: false,
          errorMessage: "서버 통신 중 오류가 발생했습니다.",
          isError: true
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 [보조 기능] 이체 금액별 수수료 계산 (시뮬레이션)
  // ---------------------------------------------------------------------------
  Future<void> getTransferFee(int amount) async {
    state = state.copyWith(isLoadingFee: true);
    try {
      // 실제로는 백엔드 로직에 따라 달라질 수 있음 (현재는 0.5초 딜레이 후 500원 고정)
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isLoadingFee: false,
        fee: 500,
      );
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message, isBusy: false, isError: true);
    } catch (e) {
      state = state.copyWith(
          isVerifying: false,
          errorMessage: "서버 통신 중 오류가 발생했습니다.",
          isError: true
      );
    }
  }

  /// 🔹 상태 강제 초기화
  void reset() {
    state = TransferViewState.initial();
  }
}