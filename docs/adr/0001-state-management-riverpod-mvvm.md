# 0001 — 상태관리: Riverpod + MVVM

- **Status:** Accepted
- **관련 코드:** `lib/view/base_view.dart`, `lib/view/base_view_model.dart`, `lib/view/base_view_state.dart`

## Context
화면마다 로딩/에러/데이터 상태를 일관되게 다루고, 의존성(Repository·Service)을 테스트 가능하게 주입할 방법이 필요했다. Flutter의 기본 `setState`는 비동기 흐름·DI·자동 정리(dispose)에서 보일러플레이트가 많다.

## Decision
**Riverpod 기반 MVVM**을 표준으로 한다.
- 각 화면 = `*_view`(UI) + `*_view_model`(로직) + `*_view_state`(불변 상태) 3종 세트
- ViewModel은 `BaseViewModel<S> extends AutoDisposeNotifier<S>`를 상속, 상태는 `BaseViewState`(isBusy/isError/errorMessage) 확장
- Provider: `NotifierProvider.autoDispose` (파라미터 필요 시 `.family`)
- 상태 갱신은 `copyWith` 불변 패턴, 화면 종료 시 `autoDispose`로 자동 정리
- 상태 읽기 `ref.watch`, 메서드 호출·일회성 읽기 `ref.read`

## Consequences
- (+) 화면 구조가 예측 가능, DI·테스트 용이(`ProviderScope` override로 mock 주입)
- (+) 자동 dispose로 메모리 누수 방지
- (−) feature마다 파일 3개 → 보일러플레이트. 단순 화면도 동일 구조 강제
- (−) 일부 ViewModel이 `BaseViewModel` 대신 `AutoDisposeFamilyNotifier`를 직접 상속하는 등 변형 존재 → [0004](0004-known-duplication-debt.md) 참조
