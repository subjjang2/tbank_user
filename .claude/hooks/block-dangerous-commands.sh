#!/usr/bin/env bash
# PreToolUse(Bash): 파괴적 명령 차단. exit 2 → 도구 호출 차단 + stderr를 Claude에 전달.
# 파싱 실패 시 fail-closed(차단)로 동작해 차단기가 조용히 무력화되지 않도록 한다.
set -uo pipefail   # -e 제외: 비매칭 grep(exit 1)으로 조기 종료되지 않도록 수동 처리

input=$(cat)

# tool_input 의 필드 1개를 추출. jq → python3 → python → py 순으로 가용 파서 사용.
# 반환 127 = 파서 없음, 그 외 비0 = JSON 파싱 실패.
read_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg f "$1" '.tool_input[$f] // ""'
    return $?
  fi
  local py
  for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1; then
      printf '%s' "$input" | "$py" -c "import sys,json
try:
    print(json.load(sys.stdin).get('tool_input',{}).get('$1',''))
except Exception:
    sys.exit(3)"
      return $?
    fi
  done
  return 127
}

# JSON 파싱 실패/파서 부재 → fail-closed(차단). 보안 가드는 무력화보다 차단이 안전.
cmd=$(read_field command); rc=$?
if [ "$rc" -eq 127 ]; then
  echo "🚫 JSON 파서(jq/python3) 없음 — 안전을 위해 명령을 차단합니다." >&2; exit 2
elif [ "$rc" -ne 0 ]; then
  echo "🚫 훅 입력 파싱 실패 — 안전을 위해 명령을 차단합니다." >&2; exit 2
fi

norm=$(printf '%s' "$cmd" | tr -s '[:space:]' ' ')
# Dequote: strip quotes/backslashes so shell-equivalent evasions collapse to
# their effective form — "rm" -rf, r\m, rm "-rf", "git" push 등. 셸이 동일하게
# 평가하는 형태를 매칭하기 위함. (echo "rm -rf /" 처럼 리터럴 문자열까지
# 차단될 수 있으나, 안전 가드에서는 과차단이 누락보다 안전하므로 허용.)
deq=$(printf '%s' "$norm" | tr -d "\"'\\\\")
block() { echo "🚫 차단된 위험 명령($1): $cmd" >&2; exit 2; }

# rm 재귀 삭제: \rm, /bin/rm, path/rm 까지. 재귀 플래그(-r/-R/-rf/--recursive) 있으면 차단
if printf '%s' "$deq" | grep -qE '(^|[^[:alnum:]_])rm[[:space:]]'; then
  if printf '%s' "$deq" | grep -qE 'rm[[:space:]]+([^;&|]*[[:space:]])?(-[[:alnum:]]*[rR]|--recursive)'; then
    block "rm 재귀 삭제"
  fi
fi

# git push 강제 푸시: --force / -f / +refspec. 전역 옵션(-C, --no-pager 등)이
# git 과 push 사이에 끼어도 매칭. 단 --force-with-lease 는 허용.
if printf '%s' "$deq" | grep -qE '(^|[;&|(]|[[:space:]])git[[:space:]][^;&|]*push\b'; then
  if printf '%s' "$deq" | grep -qE '(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$)|push[[:space:]][^;&|]*[[:space:]]\+[^[:space:]])'; then
    block "git push --force"
  fi
fi

exit 0
