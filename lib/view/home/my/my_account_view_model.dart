import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tbank_user/model/user_profile_model.dart';
import '../../../repository/account_repository.dart';
import '../../../repository/response/account_response.dart';
import '../../../util/app_config.dart';
import '../../base_view_model.dart';
import 'my_account_view_state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 화면을 벗어나면(pop) 상태를 초기화하여,
// 다시 들어왔을 때 최신 데이터로 새로 시작할 수 있게 합니다.
final myAccountViewModelProvider = NotifierProvider.autoDispose<MyAccountViewModel, AccountViewState>(
    MyAccountViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class MyAccountViewModel extends BaseViewModel<AccountViewState> {
  // 토큰 등 저장을 위한 스토리지 (현재 로직에서는 직접 사용되지 않으나 초기화됨)
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  @override
  AccountViewState build() {
    // 초기 상태 반환 (로딩 X, 에러 X)
    return const AccountViewState(isBusy: false, isError: false, errorMessage: "", isHeaderRefreshing: false);
  }

  // ---------------------------------------------------------------------------
  // [기능 1] 새로고침 (Refresh / Pull-to-Refresh)
  // 프로필 정보와 계좌 목록(1페이지)을 새로 불러와 상태를 '교체'합니다.
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    // 이미 로딩 중이면 중복 요청 방지
    if (state.isBusy) return;

    // isHeaderRefreshing: true -> 상단 로딩 인디케이터 표시용
    state = state.copyWith(isBusy: true, isHeaderRefreshing: true);

    try {
      // 1. 내 프로필 정보 조회 (이름, 관리자 여부 등)
      final UserProfileModel userProfileModel = await ref.read(accountRepositoryProvider).getMyProfile();

      // 2. 내 계좌 목록 조회 (무조건 1페이지)
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .fetchMyAccounts(page: 1);

      final newItems = result.list;

      // (선택) 로딩 깜빡임 방지 딜레이
      await Future.delayed(AppConfig.minLoadingDuration);

      // 3. 상태 업데이트 (리스트 교체 및 프로필 정보 갱신)
      state = state.copyWith(
        // 프로필 정보 업데이트
        isAdmin: userProfileModel.isAdmin,
        isAuditor: userProfileModel.isAuditor,
        userId: userProfileModel.userId,
        userName: userProfileModel.name,

        // 상태 플래그 끄기
        isBusy: false,
        isHeaderRefreshing: false,

        // 계좌 리스트 교체 (덮어쓰기)
        accounts: newItems,
        totalCount: result.summary.totalCount,
        page: 1,
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(
          isError: true,
          isHeaderRefreshing: false,
          isBusy: false,
          errorMessage: "데이터 로드 실패: $e"
      );
    }
  }

  // ---------------------------------------------------------------------------
  // [기능 2] 더보기 (Load More / 무한 스크롤)
  // 다음 페이지의 계좌 목록을 불러와 기존 리스트 뒤에 '추가'합니다.
  // ---------------------------------------------------------------------------
  Future<void> loadMore() async {
    // 로딩 중이거나, 더 이상 가져올 데이터(hasMore)가 없으면 리턴
    if (state.isBusy || !state.hasMore) return;

    try {
      // 하단 로딩 스피너 표시용
      state = state.copyWith(isBusy: true, isError: false, errorMessage: null);

      await Future.delayed(AppConfig.minLoadingDuration);

      // 1. 다음 페이지 번호 계산
      final nextPage = state.page + 1;

      // 2. 계좌 목록 조회 (다음 페이지)
      final AccountResponse result = await ref
          .read(accountRepositoryProvider)
          .fetchMyAccounts(page: nextPage);

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