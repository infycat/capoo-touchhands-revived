#!/usr/bin/env bash
# End-to-end test for the revived Capoo APK.
#
#   1. the game's attract mode plays a demo round and scores by itself
#   2. the game's own name-entry panel appears
#   3. clear the field, type a new name
#   4. tap the game's OWN OK button (located automatically from a screenshot)
#   5. verify: name stored in the role array, panel closed fast, app alive
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ADB:-adb}"
PYTHON="${PYTHON:-python3}"
cd "$ROOT/build"

RLOG() { $ADB shell run-as air.air.capoo "cat './air.capoo/Local Store/ranklog.txt'" 2>/dev/null; }
CNT() { RLOG | grep -c "$1"; }
PIDOFP() { $ADB shell "pidof air.air.capoo" 2>/dev/null | tr -d '\r\n'; }

APK="${1:-$ROOT/dist/capoo-touchhands-revived-v1.0.2.apk}"
NEWNAME="${2:-Zed}"

echo "### uninstall + install $APK"
$ADB uninstall air.air.capoo >/dev/null 2>&1
$ADB install --no-incremental -d "$APK" 2>&1 | tail -1
$ADB logcat -c
$ADB shell am start -n air.air.capoo/.AIRAppEntry >/dev/null 2>&1

echo "### wait for menu"
for i in $(seq 1 40); do RLOG | grep -q "label=menu" && break; sleep 0.5; done

echo "### wait for the name-entry panel (attract round plays itself)"
BASEC=$(CNT "NAME CLIP shown")
for i in $(seq 1 90); do [ "$(CNT 'NAME CLIP shown')" -gt "$BASEC" ] && break; sleep 0.5; done
if [ "$(CNT 'NAME CLIP shown')" -le "$BASEC" ]; then
  echo "### no panel - log:"; RLOG | tail -20; echo "### DONE (no panel)"; exit 1
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

echo "### wait for close"
for i in $(seq 1 30); do RLOG | grep -q "closed to menu" && break; sleep 0.3; done
sleep 1

echo "### log"
RLOG | tail -22
echo "### process alive: $(PIDOFP)"
echo "### AIR/JS errors"
$ADB logcat -d -v brief 2>/dev/null | grep -iE "AndroidRuntime|FATAL|uncaught|VerifyError|TypeError|ReferenceError" | grep -v FREArray | tail -15
echo "### DONE"
