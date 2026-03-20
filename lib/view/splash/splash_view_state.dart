
import '../base_view_state.dart';

class SplashViewState extends BaseViewState {
  const SplashViewState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
  });
  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;


  SplashViewState copyWith({bool? isBusy, String? errorMessage ,bool? isError }) {
    return SplashViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}