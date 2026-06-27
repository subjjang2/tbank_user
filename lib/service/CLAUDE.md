# service/ — 비즈니스 로직 계층

## Overview / Owns
외부 SDK 연동·UI cross-cutting 관심사(FCM·테마)만 담당한다.
**API 호출은 Service를 거치지 않는다** — ViewModel/Provider가 Repository를 직접 호출하는 것이 표준 ([ADR 0005](../../docs/adr/0005-api-call-via-repository.md)).

## Key Files
- `fcm_service.dart` — Firebase Cloud Messaging 초기화·토큰·알림 처리. `fcmServiceProvider`, `fcmTokenProvider`(StateProvider). `main.dart`에서 부트스트랩 시 `initialize()` 호출
- `theme_service.dart` — 라이트/다크 테마 전환

## Common Change Patterns
- FCM 라우팅: 알림 data의 `route` 키 → `navigatorKey.currentState?.pushNamed(route)` (`fcm_service.dart`)
- 토큰 갱신: `fcmTokenProvider`를 `ref.watch`하여 로그인 요청에 포함
- **API가 필요한 로직은 여기 만들지 말 것** — `../repository/`에 추가하고 ViewModel에서 직접 호출

## Non-obvious / Gotchas
- 과거 `auth_service.dart`/`account_service.dart`가 Repository를 래핑했으나 미사용 중복이라 제거됨 ([ADR 0005](../../docs/adr/0005-api-call-via-repository.md))
- 백그라운드 메시지 핸들러는 top-level 함수 + `@pragma('vm:entry-point')` 필요 (`main.dart`)

## Dependencies
- 의존: `../repository/`, `firebase_messaging`, `flutter_local_notifications`, `flutter_secure_storage`
- 피의존: `../view/`, `main.dart`(fcm 부트스트랩)
