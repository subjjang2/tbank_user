import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tbank_user/view/transaction_history/transation_history_view_state.dart';

import '../../repository/transfer_repository.dart';
import '../../util/app_config.dart';
import '../../util/helper/app_exception.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// .family: 외부에서 '계좌번호(String)'를 인자로 받아서 뷰모델을 생성합니다.
// .autoDispose: 화면을 벗어나면 상태를 초기화하여 메모리를 절약합니다.
final transactionViewModelProvider = NotifierProvider.family.autoDispose<
    TransactionViewModel,
    TransactionViewState,
    String
>(TransactionViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
// BaseViewModel 대신 AutoDisposeFamilyNotifier를 상속받아 'arg(계좌번호)'를 처리합니다.
class TransactionViewModel extends AutoDisposeFamilyNotifier<TransactionViewState, String> {

  // 이 뷰모델이 담당하는 계좌번호
  late final String _accountNumber;

  @override
  TransactionViewState build(String arg) {
    // 1. 전달받은 계좌번호 저장
    _accountNumber = arg;

    // 2. 초기 상태 반환 (첫 로딩은 UI의 initState에서 refresh() 호출로 시작됨)
    return TransactionViewState.initial();
  }

  // ---------------------------------------------------------------------------
  // [기능 1] 날짜 필터 적용 (기간 조회)
  // ---------------------------------------------------------------------------
  Future<void> updateDateRange(DateTime? start, DateTime? end, {int? days}) async {
    // 1. 상태 초기화 (검색 조건이 바뀌었으므로 기존 리스트 삭제)
    state = state.copyWith(
      isAllClick: false,    // '전체' 버튼 해제
      startDate: start,     // 시작일
      endDate: end,         // 종료일
      selectedPeriodDays: days,
      transactions: [],     // ✨ 리스트 비우기 (새로운 검색 결과 담을 준비)
      page: 1,              // 1페이지부터 다시 시작
      isBusy: true,         // 로딩 시작 (Lock)
    );

    // 2. 데이터 요청
    await _fetchTransactions();
  }

  // ---------------------------------------------------------------------------
  // [기능 2] 새로고침 (Pull-to-Refresh)
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isBusy) return;

    // 로딩 상태만 켜고 내부적으로 1페이지 요청
    state = state.copyWith(isBusy: true);

    await _fetchTransactions();
  }

  // ---------------------------------------------------------------------------
  // [기능 3] 더보기 (무한 스크롤)
  // ---------------------------------------------------------------------------
  Future<void> loadMore() async {
    // 로딩 중이거나, 더 가져올 데이터가 없으면 중단
    if (state.isBusy || !state.hasMore) return;

    // ✨ 중복 호출 방지를 위해 '로딩 중' 상태로 변경
    state = state.copyWith(isBusy: true);

    // 다음 페이지 요청 (isLoadMore: true)
    await _fetchTransactions(isLoadMore: true);
  }

  // ---------------------------------------------------------------------------
  // [핵심 로직] 통합 데이터 요청 메서드
  // ---------------------------------------------------------------------------
  Future<void> _fetchTransactions({bool isLoadMore = false}) async {
    try {
      // 1. 에러 상태 초기화
      state = state.copyWith(isError: false);

      // 2. 요청할 페이지 계산 (더보기면 현재+1, 아니면 1)
      final requestPage = isLoadMore ? state.page + 1 : 1;

      // (선택) 너무 빠른 로딩 깜빡임 방지용 딜레이
      await Future.delayed(AppConfig.minLoadingDuration);

      // 3. Repository 호출 (API 요청)
      // ✨ State에 저장된 날짜 필터(startDate, endDate)를 그대로 사용 (Source of Truth)
      final result = await ref.read(transRepositoryProvider).fetchHistory(
        _accountNumber,
        page: requestPage,
        limit: AppConfig.defaultLimit,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      // 4. 상태 업데이트
      state = state.copyWith(
        isBusy: false,
        accountName: result.accountName, // 계좌 별칭 업데이트
        balance: result.balance,         // 잔액 업데이트
        totalCount: result.totalCount,   // 전체 데이터 개수 (hasMore 계산용)
        page: requestPage,               // 현재 페이지 업데이트

        // ✨ 리스트 병합 로직
        // 더보기(LoadMore): 기존 리스트 뒤에 새 데이터 붙이기
        // 새로고침/필터: 새 데이터로 덮어쓰기
        transactions: isLoadMore
            ? [...state.transactions, ...result.data]
            : result.data,
      );

    } on AppException catch (e) {
      // 5. 비즈니스 로직 에러 처리 (예: 계좌 없음, 권한 없음)
      print("AppException 발생: ${e.message}");
      state = state.copyWith(
        isBusy: false,
        isError: true,
        errorMessage: e.message,
      );
    } catch (e) {
      // 6. 기타 시스템 에러 처리 (파싱 에러 등)
      state = state.copyWith(
        isBusy: false,
        isError: true,
        errorMessage: "알 수 없는 오류가 발생했습니다.",
      );
    }
  }
}