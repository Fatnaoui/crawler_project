#!/usr/bin/env bash
set -euo pipefail

# =========================
# Goal: Create .warc.gz files (for downstream text extraction) using wget recursion.
# Supports:
# - Single seed URL OR a seeds file (one URL per line)
# Notes:
# - Stays on the seed host by default (no cross-host traversal).
# - Uses reject-regex to avoid common crawler traps.
# - Uses quota + warc rotation to keep outputs bounded.
# - Uses --delete-after to avoid storing a local mirror long-term.
# - Moves wget-generated *-meta.warc.gz files under $OUTDIR/_meta/
# - This work was done in MNRT, a team of 4 members supervised by Mr. Abderrahman 
# - use this website to check your crawling: https://replayweb.page/

usage() {
  cat >&2 <<'EOF'
Usage:
  ./crawl_script.sh <seed_url|seeds_file> <prefix>

Examples:
  crawl_script.sh file.txt <prefix>
  crawl_script.sh "https://example.com/" <prefix>
  DEPTH=4 ROBOTS=on ./crawl_script.sh "https://example.com/" <prefix>

Seeds file format:
  - One URL per line
  - Blank lines are ignored
  - Lines starting with # are ignored

Environment variables (tunable):
  DEPTH           Recursion depth (default: 3)
  WAIT_SECS       Polite delay between requests (default: 1)
  RANDOM_WAIT     1 to add jitter (default: 1)
  TIMEOUT_SECS    Network timeout per request (default: 30)
  TRIES           Retry attempts per URL (default: 3)
  MAX_REDIRECT    Max redirects to follow per URL (default: 10)
  QUOTA           Total download cap (default: 0 = unlimited), e.g., 2G, 500M
  ROBOTS          Respect robots.txt: on|off (default: off)
  UA              User-Agent string (default: Wget-WARC/1.0 (project: warc-crawl))
  REJECT_REGEX    URLs to exclude (default: common traps)
  DELETE_AFTER    1 to delete downloaded mirror files (default: 1)

  WARC_MAX_SIZE   Rotate WARC chunks at this size (default: 1G)
  WARC_TEMPDIR    Temp dir for WARC assembly (default: crawl_out/<prefix>/.warc-tmp)
  KEEP_TEMPDIR    1 to keep temp dir after exit (default: 0)

  LOGFILE         If set, write wget logs to this file (default: crawl_out/<prefix>/logs/<prefix>.log)
  REJECTED_LOG    If set, write rejected URLs to this file (default: crawl_out/<prefix>/logs/<prefix>.rejected.log)

Exit codes:
  2 - usage / input error
EOF
}

die() {
  local msg="${1:-Unknown error}"
  local code="${2:-2}"
  echo "Error: $msg" >&2
  echo >&2
  usage
  exit "$code"
}

extract_host() {
  local url="$1"
  url="${url#http://}"
  url="${url#https://}"
  url="${url%%/*}"
  printf '%s' "$url"
}

first_seed_from_file() {
  local f="$1"
  grep -E -v '^[[:space:]]*($|#)' "$f" | head -n 1
}

# -------------------------
# Parse inputs (URL or file)
# -------------------------
[[ $# -eq 2 ]] || die "Expected exactly 2 arguments: <seed_url|seeds_file> <prefix>"

TARGET="$1"
PREFIX="$2"
OUTDIR="crawl_out/$PREFIX"

[[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]] || die "Invalid prefix. Use only A-Za-z0-9._- (got: $PREFIX)"


MODE=""         # url|file
SEED_URL=""
SEEDS_FILE=""

if [[ "$TARGET" =~ ^https?:// ]]; then
  MODE="url"
  SEED_URL="$TARGET"
elif [[ -f "$TARGET" ]]; then
  MODE="file"
  SEEDS_FILE="$TARGET"
else
  die "First argument must be an http(s) URL or an existing file path (got: $TARGET)"
fi

# Validate seed(s) and derive reference host for logs
HOST=""
if [[ "$MODE" == "url" ]]; then
  HOST="$(extract_host "$SEED_URL")"
else
  FIRST_URL="$(first_seed_from_file "$SEEDS_FILE" || true)"
  [[ -n "${FIRST_URL:-}" ]] || die "Seeds file is empty (or only comments): $SEEDS_FILE"
  [[ "$FIRST_URL" =~ ^https?:// ]] || die "Seeds file first URL must start with http(s):// (got: $FIRST_URL)"
  HOST="$(extract_host "$FIRST_URL")"

  # Optional warning if seeds file contains multiple hosts (allowed; just a warning)
  unique_hosts_count="$(
    grep -E -v '^[[:space:]]*($|#)' "$SEEDS_FILE" \
      | sed -E 's#^[a-zA-Z]+://([^/]+).*#\1#' \
      | sort -u | wc -l | tr -d ' '
  )"
  if [[ "${unique_hosts_count:-1}" -gt 1 ]]; then
    echo "Warning: seeds file contains multiple hosts ($unique_hosts_count). This can expand scope unintentionally." >&2
  fi
fi

# -------------------------
# Defaults (can be overridden via env)
# -------------------------
DEPTH="${DEPTH:-3}"
WAIT_SECS="${WAIT_SECS:-1}"
RANDOM_WAIT="${RANDOM_WAIT:-1}"
TIMEOUT_SECS="${TIMEOUT_SECS:-30}"
TRIES="${TRIES:-3}"
MAX_REDIRECT="${MAX_REDIRECT:-10}"
QUOTA="${QUOTA:-0}"
ROBOTS="${ROBOTS:-off}"
UA="${UA:-Wget-WARC/1.0 (project: warc-crawl)}"
DELETE_AFTER="${DELETE_AFTER:-1}"

WARC_MAX_SIZE="${WARC_MAX_SIZE:-1G}"
WARC_TEMPDIR="${WARC_TEMPDIR:-$OUTDIR/.warc-tmp}"
KEEP_TEMPDIR="${KEEP_TEMPDIR:-0}"

mkdir -p "$OUTDIR/$PREFIX" "$OUTDIR/logs" "$OUTDIR/files" "$WARC_TEMPDIR"

LOGFILE="${LOGFILE:-$OUTDIR/logs/$PREFIX.log}"
REJECTED_LOG="${REJECTED_LOG:-$OUTDIR/logs/$PREFIX.rejected.log}"

# Keep this regex SINGLE-LINE to avoid accidental newlines breaking POSIX ERE.
DEFAULT_REJECT_REGEX="$(
  printf '%s' \
'/(login|logout|signin|signout|signup|cart|checkout)(/|$)' \
'|/wp-admin(/|$)' \
'|([?&](session|sid|phpsessid|jsessionid|token)=)' \
'|([?&](utm_[[:alnum:]_]+|ref|fbclid|gclid)=)' \
'|([?&](sort|filter)=)' \
'|\.(png|jpe?g|gif|svg|webp|ico|css|js|woff2?|ttf|eot|otf|mp4|webm|mp3|wav|avi|mov|zip|rar|7z|tar|gz|bz2|xz|pdf)(\?|$)' \
'|([?&](format|ext|type|output)(=)?(png|jpe?g|gif|svg|webp|pdf|mp4|mp3))([&#]|$)'
)"

REJECT_REGEX="${REJECT_REGEX:-$DEFAULT_REJECT_REGEX}"

# -------------------------
# Validate basics
# -------------------------
[[ "$DEPTH" =~ ^[0-9]+$ ]] || die "DEPTH must be an integer (got: $DEPTH)"
[[ "$WAIT_SECS" =~ ^[0-9]+$ ]] || die "WAIT_SECS must be an integer (got: $WAIT_SECS)"
[[ "$TIMEOUT_SECS" =~ ^[0-9]+$ ]] || die "TIMEOUT_SECS must be an integer (got: $TIMEOUT_SECS)"
[[ "$TRIES" =~ ^[0-9]+$ ]] || die "TRIES must be an integer (got: $TRIES)"
[[ "$MAX_REDIRECT" =~ ^[0-9]+$ ]] || die "MAX_REDIRECT must be an integer (got: $MAX_REDIRECT)"
[[ "$ROBOTS" == "on" || "$ROBOTS" == "off" ]] || die "ROBOTS must be 'on' or 'off' (got: $ROBOTS)"
[[ "$RANDOM_WAIT" == "0" || "$RANDOM_WAIT" == "1" ]] || die "RANDOM_WAIT must be 0 or 1 (got: $RANDOM_WAIT)"
[[ "$DELETE_AFTER" == "0" || "$DELETE_AFTER" == "1" ]] || die "DELETE_AFTER must be 0 or 1 (got: $DELETE_AFTER)"
[[ "$KEEP_TEMPDIR" == "0" || "$KEEP_TEMPDIR" == "1" ]] || die "KEEP_TEMPDIR must be 0 or 1 (got: $KEEP_TEMPDIR)"

# -------------------------
# Cleanup (best effort)
# -------------------------
cleanup() {
  if [[ "$KEEP_TEMPDIR" != "1" ]]; then
    rm -rf "$WARC_TEMPDIR" || true
  fi
}
trap cleanup EXIT

# -------------------------
# Build wget args
# -------------------------
WARC_BASE="$OUTDIR/$PREFIX/$PREFIX"

WGET_ARGS=(
  --recursive
  --level="$DEPTH"
  --no-parent

  --wait="$WAIT_SECS"
  --timeout="$TIMEOUT_SECS"
  --tries="$TRIES"
  --max-redirect="$MAX_REDIRECT"
  --user-agent="$UA"
  --execute="robots=$ROBOTS"

  --reject-regex="$REJECT_REGEX"

  --warc-file="$WARC_BASE"
  --warc-max-size="$WARC_MAX_SIZE"
  --warc-tempdir="$WARC_TEMPDIR"

  -o "$LOGFILE"
  --rejected-log="$REJECTED_LOG"

  --directory-prefix="$OUTDIR/files"
)

if [[ "$RANDOM_WAIT" == "1" ]]; then
  WGET_ARGS+=( --random-wait )
fi

if [[ "$QUOTA" != "0" ]]; then
  WGET_ARGS+=( --quota="$QUOTA" )
fi

if [[ "$DELETE_AFTER" == "1" ]]; then
  WGET_ARGS+=( --delete-after )
fi

# -------------------------
# Run
# -------------------------
echo "Mode          : $MODE"
echo "Host (ref)    : $HOST"
echo "Output dir    : $OUTDIR"
echo "Prefix        : $PREFIX"
echo "WARC base     : $WARC_BASE"
echo "Log file      : $LOGFILE"
echo "Rejected log  : $REJECTED_LOG"
echo "Depth         : $DEPTH"
echo "Wait/random   : $WAIT_SECS / $RANDOM_WAIT"
echo "Timeout/tries : $TIMEOUT_SECS / $TRIES"
echo "Quota         : $QUOTA"
echo "Robots        : $ROBOTS"
echo "Delete-after  : $DELETE_AFTER"
echo "WARC max size : $WARC_MAX_SIZE"

set +e
if [[ "$MODE" == "url" ]]; then
  echo "Seed URL      : $SEED_URL"
  echo
  echo "The process is starting ...."
  wget "${WGET_ARGS[@]}" "$SEED_URL"
else
  echo "Seeds file    : $SEEDS_FILE"
  echo
  echo "The process is starting ...."
  wget "${WGET_ARGS[@]}" --input-file="$SEEDS_FILE"
fi
set -e

shopt -s nullglob
meta_files=( "$OUTDIR/$PREFIX/${PREFIX}"*-meta.warc.gz )

if ((${#meta_files[@]})); then
  mkdir -p "$OUTDIR/_meta"
  mv -f -- "${meta_files[@]}" "$OUTDIR/_meta/" || true
fi

shopt -u nullglob

echo "Done Crawling"
echo
echo "WARC files created under: $OUTDIR/$PREFIX/"
ls -lh "$OUTDIR/$PREFIX/" | sed -n '1,200p'




