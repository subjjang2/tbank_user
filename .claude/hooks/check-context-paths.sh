#!/usr/bin/env bash
# check-context: 컨텍스트/문서(CLAUDE.md, docs/, ADR)의 경로 참조가 실제
# 존재하는지 검증한다. 깨진 참조가 있으면 비정상 종료한다.
#
# 로컬 자동화(권장): .claude/settings.json 의 PostToolUse hook 으로 등록하면
# Edit/Write 후 자동 실행된다. git pre-commit 으로 연결해도 된다.
#
#   "hooks": {
#     "PostToolUse": [
#       { "matcher": "Edit|Write",
#         "hooks": [{ "type": "command",
#                     "command": "bash .claude/hooks/check-context-paths.sh" }] }
#     ]
#   }

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0

# 깨진 참조가 있으면 exit 2 로 종료해 stderr 를 Claude 에 피드백한다.
# (dart 의 기본 종료코드 1 은 PostToolUse 에서 모델에 전달되지 않음)
if ! out=$(dart run tool/verify_doc_paths.dart 2>&1); then
  printf '%s\n' "$out" >&2
  exit 2
fi
printf '%s\n' "$out"
