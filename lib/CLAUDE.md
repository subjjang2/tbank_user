# lib/ — 애플리케이션 코드

Flutter 앱의 전체 소스. 루트 [`../CLAUDE.md`](../CLAUDE.md) · 구조 상세 [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).

## Overview / Owns
- **진입점:** `main.dart` (Firebase·FCM·Riverpod 부트스트랩 → `MyApp`)
- **서브시스템별 모듈 문서:**
  - [`view/`](view/CLAUDE.md) — Presentation (Feature-First, MVVM)
  - [`repository/`](repository/CLAUDE.md) — Data (Dio API 호출)
  - [`service/`](service/CLAUDE.md) — Business (auth · fcm · theme)
- 그 외: `model/`(도메인 모델) · `provider/`(전역 Provider) · `util/`(route·helper) · `theme/`·`res/`(UI) · `common/`(전역 키)

## Common Change Patterns
- **새 화면 추가:** `view/<feature>/`에 `*_view` + `*_view_model` + `*_view_state` 3종 → `util/route_path.dart`에 라우트 등록
- **새 API:** `repository/<x>_repository.dart`에 메서드 추가 (`_dio` 사용, `throw ApiErrorHandler.parse(e)`)
- **모델 변경:** freezed 모델이면 `dart run build_runner build --delete-conflicting-outputs` 필수

## Non-obvious / Gotchas
- 상태 읽기는 `ref.watch`, 메서드 호출은 `ref.read` — 혼용 주의
- 전역 네비게이션/스낵바는 `common/app_global.dart`의 `navigatorKey`/`scaffoldMessengerKey` 사용 (context 없는 FCM 콜백용)
- 중복/혼용 패턴은 루트 CLAUDE.md "⚠️ 중복 패턴" 참조

## Dependencies
- 외부: `flutter_riverpod`, `dio`, `firebase_*`, `flutter_secure_storage`
- 내부 흐름: `view` → `repository`/`service` → `util/helper`(dioProvider) → API (단방향)
