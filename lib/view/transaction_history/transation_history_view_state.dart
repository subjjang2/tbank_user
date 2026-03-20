// view_model/transaction/transaction_view_state.dart
import '../../model/transaction.dart';
import '../base_view_state.dart';

/// ----------------------------------------------------------------------------
/// [TransactionViewState]
/// 거래 내역 화면(TransactionHistoryScreen)에서 사용하는 모든 상태를 담는 클래스입니다.
/// 리스트 데이터, 페이징 정보, 필터 설정, 로딩/에러 상태 등을 포함합니다.
/// ----------------------------------------------------------------------------
class TransactionViewState extends BaseViewState {
  // 1. 데이터 영역
  final List<Transaction> transactions; // 화면에 보여줄 거래 내역 리스트
  final String balance;                 // 현재 계좌 잔액 (헤더 표시용)
  final String accountName;             // 계좌 별칭 (헤더 표시용)

  // 2. 페이징 영역
  final int page;         // 현재 로드된 페이지 번호
  final int totalCount;   // 서버에 저장된 전체 데이터 개수 (무한 스크롤 종료 판단용)

  // 3. 필터 영역 (기간 조회)
  final DateTime? startDate;      // 조회 시작일
  final DateTime? endDate;        // 조회 종료일
  final int? selectedPeriodDays;  // 선택된 기간 (1주일, 1개월 등 - 선택사항)
  final bool isAllClick;          // '전체' 칩 선택 여부 (true: 전체, false: 기간설정)

  // 4. BaseViewState 상속 (공통 상태)
  @override
  final bool isBusy;        // 로딩 중 여부
  @override
  final bool isError;       // 에러 발생 여부
  @override
  final String errorMessage; // 에러 메시지

  const TransactionViewState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.transactions = const [],
    this.page = 1,
    this.totalCount = 0,
    this.balance = "",
    this.accountName = "",
    this.startDate,
    this.endDate,
    this.selectedPeriodDays,
    this.isAllClick = true,
  });

  // 초기 상태 생성 (화면 진입 시점)
  factory TransactionViewState.initial() {
    return const TransactionViewState(
      isBusy: false,
      isError: false,
      errorMessage: '',
      balance: "",
    );
  }

  // ✨ [핵심 로직] 무한 스크롤 가능 여부 판단
  // 현재 가지고 있는 리스트 개수가 서버의 전체 개수보다 적으면 더 불러올 데이터가 있다는 뜻
  bool get hasMore => transactions.length < totalCount;

  // 상태 업데이트를 위한 copyWith (불변 객체 유지)
  TransactionViewState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    List<Transaction>? transactions,
    int? page,
    int? totalCount,
    String? balance,
    String? accountName,
    DateTime? startDate,
    DateTime? endDate,
    int? selectedPeriodDays,
    bool? isAllClick,
  }) {
    return TransactionViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      balance: balance ?? this.balance,
      accountName: accountName ?? this.accountName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPeriodDays: selectedPeriodDays ?? this.selectedPeriodDays,
      isAllClick: isAllClick ?? this.isAllClick,
    );
  }
}