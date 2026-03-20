# Plan: RandomCounterView 구현

## Context
Gemini가 설계한 `gemini_plan.md`를 기반으로 상태 관리 테스트용 랜덤 카운터 화면을 구현한다.
기존 `CounterView` 패턴을 그대로 재사용하되, `increment()` 대신 `incrementRandomly()`에서 `dart:math`의 Random으로 1~100 사이의 값을 누적한다.
`BaseView`가 `isBusy` 상태를 자동으로 감지해 로딩 인디케이터를 표시하므로, View는 UI에만 집중한다.

---

## 생성 파일 3개

### 1. `lib/view/random_counter/random_counter_view_state.dart`
`counter_view_state.dart`를 그대로 복제 후 이름만 변경.

```dart
import '../base_view_state.dart';

class RandomCounterViewState extends BaseViewState {
  const RandomCounterViewState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.count = 0,
  });

  @override final bool isBusy;
  @override final bool isError;
  @override final String errorMessage;

  final int count;

  RandomCounterViewState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    int? count,
  }) {
    return RandomCounterViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      count: count ?? this.count,
    );
  }
}
```

### 2. `lib/view/random_counter/random_counter_view_model.dart`
`counter_view_model.dart`를 기반으로 `increment()` → `incrementRandomly()`로 교체.

```dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../base_view_model.dart';
import 'random_counter_view_state.dart';

final randomCounterViewModelProvider =
    NotifierProvider.autoDispose<RandomCounterViewModel, RandomCounterViewState>(
        RandomCounterViewModel.new);

class RandomCounterViewModel extends BaseViewModel<RandomCounterViewState> {
  @override
  RandomCounterViewState build() => const RandomCounterViewState(
        isBusy: false, isError: false, errorMessage: '',
      );

  Future<void> incrementRandomly() async {
    state = state.copyWith(isBusy: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final randomNumber = Random().nextInt(100) + 1;
      state = state.copyWith(count: state.count + randomNumber);
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
```

### 3. `lib/view/random_counter/random_counter_view.dart`
`counter_view.dart`를 기반으로 버튼 텍스트와 provider만 교체.

```dart
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
```

---

## 참조 파일 (수정 없음)
- `lib/view/counter/counter_view_state.dart` — State 패턴 원본
- `lib/view/counter/counter_view_model.dart` — ViewModel 패턴 원본
- `lib/view/counter/counter_view.dart` — View 패턴 원본
- `lib/view/base_view.dart` — BaseView (제네릭, 로딩 자동 처리)
- `lib/theme/button/button.dart` — Button 위젯 (`isInactive` 지원)

---

## 검증
1. `RandomCounterView`로 라우팅 후 앱 실행
2. 버튼 클릭 → 1초간 로딩 인디케이터 표시 + 버튼 비활성화 확인
3. 로딩 완료 후 count가 1~100 사이 값만큼 증가 확인
4. 로딩 중 버튼 연타 → 중복 호출 없음 확인
