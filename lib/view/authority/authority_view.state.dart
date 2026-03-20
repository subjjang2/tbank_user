// 1. State 클래스
import '../../repository/response/authority/account_authority_response.dart';
import '../base_view_state.dart';

class AccountAuthorityState extends BaseViewState {


  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  final bool isSuccess;
  final bool isPending;

  final bool isAuditorAllowed; // 감찰 허용 여부

  List<Permission> permissions;

  final String? userSearchErrorMessage;

   AccountAuthorityState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.isAuditorAllowed = true,
    this.isSuccess = false,
    this.permissions = const [],
    this.userSearchErrorMessage,
    this.isPending =false
  });

  AccountAuthorityState copyWith({
    bool clearUserSearchError = false,
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    String? userSearchErrorMessage,
    bool? isAuditorAllowed,
    bool? isSuccess,
    bool? isPending,
    List<Permission>? permissions
  }) {
    return AccountAuthorityState(
      permissions: permissions ?? this.permissions,
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      isAuditorAllowed: isAuditorAllowed ?? this.isAuditorAllowed,
      isSuccess: isSuccess ?? this.isSuccess,
      isPending: isPending ?? this.isPending,
        // ✨ [수정] 플래그가 true면 null 주입, 아니면 기존 ?? 로직 수행
      userSearchErrorMessage: clearUserSearchError
          ? null
          : (userSearchErrorMessage ?? this.userSearchErrorMessage),
    );
  }
}
