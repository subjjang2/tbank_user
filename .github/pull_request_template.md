## 변경 요약
<!-- 무엇을, 왜 바꿨는지 1-3줄 -->

## 관련 이슈 / ADR
<!-- 아키텍처 결정이 바뀌면 docs/adr/ 에 ADR 추가·갱신 -->

## 체크리스트
- [ ] `flutter analyze` 통과 (경고 없음)
- [ ] `flutter test` 통과
- [ ] freezed/json_serializable 모델 변경 시 `dart run build_runner build --delete-conflicting-outputs` 실행
- [ ] 컨텍스트/문서 경로 검증: `dart run tool/verify_doc_paths.dart` 통과 (깨진 참조 0)
- [ ] 구조·결정 변경 시 `CLAUDE.md` / `docs/ARCHITECTURE.md` / `docs/adr/` 갱신
- [ ] 신규 코드는 [`docs/adr/0004`](../docs/adr/0004-known-duplication-debt.md) 통일 방향 준수 (모델·에러·네비게이션)

## 검토 노트
<!-- 리뷰어가 집중해서 볼 부분 -->
