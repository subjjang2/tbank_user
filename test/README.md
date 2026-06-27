# test/ — 테스트

## Overview / Owns
Flutter 위젯·유닛 테스트. 실행: `flutter test`.

## Key Files
- `widget_test.dart` — 앱 부트스트랩 스모크 테스트 (템플릿 기반)
- `view/login/` — Login feature MVVM 3종 테스트
  - `login_view_test.dart` (위젯) · `login_view_model_test.dart` (로직) · `login_view_state_test.dart` (상태)

## Common Change Patterns
- 테스트는 `lib/` 구조를 미러링 — `view/<feature>/` 추가 시 같은 경로에 `*_test.dart`
- ViewModel 테스트는 `ProviderContainer`로 Provider를 격리해 `state` 전이 검증

## Non-obvious / Gotchas
- 현재 커버리지는 login feature + 스모크 테스트뿐 — repository/service 단위 테스트 부재
- Riverpod Provider 의존 테스트는 `ProviderScope` override로 Repository를 mock 주입 권장

## Dependencies
- `flutter_test`, `flutter_riverpod`. 대상: `../lib/`
