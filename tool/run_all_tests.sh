#!/usr/bin/env bash
# Runs every automated test, one suite after the other, and prints one summary.
#
#   tool/run_all_tests.sh
#
# 1. Regular tests (about 15 s)
# 2. Real-app checklist, 53 steps (about 10–13 min)
# 3. Real-app heavy days, stage Y (about 3 min); runs alone because it moves the app's clock
#
# The real-app suites open the Caskly window. While they run:
#  - keep the Mac unlocked and awake (plugged in);
#  - keep the Caskly window visible: macOS stops drawing a window that is
#    fully covered by other windows, and the run then waits forever;
#  - don't click or type in it.
# Full logs go to build/test-logs/.
set -u
cd "$(dirname "$0")/.."
LOGS=build/test-logs
mkdir -p "$LOGS"
rm -f "$LOGS/failures.txt"
start=$(date +%s)
summary=()
failed=0

run() { # name, log file, command...
  local name=$1 log=$2; shift 2
  echo "▶ $name …" >&2
  "$@" > "$log" 2>&1
  local code=$?
  echo "$code"
}

# 1. Regular tests
code=$(run "Regular tests" "$LOGS/unit.log" flutter test | tail -1)
line=$(grep -E '^[0-9]+:[0-9]+ \+[0-9]+' "$LOGS/unit.log" | tail -1 | sed -E 's/^[0-9:]+ //')
[ "$code" = 0 ] && summary+=("✅ Regular tests: ${line}") || { summary+=("❌ Regular tests: ${line} (see $LOGS/unit.log)"); failed=1; }

# 2 and 3. Real-app suites
for suite in "Real-app checklist|ABCDEFGHZ|e2e_checklist.log" "Real-app heavy days|Y|e2e_heavy.log"; do
  IFS='|' read -r name stages log <<< "$suite"
  code=$(run "$name" "$LOGS/$log" flutter test integration_test/app_flow_test.dart -d macos --dart-define=E2E_STAGES="$stages" | tail -1)
  result=$(grep -E '^E2E: ' "$LOGS/$log" | tail -1)
  if [ "$code" = 0 ] && echo "$result" | grep -q ', 0 fail'; then
    summary+=("✅ $name: ${result#E2E: }")
  else
    shown=${result#E2E: }
    summary+=("❌ $name: ${shown:-did not finish} (see $LOGS/$log)")
    grep -E '^\[FAIL\]|E2E_ABORTED' "$LOGS/$log" | cut -c1-200 | sed 's/^/     /' >> "$LOGS/failures.txt"
    failed=1
  fi
done

mins=$(( ($(date +%s) - start) / 60 ))
echo
echo "════════ Caskly test summary (${mins} min) ════════"
printf '%s\n' "${summary[@]}"
[ -f "$LOGS/failures.txt" ] && { echo; echo "Failures:"; cat "$LOGS/failures.txt"; rm -f "$LOGS/failures.txt"; }
exit $failed
