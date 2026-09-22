#!/usr/bin/env bash
set -euo pipefail
set +x

LOGCLI_ADDR="${LOGCLI_ADDR:-http://127.0.0.1:3100}"
LOGCLI_OUTPUT="${LOGCLI_OUTPUT:-raw}"
LOGCLI_LIMIT="${LOGCLI_LIMIT:-0}"
LOGCLI_DIRECTION="${LOGCLI_DIRECTION:-forward}"
BASE_QUERY="${BASE_QUERY:-{job=~\".+\"}}"

# Set the archive password here, or pass it with LOGCLI_EXPORT_PASSWORD.
# Keep shell tracing disabled so this value is not printed by the shell.
ARCHIVE_PASSWORD="${LOGCLI_EXPORT_PASSWORD:-CHANGE_ME_SET_PASSWORD_HERE}"
INNER_LOG_NAME="${INNER_LOG_NAME:-exported.log}"
SEVENZA_BIN="${SEVENZA_BIN:-7za}"

usage() {
  printf '%s\n' \
    'Usage:' \
    '  ./export_log_archive_query.sh FROM TO ARCHIVE_7Z EXTRA_QUERY' \
    '' \
    'Examples:' \
    '  ./export_log_archive_query.sh "2026-09-22T00:00:00Z" "2026-09-22T01:00:00Z" "./logs/error.7z" '"'"'|= "error"'"'"'' \
    '  ./export_log_archive_query.sh "2026-09-22T00:00:00Z" "2026-09-22T01:00:00Z" "./logs/nginx-error.7z" '"'"'{app="nginx"} |= "error"'"'"''
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_archive_password() {
  if [[ -z "$ARCHIVE_PASSWORD" || "$ARCHIVE_PASSWORD" == "CHANGE_ME_SET_PASSWORD_HERE" ]]; then
    die "Set ARCHIVE_PASSWORD in this script or export LOGCLI_EXPORT_PASSWORD before using this script."
  fi
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
  local archive="$3"
  local extra_query="$4"
  local query

  require_command logcli
  require_command "$SEVENZA_BIN"
  require_archive_password
  mkdir -p -- "$(dirname -- "$archive")"

  if [[ -e "$archive" ]]; then
    die "Archive already exists: $archive"
  fi

  query="$(build_query "$extra_query")"

  logcli --addr="$LOGCLI_ADDR" query \
    --from="$from" \
    --to="$to" \
    --output="$LOGCLI_OUTPUT" \
    --limit="$LOGCLI_LIMIT" \
    "--$LOGCLI_DIRECTION" \
    "$query" | "$SEVENZA_BIN" a \
    -t7z \
    -mx=9 \
    -mhe=on \
    -p"$ARCHIVE_PASSWORD" \
    "$archive" \
    -si"$INNER_LOG_NAME" >/dev/null
}

main "$@"
