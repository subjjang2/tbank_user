# view/ — 프레젠테이션 계층 (Feature-First + MVVM)

## Overview / Owns
모든 화면 UI. 기능(feature)별 폴더로 구성되며 각 feature는 `*_view` + `*_view_model` + `*_view_state` 3종 세트.
공통 베이스(`base_view.dart` / `base_view_model.dart` / `base_view_state.dart`)가 MVVM 골격을 제공한다.

## Key Files
- `base_view.dart` — 제네릭 래퍼. `viewModelProvider` + `builder(ref, viewModel, state)` 패턴
- `base_view_model.dart` — `BaseViewModel<S> extends AutoDisposeNotifier<S>`
- `base_view_state.dart` — `isBusy` / `isError` / `errorMessage` 공통 필드
- feature: `login/` · `register/` · `splash/` · `home/`(all·my·view 탭) · `transfer/` · `transaction_history/` · `authority/` · `account_info/` · `create_account/`

## Common Change Patterns
```dart
// ViewModel
final xViewModelProvider = NotifierProvider.autoDispose<XViewModel, XViewState>(XViewModel.new);
class XViewModel extends BaseViewModel<XViewState> {
  XViewState build() => XViewState.initial();
  Future<void> action() async {
    state = state.copyWith(isBusy: true, isError: false);
    try { ... state = state.copyWith(isBusy: false, ...); }
    on AppException catch (e) { state = state.copyWith(isError: true, errorMessage: e.message, isBusy: false); }
  }
}
```
- 화면 추가 후 `../util/route_path.dart`에 라우트 등록 필수

## Non-obvious / Gotchas
- **에러 UI 4가지 혼용(중복 패턴):** `ref.listen`+SnackBar / `state.isError` 직접 렌더 / `AppDialog`(util) / `Toast`(theme). 새 화면은 기존 feature 한 곳을 골라 일관되게
- **ViewModel 반환 타입 혼용:** bool / void / String? 제각각
- 파일명 오타: `home/my/my_accont_view.dart`, `transaction_history/transation_*`
- 클래스 접미사 혼용: `LoginView` vs `TransferScreen`

## Dependencies
- 의존: `../repository/`(ref.read), `../provider/`, `../theme/`·`../res/`(UI), `../util/`(route·dialog)
- 피의존: `../util/route_path.dart`(onGenerateRoute가 각 View 생성)
