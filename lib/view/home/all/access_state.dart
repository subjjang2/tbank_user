

import 'package:tbank_user/repository/response/account_response.dart';

import '../../base_view_state.dart';

class AccessibleAccountsState extends BaseViewState {
  final String userId;
  final String userName;
  final List<Account> accounts;
  final String totalBalance; // 총 자산 (계산된 값)
  final int page;
  final int totalCount;
  final bool isHeaderRefreshing;
  const AccessibleAccountsState({
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
  AccessibleAccountsState copyWith({
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
    return AccessibleAccountsState(
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
  bool get hasMore => accounts.length < totalCount;
}