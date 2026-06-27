# tool/ — 개발 도구

프로젝트 유지보수용 Dart 스크립트.

## Key Files
- `verify_doc_paths.dart` — 컨텍스트/문서(CLAUDE.md·docs/·ADR)의 마크다운 링크가 실제 파일을 가리키는지 검증. 깨진 참조 발견 시 exit 1

## Common Change Patterns
```bash
dart run tool/verify_doc_paths.dart   # 문서 경로 검증
```
- CI 워크플로우(`context-check.yml`)와 로컬 hook(`check-context-paths.sh`)이 이 스크립트를 호출

## Dependencies
- `dart:io`만 사용 (외부 패키지 없음). 대상: `../CLAUDE.md`, `../docs/`, `../lib/`, `../test/`
