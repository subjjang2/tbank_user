# 0003 — 에러 처리: Repository Exception 계약 + ApiErrorHandler 단일화

- **Status:** Accepted
- **관련 코드:** `lib/util/helper/api_error_handler.dart`, `lib/util/helper/app_exception.dart`, `lib/repository/*`

## Context
Dio 네트워크 에러(타임아웃·연결불가·HTTP status)는 형태가 제각각이고 사용자에게 보여줄 한글 메시지가 필요하다. 에러를 어디서 어떤 형태로 표현할지 계층 간 계약이 없으면 화면마다 처리가 갈린다.

## Decision
- 모든 Dio 에러는 `ApiErrorHandler.parse(e)`가 **`AppException`(한글 message)**로 변환한다 (타임아웃/연결불가/HTTP status별 분기, 서버 `message`/`error` 필드 우선)
- **Repository는 항상 `throw ApiErrorHandler.parse(e)`** — bool/null로 삼키지 않는다
- ViewModel이 `on AppException catch`로 받아 `state.copyWith(isError:true, errorMessage:e.message)`에 반영
- 의미 있는 예외: 존재하지 않는 리소스 조회(예: 권한 대상 사용자 검색)는 404를 에러가 아닌 `null`로 처리

## Consequences
- (+) 에러 메시지 변환 로직이 한 곳에 집중, 사용자에게 일관된 한글 메시지
- (+) Repository 호출부는 try/catch로 단일 예외 타입만 다루면 됨
- (−) **계약이 Repository에만 적용** — Service 계층은 bool/String?/void로 제각각 반환(미준수) → [0004](0004-known-duplication-debt.md)
- (−) View의 에러 표시(SnackBar/Dialog/Toast/인라인)는 여전히 비표준 → [0004](0004-known-duplication-debt.md)
