# test/ — 테스트

## Overview / Owns
Flutter 위젯·유닛 테스트. 실행: `flutter test`.

## Key Files
- `view/login/` — Login feature MVVM 3종 테스트
  - `login_view_test.dart` (위젯) · `login_view_model_test.dart` (로직) · `login_view_state_test.dart` (상태)
- `repository/` — Repository 5종 단위 테스트 (auth·account·transfer·bank·system)
  - `mock_dio.dart` — 공유 Dio mock 헬퍼 (`buildMockDio`/`MockReply`/`respondsWith`/`throwsDioType`)

## Common Change Patterns
- 테스트는 `lib/` 구조를 미러링 — `view/<feature>/` 추가 시 같은 경로에 `*_test.dart`
- ViewModel 테스트는 `ProviderContainer`로 Provider를 격리해 `state` 전이 검증
- Repository 테스트는 `mock_dio.dart`의 `buildMockDio(handler)`로 Dio를 교체해 직접 생성 (`Repo(buildMockDio(...))`) — Provider 불필요. 응답 파싱 + `ApiErrorHandler.parse` 전체 경로가 실행됨

## Non-obvious / Gotchas
- Repository 에러 계약 검증: 대부분 `AppException` throw, 단 **`BankRepository`는 에러를 삼키고 empty/[] 반환**, `account.searchUserForPermission`은 **404→null**
- 4xx/5xx는 `MockReply(statusCode, ...)`만 반환하면 Dio가 자동으로 `DioException(badResponse)`로 변환. 타임아웃/연결에러는 `throwsDioType(...)` 사용
- ViewModel 위젯 테스트에서 `flutter_secure_storage`는 플랫폼 채널이 없어 `setMockMethodCallHandler`로 채널 mock 필요 (`login_view_model_test.dart` 참고)

## Dependencies
- `flutter_test`, `flutter_riverpod`. 대상: `../lib/`
