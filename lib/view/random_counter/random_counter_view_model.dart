import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../base_view_model.dart';
import 'random_counter_view_state.dart';

final randomCounterViewModelProvider =
    NotifierProvider.autoDispose<RandomCounterViewModel, RandomCounterViewState>(
        RandomCounterViewModel.new);

class RandomCounterViewModel extends BaseViewModel<RandomCounterViewState> {
  final _random = Random();

  @override
  RandomCounterViewState build() => const RandomCounterViewState(
        isBusy: false,
        isError: false,
        errorMessage: '',
      );

  Future<void> incrementRandomly() async {
    state = state.copyWith(isBusy: true, isError: false, errorMessage: '');
    try {
      await Future.delayed(const Duration(seconds: 1));
      final randomNumber = _random.nextInt(100) + 1;
      state = state.copyWith(count: state.count + randomNumber);
    } catch (e) {
      state = state.copyWith(isError: true, errorMessage: e.toString());
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
