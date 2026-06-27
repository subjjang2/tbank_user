#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): 수정된 Dart 파일 포맷 + 분석.
# 실행 이후 단계이므로 파싱 실패는 차단이 아니라 skip(exit 0).
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0

input=$(cat)

# tool_input.file_path 추출. jq → python3 → python → py 순. 포스트 훅이므로
# 파서가 없거나 파싱 실패하면 차단이 아니라 skip(exit 0).
file=""
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""') || exit 0
else
  for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1; then
      file=$(printf '%s' "$input" | "$py" -c "import sys,json
try:
    print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))
except Exception:
    pass") || exit 0
      break
    fi
  done
fi
[ -z "$file" ] && exit 0

case "$file" in
  *.g.dart|*.freezed.dart) exit 0 ;;   # 생성 파일 제외
  *.dart) ;;
  *) exit 0 ;;                          # Dart 외 파일 무시
esac

dart format "$file" >/dev/null || true
dart analyze "$file" || true            # 분석 결과는 정보성(빌드 차단 안 함)
exit 0
