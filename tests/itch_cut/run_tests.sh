#!/usr/bin/env bash
#
# End-to-end test for itch_cut
#
# NOTE: Claude wrote this, approved by author.
# Usage:
#   run_tests.sh <itch_cut binary>
#   run_tests.sh <itch_cut binary> <ITCH source file> <committed fixture> <fixture message count>
# 
# With one argument, only the tests run
# With four, the real-data tests run, including re-cutting the fixture and
# checking it is byte-identical to the committed one.
#
# It exits 0 if every test passes, 1 if any fails, 2 on bad usage or bad test inputs.

set -u

if [ $# -ne 1 ] && [ $# -ne 4 ]; then
    echo "usage: $0 <itch_cut> [<ITCH source> <committed fixture> <message count>]" >&2
    exit 2
fi

BIN=$(realpath "$1")
DATA=""
FIXTURE=""
COUNT=""
if [ $# -eq 4 ]; then
    DATA=$(realpath "$2")
    FIXTURE=$(realpath "$3")
    COUNT=$4
fi

[ -x "$BIN" ] || { echo "not an executable: $BIN" >&2; exit 2; }

# All work happens in a throwaway directory that is removed on exit.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 2

PASSES=0
FAILS=0
MSG=""
RC=0

pass() {
    printf 'PASS  %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL  %s: %s\n' "$1" "$2"
    if [ -n "$MSG" ]; then
        printf '%s\n' "$MSG" | sed 's/^/      | /'
    fi
    FAILS=$((FAILS + 1))
}

# Run itch_cut; capture stdout+stderr in MSG and the exit code in RC.
run_cut() {
    MSG=$("$BIN" "$@" 2>&1)
    RC=$?
}

# ASan/LSan print "...Sanitizer", UBSan prints "runtime error".
sanitizer_fired() {
    grep -Eq 'Sanitizer|runtime error' <<<"$MSG"
}

# expect_fail NAME PATTERN INPUT LIMIT
# Expects exit 1, output matching PATTERN (case-insensitive extended regex),
# no sanitizer report, and neither out.bin nor out.bin.tmp afterwards.
expect_fail() {
    local name=$1 pattern=$2 input=$3 limit=$4
    rm -f out.bin out.bin.tmp
    run_cut "$input" out.bin "$limit"
    if sanitizer_fired;                     then fail "$name" "sanitizer report"; return; fi
    if [ "$RC" -ne 1 ];                     then fail "$name" "exit $RC, expected 1"; return; fi
    if ! grep -Eqi -- "$pattern" <<<"$MSG"; then fail "$name" "output does not match /$pattern/"; return; fi
    if [ -e out.bin ];                      then fail "$name" "out.bin was created"; return; fi
    if [ -e out.bin.tmp ];                  then fail "$name" "out.bin.tmp left behind"; return; fi
    pass "$name"
}

# expect_ok NAME INPUT LIMIT
# Expects exit 0, out.bin present, no out.bin.tmp, no sanitizer report.
# Returns 0 if all hold, so the caller can add content checks and call pass.
# Does NOT delete out.bin first: some tests pre-create it on purpose.
expect_ok() {
    local name=$1 input=$2 limit=$3
    rm -f out.bin.tmp
    run_cut "$input" out.bin "$limit"
    if sanitizer_fired;    then fail "$name" "sanitizer report"; return 1; fi
    if [ "$RC" -ne 0 ];    then fail "$name" "exit $RC, expected 0"; return 1; fi
    if [ ! -e out.bin ];   then fail "$name" "out.bin missing"; return 1; fi
    if [ -e out.bin.tmp ]; then fail "$name" "out.bin.tmp left behind"; return 1; fi
    return 0
}

# Refuse to run if a test input is not the size it is meant to be:
# verify the test input before blaming the code.
check_size() {
    local actual
    actual=$(stat -c %s "$1")
    if [ "$actual" -ne "$2" ]; then
        echo "BAD TEST INPUT: $1 is $actual bytes, expected $2" >&2
        exit 2
    fi
}

# ---------------------------------------------------------------------------
# Synthetic inputs: every byte is known.
# ---------------------------------------------------------------------------
: > t_empty.bin                                                        # 0 bytes
printf '\x00'      > t_half_prefix.bin                                 # half a length prefix
printf '\x00\x0cS' > t_short_body.bin                                  # says 12 bytes, has 1
printf '\x00\x00'  > t_zero_len.bin                                    # length 0
{ printf '\x00\x0dS'; head -c 12 /dev/zero; }             > t_bad_len.bin    # first msg 13 bytes, not 12
{ printf '\x00\x0cX'; head -c 11 /dev/zero; }             > t_bad_type.bin   # type X, not S
{ printf '\x00\x0cS'; head -c 10 /dev/zero; printf 'Q'; } > t_bad_code.bin   # event code Q, not O
{ printf '\x00\x0cS'; head -c 10 /dev/zero; printf 'O'; } > t_good_one.bin   # one valid S/12/O message
{ cat t_good_one.bin; printf '\x00'; }                          > t_half_second.bin   # 2nd prefix cut, offset 14
{ cat t_good_one.bin; printf '\x00\x27'; head -c 5 /dev/zero; } > t_trunc_second.bin  # 2nd msg says 39, has 5

check_size t_empty.bin         0
check_size t_half_prefix.bin   1
check_size t_short_body.bin    3
check_size t_zero_len.bin      2
check_size t_bad_len.bin      15
check_size t_bad_type.bin     14
check_size t_bad_code.bin     14
check_size t_good_one.bin     14
check_size t_half_second.bin  15
check_size t_trunc_second.bin 21

# ---------------------------------------------------------------------------
echo "== arguments =="
# ---------------------------------------------------------------------------
rm -f out.bin out.bin.tmp
run_cut t_good_one.bin out.bin          # only 2 arguments
if [ "$RC" -eq 1 ] && grep -qi 'usage' <<<"$MSG" && [ ! -e out.bin ] && [ ! -e out.bin.tmp ]; then
    pass "wrong argument count"
else
    fail "wrong argument count" "expected exit 1, a usage message, and no files"
fi

expect_fail "limit: letters"       'error'         t_good_one.bin     abc
expect_fail "limit: zero"          'error'         t_good_one.bin     0
expect_fail "limit: negative"      'error'         t_good_one.bin     -5
expect_fail "limit: trailing junk" 'error'         t_good_one.bin     10abc
expect_fail "input: missing file"  'no such file'  does_not_exist.bin 10

# ---------------------------------------------------------------------------
echo "== framing and truncation =="
# ---------------------------------------------------------------------------
expect_fail "empty input"                   'wrote 0 messages'          t_empty.bin        10
expect_fail "truncated prefix at offset 0"  'truncated prefix.* 0$'     t_half_prefix.bin  10
expect_fail "truncated body at offset 0"    'message truncated.* 0$'    t_short_body.bin   10
expect_fail "zero-length message"           'zero'                      t_zero_len.bin     10
expect_fail "truncated prefix at offset 14" 'truncated prefix.* 14$'    t_half_second.bin  10
expect_fail "truncated body at offset 14"   'message truncated.* 14$'   t_trunc_second.bin 10
expect_fail "short input (1 of 10)"         'wrote 1 messages'          t_good_one.bin     10

# ---------------------------------------------------------------------------
echo "== first message must be S / length 12 / event code O =="
# ---------------------------------------------------------------------------
expect_fail "first message: wrong length"     'length'      t_bad_len.bin  10
expect_fail "first message: wrong type"       'type'        t_bad_type.bin 10
expect_fail "first message: wrong event code" 'event code'  t_bad_code.bin 10

# ---------------------------------------------------------------------------
echo "== success and atomic output =="
# ---------------------------------------------------------------------------
rm -f out.bin
if expect_ok "cut exactly 1 message" t_good_one.bin 1; then
    if cmp -s out.bin t_good_one.bin; then
        pass "cut exactly 1 message"
    else
        fail "cut exactly 1 message" "output differs from input"
    fi
fi

printf 'stale' > out.bin
if expect_ok "success replaces existing output" t_good_one.bin 1; then
    if cmp -s out.bin t_good_one.bin; then
        pass "success replaces existing output"
    else
        fail "success replaces existing output" "old content still present"
    fi
fi

cp t_good_one.bin out.bin
before=$(md5sum < out.bin)
rm -f out.bin.tmp
run_cut t_zero_len.bin out.bin 1
if sanitizer_fired; then
    fail "failed run preserves existing output" "sanitizer report"
elif [ "$RC" -ne 1 ]; then
    fail "failed run preserves existing output" "exit $RC, expected 1"
elif [ ! -e out.bin ] || [ "$(md5sum < out.bin)" != "$before" ]; then
    fail "failed run preserves existing output" "existing out.bin was modified or removed"
elif [ -e out.bin.tmp ]; then
    fail "failed run preserves existing output" "out.bin.tmp left behind"
else
    pass "failed run preserves existing output"
fi

# ---------------------------------------------------------------------------
if [ -n "$DATA" ]; then
    echo "== real data =="
    # -----------------------------------------------------------------------
    head -c 13 "$DATA" > t_real_cut.bin
    check_size t_real_cut.bin 13
    expect_fail "real first message, 1 byte short" 'message truncated.* 0$' t_real_cut.bin 10

    rm -f out.bin
    if expect_ok "re-cut matches committed fixture" "$DATA" "$COUNT"; then
        if ! cmp -s out.bin "$FIXTURE"; then
            fail "re-cut matches committed fixture" "not byte-identical to $FIXTURE"
        elif ! cmp -s -n "$(stat -c %s out.bin)" out.bin "$DATA"; then
            fail "re-cut matches committed fixture" "not an exact prefix of the source file"
        else
            pass "re-cut matches committed fixture"
        fi
    fi
fi

# ---------------------------------------------------------------------------
echo
echo "$PASSES passed, $FAILS failed"
[ "$FAILS" -eq 0 ]
