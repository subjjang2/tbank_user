# evals/ — Agent 성과 측정

AI 에이전트가 이 코드베이스에서 흔히 수행하는 task를 **반복 가능한 기준**으로 채점해, 컨텍스트 문서 개선이 실제 산출물 품질로 이어지는지 정량 추적한다.

## 구성
- `tasks/*.md` — 대표 task 정의 + golden 기준(pass criteria)
- `agent-results.json` — 실행 결과 누적 (모델·일자·pass-rate)

## 실행 방법
1. 각 `tasks/*.md`의 프롬프트를 에이전트에 단독 컨텍스트로 제시 (CLAUDE.md만 주고 정답 노출 금지)
2. 산출물을 pass criteria로 채점 — 일부는 자동 검증 가능:
   - 문서 경로 무결성: `dart run tool/verify_doc_paths.dart`
   - 정적 분석: `flutter analyze`
   - 테스트: `flutter test`
3. 결과를 `agent-results.json`에 기록 (수동 채점 항목은 reviewer 표기)

## 채점 기준
- 각 task는 pass/fail. criteria **전부 충족 시에만 pass**
- `pass_rate = passed / total`. 컨텍스트 변경 전후로 비교해 회귀/개선 판단
- 모델·날짜를 함께 기록해 재현성 확보 (agent session log 단서)

## 해석
- pass-rate 상승 = 문서가 에이전트를 올바른 패턴으로 유도함
- 특정 task 반복 실패 = 해당 영역 컨텍스트/ADR 보강 필요 신호
