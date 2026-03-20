import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../base_view_model.dart';
import 'counter_view_state.dart';

final counterViewModelProvider =
    NotifierProvider.autoDispose<CounterViewModel, CounterViewState>(
        CounterViewModel.new);

class CounterViewModel extends BaseViewModel<CounterViewState> {
  @override
  CounterViewState build() =>
      const CounterViewState(isBusy: false, isError: false, errorMessage: '');

  Future<void> increment() async {
    state = state.copyWith(isBusy: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(count: state.count + 1);
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
