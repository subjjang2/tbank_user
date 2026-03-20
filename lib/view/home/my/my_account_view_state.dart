import '../../../repository/response/account_response.dart';
import '../../base_view_state.dart';

/// ----------------------------------------------------------------------------
/// [AccountViewState]
/// 내 계좌 화면(MyAccountView)의 모든 상태를 관리하는 클래스입니다.
/// 사용자 프로필(이름, 권한)과 계좌 목록 데이터, 페이징 정보 등을 포함합니다.
/// ----------------------------------------------------------------------------
class AccountViewState extends BaseViewState {
  // 1. [사용자 프로필 & 권한]
  final String userId;        // 사용자 ID
  final String userName;      // 사용자 이름 (헤더 표시용)
  final bool isAdmin;         // 관리자 권한 여부 (배지 표시용)
  final bool isAuditor;       // 감찰부 권한 여부 (배지 표시용)

  // 2. [계좌 데이터]
  final List<Account> accounts; // 화면에 보여줄 계좌 리스트
  final String totalBalance;    // 총 자산 (서버 계산값 혹은 앱 합산값)

  // 3. [페이징 정보]
  final int page;             // 현재 로드된 페이지 번호
  final int totalCount;       // 서버 전체 데이터 개수 (무한 스크롤 종료 판단용)

  // 4. [UI 상태]
  // isBusy(전체 로딩)와 별도로, '상단 당겨서 새로고침' 중인지 표시하는 플래그
  final bool isHeaderRefreshing;

  const AccountViewState({
    // BaseViewState 상속 필드 (로딩, 에러 상태)
    required this.isBusy,
    required this.isError,
    required this.errorMessage,

    // 초기값 설정
    this.accounts = const [],
    this.totalBalance = "0",
    this.page = 1,
    this.totalCount = 0,
    this.userId = "",
    this.userName = "",
    this.isHeaderRefreshing = false,
    this.isAdmin = false,
    this.isAuditor = false,
  });

  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  // ---------------------------------------------------------------------------
  // [copyWith] 불변 객체 유지를 위한 복사 메서드
  // 변경된 필드만 교체하여 새로운 상태 객체를 반환합니다.
  // ---------------------------------------------------------------------------
  AccountViewState copyWith({
    bool? isAdmin,
    bool? isAuditor,
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
    return AccountViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      isAdmin: isAdmin ?? this.isAdmin,
      isAuditor: isAuditor ?? this.isAuditor,
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
  // [Helper] 무한 스크롤 가능 여부 (Getter)
  // 현재 리스트 개수가 전체 개수보다 적으면 다음 페이지가 존재한다고 판단
  // ---------------------------------------------------------------------------
  bool get hasMore => accounts.length < totalCount;
}