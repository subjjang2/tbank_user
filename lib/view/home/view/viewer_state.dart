import 'package:tbank_user/repository/response/account_response.dart';

import '../../base_view_state.dart';

/// ----------------------------------------------------------------------------
/// [ViewerAccountsState]
/// 조회 권한 계좌 화면(ViewerAccountsView)의 상태를 관리하는 클래스입니다.
/// 계좌 목록 데이터, 페이징 정보, 새로고침 상태 등을 포함합니다.
/// ----------------------------------------------------------------------------
class ViewerAccountsState extends BaseViewState {
  // 1. [데이터 영역]
  final String userId;
  final String userName;
  final List<Account> accounts; // 화면에 표시할 계좌 리스트
  final String totalBalance;    // 총 자산 (서버에서 계산되어 오거나, 앱에서 합산한 값)

  // 2. [페이징 영역]
  final int page;        // 현재 페이지 번호
  final int totalCount;  // 서버 전체 데이터 개수 (무한 스크롤 종료 판단용)

  // 3. [UI 상태 영역]
  // isBusy(전체 로딩)와 별개로, '상단 당겨서 새로고침' 중인지만 판단하는 플래그
  final bool isHeaderRefreshing;

  const ViewerAccountsState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.accounts = const [],
    this.totalBalance = "0",
    this.page = 1,
    this.totalCount = 0,
    this.userId = "",
    this.userName = "",
    this.isHeaderRefreshing = false,
  });

  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  // ---------------------------------------------------------------------------
  // [copyWith] 상태 업데이트 메서드 (불변 객체 유지)
  // 변경할 값만 인자로 넘겨 새로운 상태 객체를 생성합니다.
  // ---------------------------------------------------------------------------
  ViewerAccountsState copyWith({
    bool? isBusy,
    bool? isError,
    bool? isHeaderRefreshing,
    String? errorMessage,
    List<Account>? accounts,
    String? totalBalance,
    int? page,
    int? totalCount,
    String? userId,
    String? userName,
  }) {
    return ViewerAccountsState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      isHeaderRefreshing: isHeaderRefreshing ?? this.isHeaderRefreshing,
      errorMessage: errorMessage ?? this.errorMessage,
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  // ---------------------------------------------------------------------------
  // [Helper] 무한 스크롤 가능 여부 판단
  // 현재 리스트 개수가 전체 개수보다 적으면 다음 페이지가 존재함
  // ---------------------------------------------------------------------------
  bool get hasMore => accounts.length < totalCount;
}