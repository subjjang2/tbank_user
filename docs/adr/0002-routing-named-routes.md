# 0002 — 라우팅: 네이티브 Named Route

- **Status:** Accepted
- **관련 코드:** `lib/util/route_path.dart`, `lib/main.dart`

## Context
화면 수가 많지 않고(약 6개 라우트), FCM 알림 클릭 시 context 없이도 네비게이션할 수 있어야 했다. go_router 도입은 의존성·러닝커브를 추가한다.

## Decision
**Flutter 기본 Named Route + `onGenerateRoute`**를 사용한다 (go_router 미채택).
- 라우트 상수와 생성 로직을 `RoutePath`(`util/route_path.dart`)에 중앙화
- `MaterialApp(initialRoute: splash, onGenerateRoute: RoutePath.onGenerateRoute)`
- 파라미터는 `settings.arguments`로 String 또는 Map 전달
- 모든 화면을 `ConstrainedScreen`으로 감싸 반응형 대응
- context 없는 전역 네비게이션(FCM 콜백)은 `navigatorKey`(`common/app_global.dart`) 사용

## Consequences
- (+) 의존성 0, 라우트가 한 파일에 집중되어 파악 쉬움
- (+) 전역 `navigatorKey`로 알림 딥링크 처리 가능
- (−) 타입 안전 라우팅·중첩 라우팅·딥링크 URL 파싱은 수동
- (−) 네비게이션 호출이 `Navigator.pushNamed`(View)와 `navigatorKey`(FCM)로 혼재 → [0004](0004-known-duplication-debt.md) 참조
- 화면이 크게 늘거나 웹 URL 라우팅이 필요해지면 go_router 재검토 (이 ADR을 Superseded 처리)
