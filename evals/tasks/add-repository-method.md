# Task: Repository 메서드 추가

## Prompt (에이전트에 제시)
"계좌 거래 한도를 조회하는 API(`GET /accounts/{number}/limit`)를 repository에 추가하라."

## Pass Criteria (golden)
- [ ] 적절한 Repository(`account_repository.dart` 또는 신규)에 메서드 추가, 주입된 `_dio` 사용
- [ ] 응답을 `response/`의 모델로 파싱 (`res.data['data']` 래핑 규약)
- [ ] 에러는 `throw ApiErrorHandler.parse(e)` — bool/null로 삼키지 않음
- [ ] Provider로 노출 (`xxxRepositoryProvider` 네이밍)
- [ ] `flutter analyze` 경고 없음

## 측정 포인트
에러 계약([ADR 0003](../../docs/adr/0003-error-handling-exception-contract.md))과 Repository 패턴([lib/repository/CLAUDE.md](../../lib/repository/CLAUDE.md))을 따르는지. Service의 bool/String? 반환 안티패턴을 답습하지 않는지.
