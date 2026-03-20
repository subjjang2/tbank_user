import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repository/account_repository.dart';
import '../../../repository/response/account_response.dart';
import '../../../util/app_config.dart';
import '../../base_view_model.dart';
import 'access_state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 화면을 벗어나면 상태(리스트, 페이지 정보 등)를 초기화합니다.
// 다시 들어왔을 때 최신 데이터를 로드하기 위함입니다.
final accessibleAccountsViewModelProvider = NotifierProvider.autoDispose<AccessibleAccountsViewModel, AccessibleAccountsState>(
    AccessibleAccountsViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class AccessibleAccountsViewModel extends BaseViewModel<AccessibleAccountsState> {

  @override
  AccessibleAccountsState build() {
    // 초기 상태 반환 (로딩 X, 에러 X)
    return const AccessibleAccountsState(isBusy: false, isError: false, errorMessage: "", isHeaderRefreshing: false);
  }

  // ---------------------------------------------------------------------------
  // [기능 1] 새로고침 (Pull-to-Refresh)
  // 1페이지부터 데이터를 다시 불러와 기존 리스트를 '교체'합니다.
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isBusy) return;

    // 상단 로딩 인디케이터 표시 시작
    state = state.copyWith(isBusy: true, isHeaderRefreshing: true);

    try {
      // 1. Repository 호출 (무조건 1페이지 요청)
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .getAccessibleAccounts(page: 1);

      final newItems = result.list;

      // (선택) 로딩 깜빡임 방지 딜레이
      await Future.delayed(AppConfig.minLoadingDuration);

      // 2. 상태 업데이트 (리스트 교체)
      state = state.copyWith(
        isBusy: false,
        accounts: newItems, // ✨ 기존 데이터를 버리고 새 데이터로 덮어쓰기
        totalCount: result.summary.totalCount,
        page: 1,            // 페이지 번호 초기화
        isHeaderRefreshing: false,
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
          isHeaderRefreshing: false,
          isBusy: false,
          errorMessage: "데이터 로드 실패: $e"
      );
    }
  }

  // ---------------------------------------------------------------------------
  // [기능 2] 더보기 (무한 스크롤)
  // 다음 페이지 데이터를 불러와 기존 리스트 뒤에 '추가'합니다.
  // ---------------------------------------------------------------------------
  Future<void> loadMore() async {
    // 로딩 중이거나, 더 이상 가져올 데이터(hasMore)가 없으면 중단
    if (state.isBusy || !state.hasMore) return;

    // 하단 로딩 스피너 표시 시작
    state = state.copyWith(isBusy: true);

    await Future.delayed(AppConfig.minLoadingDuration);

    try {
      // 1. 다음 페이지 번호 계산
      final nextPage = state.page + 1;

      // 2. Repository 호출 (다음 페이지)
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .getAccessibleAccounts(page: nextPage);

      // 3. 상태 업데이트 (리스트 병합)
      state = state.copyWith(
        isBusy: false,
        accounts: [...state.accounts, ...result.list], // ✨ [기존 리스트 + 새 리스트] 병합
        totalCount: result.summary.totalCount,
        page: nextPage, // 페이지 번호 증가
      );
    } catch (e) {
      state = state.copyWith(
          isBusy: false,
          errorMessage: "추가 로드 실패: $e"
      );
    }
  }
}