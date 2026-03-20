import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repository/account_repository.dart';
import '../base_view_state.dart';

// 1. State 클래스
class CreateAccountState extends BaseViewState {


  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  final bool isSuccess;

  final bool isAuditorAllowed; // 감찰 허용 여부
  const CreateAccountState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.isAuditorAllowed = true,
    this.isSuccess = false,

  });

  CreateAccountState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    bool? isAuditorAllowed,
    bool? isSuccess,

  }) {
    return CreateAccountState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      isAuditorAllowed: isAuditorAllowed ?? this.isAuditorAllowed,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
