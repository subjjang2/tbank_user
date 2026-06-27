# Architecture Decision Records (ADR)

이 프로젝트의 **되돌리기 어려운 기술 결정**과 그 근거를 기록한다. 코드만 봐서는 "왜 이렇게 했는지" 알 수 없는 의사결정을 외부화해, 새 합류자·AI 에이전트가 같은 맥락에서 작업하도록 한다.

## 목록
- [0001](0001-state-management-riverpod-mvvm.md) — 상태관리: Riverpod + MVVM(BaseView/ViewModel/State)
- [0002](0002-routing-named-routes.md) — 라우팅: 네이티브 Named Route (go_router 미채택)
- [0003](0003-error-handling-exception-contract.md) — 에러 처리: Repository Exception 계약 + ApiErrorHandler 단일화
- [0004](0004-known-duplication-debt.md) — 알려진 중복/혼용 부채와 통일 방향
- [0005](0005-api-call-via-repository.md) — API 호출은 ViewModel→Repository 직접 호출로 통일 (Service 래퍼 제거)

## 작성 규칙
- 파일명: `NNNN-kebab-title.md` (4자리 순번)
- 형식: **Status · Context · Decision · Consequences**
- Status: `Proposed` → `Accepted` → (대체 시) `Superseded by NNNN`
- 결정이 바뀌면 기존 ADR을 지우지 말고 새 ADR로 대체 기록 (이력 보존)
