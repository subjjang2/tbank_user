# 0004 — 알려진 중복/혼용 부채와 통일 방향

- **Status:** Accepted (부채 인지·통일 방향 합의)
- **관련:** 루트 `CLAUDE.md` "⚠️ 중복 패턴", [0001](0001-state-management-riverpod-mvvm.md), [0003](0003-error-handling-exception-contract.md)

## Context
빠른 개발 과정에서 같은 일을 다르게 처리하는 패턴이 누적됐다. 즉시 일괄 리팩토링은 리스크가 크므로, **부채를 명시적으로 기록하고 신규 코드의 통일 방향만 정한다.**

## Decision (신규 코드 기준)
| 영역 | 현재 혼용 | 통일 방향 |
|---|---|---|
| 모델 정의 | freezed vs 수동 class | **freezed** (생성 명령 필수) |
| 에러 반환 | ~~Repository=Exception / Service=bool·String?·void~~ → Service 래퍼 제거됨 | **Exception throw** ([0003](0003-error-handling-exception-contract.md), [0005](0005-api-call-via-repository.md)) |
| ViewModel 결과 | bool / void / String? | **state에 저장**, 반환은 성공여부 bool 1가지 |
| View 에러 UI | ref.listen / 인라인 / AppDialog / Toast | feature 내 **한 방식 일관** 사용 |
| 네비게이션 | Navigator.pushNamed / navigatorKey | View=`pushNamed`, 전역콜백=`navigatorKey` ([0002](0002-routing-named-routes.md)) |
| State 초기화 | const 생성자 / factory.initial() | **`factory .initial()`** |

## Consequences
- (+) 신규 코드의 방향이 명확, 리뷰 기준 생김
- (+) 기존 코드는 "건드릴 때 통일" 점진 정리 (big-bang 리팩토링 회피)
- (−) 당분간 혼용 상태 공존 — 파일명 오타(`transation_history`, `my_accont_view`)는 `transaction_history`·`my_account_view`로 rename 완료 (2026-07-03)
