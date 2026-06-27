# Task: 문서 무결성 유지

## Prompt (에이전트에 제시)
"`lib/repository/`에 새 파일 `loan_repository.dart`를 추가했다. 관련 컨텍스트 문서를 갱신하라."

## Pass Criteria (golden)
- [ ] `lib/repository/CLAUDE.md`의 Key Files에 새 repository 반영
- [ ] 문서가 가리키는 경로가 모두 유효: `dart run tool/verify_doc_paths.dart` 통과 (exit 0)
- [ ] 깨진 링크/존재하지 않는 경로 0건 (hallucinated path 금지)
- [ ] 구조 변경이 의존성에 영향 시 `docs/ARCHITECTURE.md` 반영 검토

## 측정 포인트
자동 검증(`verify_doc_paths.dart`)으로 pass/fail 결정론적 판정 가능. 에이전트가 코드 변경과 문서를 동기화하는 습관을 갖는지.
