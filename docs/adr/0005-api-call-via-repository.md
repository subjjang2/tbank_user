# 0005 — API 호출은 ViewModel → Repository 직접 호출로 통일

- **Status:** Accepted
- **관련:** [0003](0003-error-handling-exception-contract.md), [0004](0004-known-duplication-debt.md)
- **관련 코드:** `lib/view/**/*_view_model.dart`, `lib/repository/*`, `lib/provider/account_status_provider.dart`

## Context
API 호출 경로가 두 갈래로 혼재했다.
- **다수(6곳):** ViewModel/Provider가 `ref.read(xxxRepositoryProvider).method()`로 Repository를 직접 호출 (login·register·transfer·transaction_history·my_account·account_status)
- **소수/죽은 코드:** `auth_service.dart`가 `authRepositoryProvider`를 래핑(login/signup/이메일인증)했으나 **어떤 ViewModel도 `authServiceProvider`를 사용하지 않았다.** `account_service.dart`는 Provider도 참조도 없는 빈 stub.

같은 로그인 로직이 ViewModel과 Service에 이중 구현되어 있었고(토큰 저장 등), 신규 작업 시 어느 경로를 따라야 할지 모호했다.

## Decision
**ViewModel/Provider가 Repository를 직접 호출하는 방식을 단일 표준으로 한다.**
- API가 필요한 로직은 `repository/`에 메서드를 추가하고 ViewModel에서 `ref.read(xxxRepositoryProvider)`로 호출
- 미사용 Service 래퍼(`auth_service.dart`, `account_service.dart`)는 제거
- `service/`는 API와 무관한 cross-cutting(FCM·테마)만 담당
- 에러는 [0003](0003-error-handling-exception-contract.md)대로 Repository가 `AppException` throw → ViewModel이 catch

## Consequences
- (+) 호출 경로 일원화, 신규 작업 시 따라야 할 패턴이 명확
- (+) 죽은 코드 제거로 표면적 축소 (auth/account service의 bool/String? 반환 안티패턴도 함께 소멸)
- (−) 로그인 토큰 저장 등 로직이 각 ViewModel에 위치 — 여러 화면이 공유할 정도로 복잡해지면 Repository 또는 전용 헬퍼로 추출 재검토
- 검증: `flutter analyze`(신규 에러 0), login feature 테스트 통과로 회귀 없음 확인
