#!/usr/bin/env bash
set -euo pipefail
set +x

LOGCLI_ADDR="${LOGCLI_ADDR:-http://127.0.0.1:3100}"
LOGCLI_OUTPUT="${LOGCLI_OUTPUT:-raw}"
LOGCLI_LIMIT="${LOGCLI_LIMIT:-0}"
LOGCLI_DIRECTION="${LOGCLI_DIRECTION:-forward}"
BASE_QUERY="${BASE_QUERY:-{job=~\".+\"}}"

usage() {
  printf '%s\n' \
    'Usage:' \
    '  ./export_log_plain_query.sh FROM TO OUTFILE EXTRA_QUERY' \
    '' \
    'Examples:' \
    '  ./export_log_plain_query.sh "2026-09-22T00:00:00Z" "2026-09-22T01:00:00Z" "./logs/error.log" '"'"'|= "error"'"'"'' \
    '  ./export_log_plain_query.sh "2026-09-22T00:00:00Z" "2026-09-22T01:00:00Z" "./logs/nginx.log" '"'"'{app="nginx"} |= "500"'"'"''
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

build_query() {
  local extra_query="$1"

  if [[ "$extra_query" == \{* ]]; then
    printf '%s\n' "$extra_query"
    return
  fi

  printf '%s %s\n' "$BASE_QUERY" "$extra_query"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    usage
    exit 0
  fi

  [[ $# -eq 4 ]] || { usage; exit 2; }

  local from="$1"
  local to="$2"
  local outfile="$3"
  local extra_query="$4"
  local query

  require_command logcli
  mkdir -p -- "$(dirname -- "$outfile")"
  query="$(build_query "$extra_query")"

  logcli --addr="$LOGCLI_ADDR" query \
    --from="$from" \
    --to="$to" \
    --output="$LOGCLI_OUTPUT" \
    --limit="$LOGCLI_LIMIT" \
    "--$LOGCLI_DIRECTION" \
    "$query" >"$outfile"
}

main "$@"
