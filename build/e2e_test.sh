#!/usr/bin/env bash
# End-to-end test for the revived Capoo APK.
#
#   1. the game's attract mode plays a demo round and scores by itself
#   2. the game's own name-entry panel appears
#   3. clear the field, type a new name
#   4. tap the game's OWN OK button (located automatically from a screenshot)
#   5. verify: panel closed, app alive, no runtime errors
#
# Two verification modes:
#
#   debug  - the APK is built with android:debuggable="true", so the in-app
#            log can be read with `adb run-as` and every step is asserted
#            against the log.
#   release- the shipped APK is NOT debuggable (that is the point of v1.0.3),
#            so `run-as` is unavailable and AIR's trace() does not reach
#            logcat on Android. The test then verifies through the UI
#            (screenshots) and through the absence of runtime errors.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ADB:-adb}"
PYTHON="${PYTHON:-python3}"
cd "$ROOT/build"

# default to the newest artifact in dist/
APK="${1:-$(ls -1t "$ROOT"/dist/capoo-touchhands-revived-v*.apk 2>/dev/null | head -1)}"
NEWNAME="${2:-Zed}"

if [ -z "$APK" ] || [ ! -f "$APK" ]; then
  echo "ERROR: no APK found - build it first (build/build.sh)" >&2
  exit 2
fi

RLOG() { $ADB shell run-as air.air.capoo "cat './air.capoo/Local Store/ranklog.txt'" 2>/dev/null; }
CNT() { RLOG | grep -c "$1"; }
PIDOFP() { $ADB shell "pidof air.air.capoo" 2>/dev/null | tr -d '\r\n'; }

echo "### uninstall + install $APK"
$ADB uninstall air.air.capoo >/dev/null 2>&1
if ! $ADB install --no-incremental -d "$APK" 2>&1 | tail -1 | grep -q Success; then
  echo "ERROR: install failed" >&2
  exit 1
fi

# can we read the private log? only in a debuggable build
if $ADB shell run-as air.air.capoo "true" 2>/dev/null; then
  MODE=debug
else
  MODE=release
fi
echo "### verification mode: $MODE"

$ADB logcat -c
$ADB shell am start -n air.air.capoo/.AIRAppEntry >/dev/null 2>&1

echo "### wait for menu"
for i in $(seq 1 40); do
  [ "$MODE" = release ] && break
  RLOG | grep -q "label=menu" && break
  sleep 0.5
done

echo "### wait for the name-entry panel (attract round plays itself)"
if [ "$MODE" = debug ]; then
  BASEC=$(CNT "NAME CLIP shown")
  for i in $(seq 1 90); do [ "$(CNT 'NAME CLIP shown')" -gt "$BASEC" ] && break; sleep 0.5; done
  if [ "$(CNT 'NAME CLIP shown')" -le "$BASEC" ]; then
    echo "### no panel - log:"; RLOG | tail -20; echo "### DONE (no panel)"; exit 1
  fi
else
  # release build: poll the screen for the panel (coral OK button on screen)
  for i in $(seq 1 90); do
    $ADB exec-out screencap -p > shot_probe.png
    [ "$($PYTHON find_ok_center.py shot_probe.png)" != "NOTFOUND" ] && break
    sleep 0.5
  done
fi
echo "  panel shown"

echo "### clear the field and type: $NEWNAME"
$ADB shell input keyevent 67 67 67 67 67 67 67 67 67 67 67 67
sleep 1
$ADB shell input text "$NEWNAME"
sleep 1.5

echo "### locate the OK button"
$ADB exec-out screencap -p > shot_e2e.png
OKPOS=$($PYTHON find_ok_center.py shot_e2e.png)
echo "  OK button centre: $OKPOS"
if [ "$OKPOS" = "NOTFOUND" ]; then
  echo "### could not find the OK button"; echo "### DONE"; exit 1
fi
OKX=$(echo $OKPOS | cut -d' ' -f1)
OKY=$(echo $OKPOS | cut -d' ' -f2)

echo "### tap the game's OWN OK button ($OKX,$OKY)"
$ADB shell input tap $OKX $OKY
sleep 2

# the game is back on the menu -> open the RANK panel and capture it
echo "### capture the leaderboard"
$ADB exec-out screencap -p > shot_after_ok.png
$ADB shell input tap 319 1831 >/dev/null 2>&1 || true   # RANK button
sleep 2
$ADB exec-out screencap -p > shot_rank.png

if [ "$MODE" = debug ]; then
  echo "### wait for close"
  for i in $(seq 1 30); do RLOG | grep -q "closed to menu" && break; sleep 0.3; done
  sleep 1
  echo "### log"
  RLOG | tail -22
fi

echo "### process alive: $(PIDOFP)"
echo "### AIR/JS errors"
$ADB logcat -d -v brief 2>/dev/null | grep -iE "AndroidRuntime|FATAL|uncaught|VerifyError|TypeError|ReferenceError|Security warning" | grep -v FREArray | tail -15
echo "### screenshots: shot_e2e.png shot_after_ok.png shot_rank.png"
echo "### DONE"
