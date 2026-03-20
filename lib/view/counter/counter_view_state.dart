import '../base_view_state.dart';

class CounterViewState extends BaseViewState {
  const CounterViewState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.count = 0,
  });

  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  final int count;

  CounterViewState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    int? count,
  }) {
    return CounterViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      count: count ?? this.count,
    );
  }
}
