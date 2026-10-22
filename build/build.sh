#!/usr/bin/env bash
# Build the Capoo (Touch Hands) revived APK from source.
#
# Requirements:
#   - Adobe AIR SDK 51.x  (tested with 51.4.1) on $AIR_SDK
#   - Oracle/Temurin JDK 17 (AIR 51's mxmlc/adt require Java 17)
#
# Usage:
#   export AIR_SDK="$HOME/AIRSDK/AIRSDK_51.4.1"
#   export SIGNING_KEYSTORE="$HOME/.keys/capoo-release.p12"
#   export SIGNING_PASSWORD="your-password"
#   ./build/build.sh
#
# Output: dist/capoo-touchhands-revived-v<versionNumber>.apk
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

AIR_SDK="${AIR_SDK:-$HOME/AIRSDK/AIRSDK_51.4.1}"
KEYSTORE="${SIGNING_KEYSTORE:-}"
KEYPASS="${SIGNING_PASSWORD:-}"

# the artifact name always follows <versionNumber> in app.xml, so the two can
# never drift apart
VERSION="$(sed -n 's/.*<versionNumber>\([^<]*\)<\/versionNumber>.*/\1/p' assets/app.xml | head -1)"
if [ -z "$VERSION" ]; then
  echo "ERROR: could not read <versionNumber> from assets/app.xml" >&2
  exit 2
fi
OUT="dist/capoo-touchhands-revived-v${VERSION}.apk"

if [[ -z "$KEYSTORE" || -z "$KEYPASS" ]]; then
  echo "ERROR: set SIGNING_KEYSTORE and SIGNING_PASSWORD before building." >&2
  exit 2
fi
if [[ ! -f "$KEYSTORE" ]]; then
  echo "ERROR: signing keystore not found: $KEYSTORE" >&2
  exit 2
fi

echo "[1/2] compiling boot shim (Boot.as -> assets/boot.swf)"
"$AIR_SDK/bin/mxmlc" +configname=airmobile \
  -output assets/boot.swf \
  -default-size 480 800 \
  -default-frame-rate 24 \
  -swf-version 51 \
  -source-path src \
  -file-specs src/Boot.as

# adt resolves <content> and the icon paths relative to the current working
# directory, so it has to run from inside assets/ (where app.xml lives)
echo "[2/2] packaging APK (armv8, captive runtime)"
cd assets
"$AIR_SDK/bin/adt" -package -target apk-captive-runtime -arch armv8 \
  -storetype pkcs12 -keystore "$KEYSTORE" -storepass "$KEYPASS" \
  "$ROOT/$OUT" app.xml boot.swf capoo.swf icons

cd "$ROOT"
echo "Done -> $OUT"
