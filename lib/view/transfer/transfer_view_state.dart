import '../base_view_state.dart';

class TransferViewState extends BaseViewState {
  const TransferViewState({
    // ✨ [핵심 수정 1] this.isBusy 대신 super.isBusy 사용
    // 이렇게 하면 부모(BaseViewState)의 생성자로 값이 바로 전달됩니다.
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.accountName,
    this.isVerifying = false,
    this.fee,
    this.isLoadingFee = false,
    this.isTransferOk = false,

  });

  @override
  final bool isBusy;

  @override
  final bool isError;
  @override
  final String errorMessage;

  // --- BaseViewState에 없는(확장된) 필드들만 선언 ---

  final String? accountName;
  final bool isVerifying;
  final int? fee;
  final bool isLoadingFee;
  final bool isTransferOk;

  factory TransferViewState.initial() {
    return const TransferViewState(
      isBusy: false,
      isVerifying: false,
      isLoadingFee: false, isError: false, errorMessage: '',isTransferOk: false
    );
  }

  // 상태 업데이트 메서드
  TransferViewState copyWith({
    bool? isBusy,
    String? errorMessage,
    String? accountName,
    bool? isVerifying,
    int? fee,
    bool? isLoadingFee,
    bool forceClearOwnerName = false,
    bool isError = false,
    bool isTransferOk=false
  }) {
    return TransferViewState(
      // 부모 필드(isBusy)도 여기서 업데이트 가능
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage ?? this.errorMessage,
      accountName: forceClearOwnerName ? null : (accountName ?? this.accountName),
      isVerifying: isVerifying ?? this.isVerifying,
      fee: fee ?? this.fee,
      isLoadingFee: isLoadingFee ?? this.isLoadingFee,
      isError: isError ?? this.isError,
      isTransferOk: isTransferOk ?? this.isTransferOk,
    );
  }
}