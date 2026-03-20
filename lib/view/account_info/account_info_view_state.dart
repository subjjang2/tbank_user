import '../../repository/response/account_search/account_searchtype_response.dart';
import '../base_view_state.dart';

class AccountInfoViewState extends BaseViewState {
  const AccountInfoViewState({
    // ✨ [핵심 수정 1] this.isBusy 대신 super.isBusy 사용
    // 이렇게 하면 부모(BaseViewState)의 생성자로 값이 바로 전달됩니다.
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.accountSearchResponse,
  });

  @override
  final bool isBusy;

  @override
  final bool isError;
  @override
  final String errorMessage;

  // --- BaseViewState에 없는(확장된) 필드들만 선언 ---

final AccountSearchResponse? accountSearchResponse;



  factory AccountInfoViewState.initial() {
    return const AccountInfoViewState(
      isBusy: false,
      isError: false, errorMessage: '',
    );
  }

  // 상태 업데이트 메서드
  AccountInfoViewState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool isError = false,
    AccountSearchResponse? accountSearchResponse
  }) {
    return AccountInfoViewState(
      // 부모 필드(isBusy)도 여기서 업데이트 가능
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage ?? this.errorMessage,
      isError: isError ?? this.isError,
      accountSearchResponse: accountSearchResponse ?? this.accountSearchResponse,
    );
  }
}