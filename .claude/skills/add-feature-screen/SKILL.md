---
name: add-feature-screen
description: T-BANK 앱에 새 화면(feature)을 추가할 때 사용. view + view_model + view_state 3종 세트를 BaseView/BaseViewModel/BaseViewState 패턴으로 생성하고 route_path.dart에 라우트를 등록한다. "새 화면 추가", "feature 만들기", "페이지 추가", "화면 만들어줘", "view 추가" 같은 요청에 트리거.
---

# 새 화면(feature) 추가

T-BANK 사용자 앱은 **Feature-First + MVVM** 구조다. 화면 하나 = `<feature>/` 폴더 안의
`<feature>_view.dart` + `<feature>_view_model.dart` + `<feature>_view_state.dart` 3종 세트 + 라우트 등록.

## 시작 전 확인할 것
- feature 이름 (snake_case, 예: `account_detail`)
- 화면이 받을 파라미터 (없음 / String / Map)
- 보여줄 데이터와 호출할 Repository/API (API가 새로 필요하면 `add-api-endpoint` Skill 먼저)
- 클래스 접미사: 신규는 `View`로 통일 권장 (기존 `Screen` 혼용은 두지 말 것)

## 절차

폴더 `lib/view/<feature>/` 생성 후 아래 3파일 작성.

### 1. State (`<feature>_view_state.dart`)
`BaseViewState`(공통 `isBusy`/`isError`/`errorMessage`)를 상속하고 확장 필드만 추가.
```dart
import '../base_view_state.dart';

class XViewState extends BaseViewState {
  const XViewState({
    required this.isBusy,
    required this.isError,
    required this.errorMessage,
    this.data, // 확장 필드
  });

  @override final bool isBusy;
  @override final bool isError;
  @override final String errorMessage;

  final SomeData? data;

  factory XViewState.initial() =>
      const XViewState(isBusy: false, isError: false, errorMessage: '');

  XViewState copyWith({
    bool? isBusy,
    String? errorMessage,
    bool isError = false,
    SomeData? data,
  }) => XViewState(
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage ?? this.errorMessage,
        isError: isError ?? this.isError,
        data: data ?? this.data,
      );
}
```

### 2. ViewModel (`<feature>_view_model.dart`)
`BaseViewModel<S>`(= AutoDisposeNotifier) 상속. Provider는 `NotifierProvider.autoDispose`.
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../base_view_model.dart';
import '../../util/helper/app_exception.dart';
import 'x_view_state.dart';

final xViewModelProvider =
    NotifierProvider.autoDispose<XViewModel, XViewState>(XViewModel.new);

class XViewModel extends BaseViewModel<XViewState> {
  @override
  XViewState build() => XViewState.initial();

  Future<void> load() async {
    state = state.copyWith(isBusy: true, isError: false, errorMessage: null);
    try {
      final res = await ref.read(xRepositoryProvider).fetchX();
      state = state.copyWith(isBusy: false, data: res);
    } on AppException catch (e) {
      state = state.copyWith(isBusy: false, isError: true, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isBusy: false, isError: true, errorMessage: "서버 통신 중 오류가 발생했습니다.");
    }
  }
}
```
- Repository 호출은 `ref.read(...Provider)`, 상태는 `copyWith` 불변 업데이트.

### 3. View (`<feature>_view.dart`)
`BaseView<VM, S>`로 감싼다. 화면 진입 로딩(`isBusy`)은 BaseView가 `CircularIndicator`로 처리.
```dart
import 'package:flutter/material.dart';
import '../base_view.dart';
import 'x_view_model.dart';

class XView extends StatelessWidget {
  const XView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView(
      viewModelProvider: xViewModelProvider,
      appBar: AppBar(title: const Text('제목')),
      builder: (ref, viewModel, state) {
        // state.data 렌더 / 버튼에서 viewModel.load() 호출
        return const SizedBox();
      },
    );
  }
}
```
- 입력 컨트롤러(`TextEditingController`) 등 **UI 로컬 상태가 필요하면** `login_view.dart`처럼
  `ConsumerStatefulWidget`으로 만들고 `dispose()` 처리.

### 4. 라우트 등록 (`lib/util/route_path.dart`) — 필수
1. 상수 추가: `static const String x = 'x';`
2. `onGenerateRoute` switch에 case 추가:
```dart
case RoutePath.x:
  page = const XView();
  break;
```
3. 파라미터 전달 시 기존 예시 따르기:
   - String: `final id = settings.arguments as String? ?? ''; page = XView(id: id);`
   - 여러 값: `final args = settings.arguments as Map<String, dynamic>? ?? {};`
   - import 추가하고, 모든 페이지는 `ConstrainedScreen`으로 자동 래핑됨(반환부에서 처리됨, 신경 X).

이동: `Navigator.pushNamed(context, RoutePath.x, arguments: ...)`.

### 5. 검증
```bash
flutter analyze
```

## 주의 (프로젝트 고유)
- **파일/클래스 네이밍:** snake_case 파일, PascalCase 클래스. 신규는 `View` 접미사로 통일(기존 `Screen` 따라가지 말 것). 과거 오타(`transation_`, `accont_`)를 신규 파일에서 답습 금지 — 정확한 철자 사용.
- **에러 UI가 4가지 혼용**(SnackBar/state 직접 렌더/AppDialog/Toast). 새 화면은 한 방식을 골라 일관되게.
- State 초기화도 `const` 생성자 직접 호출 vs `.initial()` 혼용 — 신규는 `.initial()` 권장.
- freezed State를 쓰지 않는다(State는 수동 class). 모델/응답에만 freezed.
