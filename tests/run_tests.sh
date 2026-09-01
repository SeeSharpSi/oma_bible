#!/usr/bin/env bash
# Regression tests for bsb book-name preprocessing.
# Focus:
#   - Isaiah aliases (is/isa/isaiah, any case) must resolve to book 23 and
#     must not be mangled by Roman numeral handling into 1 Samuel (book 9).
#   - Roman numbered-book forms (I Jn, IJohn, II Sam, IISamuel) must still work.
#   - First/Second/Third and 1st/2nd/3rd ordinals must still work.
#   - Basic CLI behavior (flags, ranges) must remain intact.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BSB="$ROOT/bsb"
DB="$ROOT/BSB.sqlite"

if [[ ! -x "$BSB" ]]; then
  echo "FAIL: bsb script not found/executable at $BSB" >&2
  exit 1
fi
if [[ ! -f "$DB" ]]; then
  echo "FAIL: BSB.sqlite not found at $DB" >&2
  exit 1
fi

PASS=0
FAIL=0

# verse text with "chapter:verse " prefix, exactly as bsb prints it
db_ref() {
  sqlite3 "file:$DB?mode=ro" \
    "SELECT chapter || ':' || verse || ' ' || text FROM verses WHERE book=$1 AND chapter=$2 AND verse=$3;"
}

# verse text without reference prefix (for -n/--no-reference mode)
db_text() {
  sqlite3 "file:$DB?mode=ro" \
    "SELECT text FROM verses WHERE book=$1 AND chapter=$2 AND verse=$3;"
}

# check_eq <description> <expected> <bsb args...>
# asserts exit 0, empty stderr (no warnings), and exact stdout match
check_eq() {
  local desc="$1" expected="$2"
  shift 2
  local errfile out rc
  errfile="$(mktemp)"
  out="$("$BSB" "$@" 2>"$errfile")"
  rc=$?
  local err
  err="$(cat "$errfile")"
  rm -f "$errfile"
  if (( rc != 0 )); then
    echo "FAIL: $desc (exit code $rc)"
    [[ -n "$err" ]] && echo "  stderr: $err"
    FAIL=$((FAIL+1))
    return
  fi
  if [[ -n "$err" ]]; then
    echo "FAIL: $desc (unexpected stderr/warning)"
    echo "  stderr: $err"
    FAIL=$((FAIL+1))
    return
  fi
  if [[ "$out" != "$expected" ]]; then
    echo "FAIL: $desc (output mismatch)"
    echo "  expected: $expected"
    echo "  got:      $out"
    FAIL=$((FAIL+1))
    return
  fi
  PASS=$((PASS+1))
}

# check_ok <description> <bsb args...>
# asserts exit 0, non-empty stdout, empty stderr (no warnings)
check_ok() {
  local desc="$1"
  shift
  local errfile out rc
  errfile="$(mktemp)"
  out="$("$BSB" "$@" 2>"$errfile")"
  rc=$?
  local err
  err="$(cat "$errfile")"
  rm -f "$errfile"
  if (( rc != 0 )); then
    echo "FAIL: $desc (exit code $rc)"
    [[ -n "$err" ]] && echo "  stderr: $err"
    FAIL=$((FAIL+1))
    return
  fi
  if [[ -z "$out" ]]; then
    echo "FAIL: $desc (empty output)"
    [[ -n "$err" ]] && echo "  stderr: $err"
    FAIL=$((FAIL+1))
    return
  fi
  if [[ -n "$err" ]]; then
    echo "FAIL: $desc (unexpected stderr/warning)"
    echo "  stderr: $err"
    FAIL=$((FAIL+1))
    return
  fi
  PASS=$((PASS+1))
}

# --- Isaiah aliases must resolve to book 23 / chapter 40, no book-9 warning ---
check_eq "is 40:1 resolves Isaiah (book 23)" "$(db_ref 23 40 1)" is 40:1
check_eq "isa 40:1 resolves Isaiah (book 23)" "$(db_ref 23 40 1)" isa 40:1
check_eq "isaiah 40:1 resolves Isaiah (book 23)" "$(db_ref 23 40 1)" isaiah 40:1
check_eq "IS 40:1 (uppercase alias) resolves Isaiah" "$(db_ref 23 40 1)" IS 40:1
check_eq "Isaiah 40:1 (mixed case) resolves Isaiah" "$(db_ref 23 40 1)" Isaiah 40:1
check_ok "is 40 (full chapter, no warning)" is 40
check_ok "isa 40 (full chapter, no warning)" isa 40
check_ok "isaiah 40 (full chapter, no warning)" isaiah 40

# --- Roman numbered-book forms must still resolve ---
check_eq "I Jn 3:16 resolves 1 John (book 62)" "$(db_ref 62 3 16)" I Jn 3:16
check_eq "IJohn 1:1 (glued) resolves 1 John (book 62)" "$(db_ref 62 1 1)" IJohn 1:1
check_eq "II Sam 1:1 resolves 2 Samuel (book 10)" "$(db_ref 10 1 1)" II Sam 1:1
check_eq "IISamuel 1:1 (glued) resolves 2 Samuel (book 10)" "$(db_ref 10 1 1)" IISamuel 1:1
check_eq "II Kings 3:1 resolves 2 Kings (book 12)" "$(db_ref 12 3 1)" II Kings 3:1
check_eq "iisam 1:1 (lowercase glued) resolves 2 Samuel" "$(db_ref 10 1 1)" iisam 1:1

# --- First/Second/Third and 1st/2nd/3rd ordinals preserved ---
check_eq "First Samuel 3:1 resolves 1 Samuel (book 9)" "$(db_ref 9 3 1)" First Samuel 3:1
check_eq "1st Samuel 3:1 resolves 1 Samuel (book 9)" "$(db_ref 9 3 1)" 1st Samuel 3:1
check_eq "1 Samuel 3:1 resolves 1 Samuel (book 9)" "$(db_ref 9 3 1)" 1 Samuel 3:1
check_eq "Second Timothy 1:7 resolves 2 Timothy (book 55)" "$(db_ref 55 1 7)" Second Timothy 1:7
check_eq "2nd Timothy 1:7 resolves 2 Timothy (book 55)" "$(db_ref 55 1 7)" 2nd Timothy 1:7
check_eq "Third John 1:4 resolves 3 John (book 64)" "$(db_ref 64 1 4)" Third John 1:4
check_eq "3rd John 1:4 resolves 3 John (book 64)" "$(db_ref 64 1 4)" 3rd John 1:4

# --- basic CLI behavior intact ---
check_eq "John 1:1 (plain name)" "$(db_ref 43 1 1)" John 1:1
check_eq "lk 1:9 (abbreviation)" "$(db_ref 42 1 9)" lk 1:9
check_eq "-n omits reference prefix" "$(db_text 43 3 16)" -n John 3:16
check_eq "--no-reference long flag" "$(db_text 20 3 5)" --no-reference Proverbs 3:5
check_eq "Luke 2:3-5:12 range runs without warning" "$("$BSB" Luke 2:3-5:12)" Luke 2:3-5:12
check_eq "multiple refs: Luke 3:1-2 John 5:1" "$("$BSB" Luke 3:1-2 John 5:1)" Luke 3:1-2 John 5:1
check_eq "digit-glued form 1Sam 3:1" "$(db_ref 9 3 1)" 1Sam 3:1

echo
echo "passed: $PASS, failed: $FAIL"
if (( FAIL > 0 )); then
  exit 1
fi
