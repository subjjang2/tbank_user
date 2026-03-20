import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../theme/button/button.dart';
import '../base_view.dart';
import 'random_counter_view_model.dart';

class RandomCounterView extends ConsumerWidget {
  const RandomCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseView(
      viewModelProvider: randomCounterViewModelProvider,
      builder: (ref, viewModel, state) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${state.count}',
              style: ref.typo.headline1.copyWith(color: ref.color.primary),
            ),
            const SizedBox(height: 24),
            Button(
              text: '랜덤 숫자 올리기',
              size: ButtonSize.large,
              isInactive: state.isBusy,
              onPressed: () => viewModel.incrementRandomly(),
            ),
          ],
        ),
      ),
    );
  }
}
