import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tbank_user/view/home/view/viewer_state.dart';
import '../../../repository/account_repository.dart';
import '../../../repository/response/account_response.dart';
import '../../../util/app_config.dart';
import '../../base_view_model.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 탭을 이동하거나 화면을 벗어나면 상태를 초기화합니다.
// (다시 돌아왔을 때 최신 데이터를 새로 로드하기 위함)
final viewerAccountProvider = NotifierProvider.autoDispose<ViewerAccountsViewModel, ViewerAccountsState>(
    ViewerAccountsViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class ViewerAccountsViewModel extends BaseViewModel<ViewerAccountsState> {

  @override
  ViewerAccountsState build() {
    // 초기 상태: 로딩 X, 에러 X
    return const ViewerAccountsState(isBusy: false, isError: false, errorMessage: "", isHeaderRefreshing: false);
  }

  // ---------------------------------------------------------------------------
  // [기능 1] 새로고침 (Pull-to-Refresh)
  // 동작: 1페이지 데이터를 다시 요청하여 기존 리스트를 '덮어쓰기' 합니다.
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    // 중복 요청 방지
    if (state.isBusy) return;

    // isHeaderRefreshing: true -> 상단 당겨서 새로고침 인디케이터 표시용
    state = state.copyWith(isBusy: true, isHeaderRefreshing: true);

    try {
      // 1. Repository 호출 (무조건 1페이지)
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .getViewerAccounts(page: 1);

      final newItems = result.list;

      // (선택) 로딩 UI 깜빡임 방지용 최소 딜레이
      await Future.delayed(AppConfig.minLoadingDuration);

      // 2. 상태 업데이트 (리스트 교체)
      state = state.copyWith(
        isBusy: false,
        accounts: newItems, // ✨ 기존 데이터 날리고 새 데이터로 교체
        totalCount: result.summary.totalCount,
        page: 1,            // 페이지 1로 초기화
        isHeaderRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
          isHeaderRefreshing: false,
          isBusy: false,
          errorMessage: "데이터 로드 실패: $e"
      );
    }
  }

  // ---------------------------------------------------------------------------
  // [기능 2] 더보기 (무한 스크롤)
  // 동작: 다음 페이지 데이터를 요청하여 기존 리스트 뒤에 '이어붙이기' 합니다.
  // ---------------------------------------------------------------------------
  Future<void> loadMore() async {
    // 로딩 중이거나, 서버에 남은 데이터가 없으면 요청하지 않음
    if (state.isBusy || !state.hasMore) return;

    // 하단 로딩 스피너 표시용 상태 변경
    state = state.copyWith(isBusy: true);

    await Future.delayed(AppConfig.minLoadingDuration);

    try {
      // 1. 다음 페이지 번호 계산
      final nextPage = state.page + 1;

      // 2. Repository 호출
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .getViewerAccounts(page: nextPage);

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