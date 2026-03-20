# 📱 [Task] 상태 관리 테스트용 랜덤 카운터 화면(RandomCounterView) 구현

## 1. 작업 대상 범위
- **생성 폴더:** `lib/view/random_counter/`
- **생성 파일:** 1. `random_counter_view_state.dart`
    2. `random_counter_view_model.dart`
    3. `random_counter_view.dart`

## 2. 구현 명세서 (@docs/architecture.md 규칙 철저히 준수)

### A. State (`random_counter_view_state.dart`)
- `BaseViewState`를 상속받는 `RandomCounterViewState` 클래스 생성.
- 추가 상태값: `final int count;` (기본값 0)
- 필수 필드(`isBusy`, `isError`, `errorMessage`)를 포함하여 `copyWith` 메서드 구현.

### B. ViewModel (`random_counter_view_model.dart`)
- `BaseViewModel<RandomCounterViewState>`를 상속받는 `RandomCounterViewModel` 클래스 생성.
- `randomCounterViewModelProvider` (AutoDisposeNotifierProvider) 정의.
- `dart:math` 패키지의 `Random` 클래스를 활용.
- `incrementRandomly()` 비동기 메서드 구현:
    1. 시작 시 `state = state.copyWith(isBusy: true);`
    2. 가짜 API 통신 지연을 위해 `await Future.delayed(const Duration(seconds: 1));`
    3. `Random().nextInt(100) + 1`을 사용하여 1~100 사이의 랜덤 숫자를 생성.
    4. 생성된 숫자를 기존 `count`에 더해서 업데이트. (`state = state.copyWith(count: state.count + randomNumber);`)
    5. `finally` 블록에서 `isBusy: false`로 복구.

### C. View (`random_counter_view.dart`)
- `ConsumerWidget`으로 생성.
- **반드시 `BaseView`로 최상단을 감쌀 것.** (로딩 인디케이터 테스트 목적)
- `randomCounterViewModelProvider` 구독 (`ref.watch`, `ref.read`).
- **UI 구성 (`builder` 내부):**
    - 화면 중앙(`Column`, `MainAxisAlignment.center`)에 현재 `count` 값을 표시.
    - **[중요] 테마 적용:** Text style은 반드시 `ref.typo.headline1.copyWith(color: ref.color.primary)` 형태로 적용할 것.
    - 그 아래에 "랜덤 숫자 올리기" 버튼(프로젝트 공통 `Button` 위젯 권장) 배치.
    - **[중요] 다중 클릭 방지:** 버튼의 `onPressed`는 `state.isBusy ? null : () => viewModel.incrementRandomly()` 형태로 작성하여 로딩 중 중복 API 호출을 막을 것.