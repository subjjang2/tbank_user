import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../theme/circular_indicator.dart';
import 'base_view_model.dart';
import 'base_view_state.dart';

class BaseView<VM extends BaseViewModel<S>, S extends BaseViewState>
    extends ConsumerWidget {
  const BaseView({
    super.key,
    required this.viewModelProvider,
    required this.builder,
    this.appBar,
    this.backgroundColor,
    // ✨ [추가] 키보드 관련 설정 (기본값 true)
    this.resizeToAvoidBottomInset = true,
  });

  final AutoDisposeNotifierProvider<VM, S> viewModelProvider;
  final Widget Function(WidgetRef ref, VM viewModel, S state) builder;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  // ✨ [추가] 변수 선언
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewModelProvider);
    final viewModel = ref.read(viewModelProvider.notifier);

    return CircularIndicator(
      isBusy: state.isBusy,
      child: Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor,
        // ✨ [추가] 전달받은 설정 적용
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: builder(
          ref,
          viewModel,
          state,
        ),
      ),
    );
  }
}