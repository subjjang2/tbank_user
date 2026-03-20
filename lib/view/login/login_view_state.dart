
import '../base_view_state.dart';


class LoginViewState extends BaseViewState {
  const LoginViewState({
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

  LoginViewState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
  }) {
    return LoginViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}