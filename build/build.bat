@echo off
REM Build the Capoo (Touch Hands) revived APK from source.
REM
REM Requirements:
REM   - Adobe AIR SDK 51.x (tested with 51.4.1) set via AIR_SDK env var
REM   - JDK 17 on PATH (AIR 51's mxmlc/adt require Java 17)
REM   - SIGNING_KEYSTORE and SIGNING_PASSWORD set in the environment
REM
REM Output: dist\capoo-touchhands-revived-v1.0.2.apk

setlocal
cd /d "%~dp0\.."

if "%AIR_SDK%"=="" set "AIR_SDK=%USERPROFILE%\AIRSDK\AIRSDK_51.4.1"

set "ROOT=%CD%"
set "KEYSTORE=%SIGNING_KEYSTORE%"
set "KEYPASS=%SIGNING_PASSWORD%"
set OUT=dist\capoo-touchhands-revived-v1.0.2.apk

if "%KEYSTORE%"=="" (
  echo ERROR: set SIGNING_KEYSTORE before building.
  exit /b 2
)
if "%KEYPASS%"=="" (
  echo ERROR: set SIGNING_PASSWORD before building.
  exit /b 2
)
if not exist "%KEYSTORE%" (
  echo ERROR: signing keystore not found: %KEYSTORE%
  exit /b 2
)

echo [1/2] compiling boot shim (Boot.as -^> assets\boot.swf^)
"%AIR_SDK%\bin\mxmlc.bat" +configname=airmobile ^
  -output assets\boot.swf ^
  -default-size 480 800 ^
  -default-frame-rate 24 ^
  -swf-version 51 ^
  -source-path src ^
  -file-specs src\Boot.as

REM adt resolves the ^<content^> path and the icon paths relative to the
REM current working directory, so it has to run from inside assets\ where
REM app.xml lives
echo [2/2] packaging APK (armv8, captive runtime^)
cd assets
"%AIR_SDK%\bin\adt.bat" -package -target apk-captive-runtime -arch armv8 ^
  -storetype pkcs12 -keystore "%KEYSTORE%" -storepass "%KEYPASS%" ^
  "%ROOT%\%OUT%" app.xml boot.swf capoo.swf icons

cd /d "%~dp0\.."
echo Done -^> %OUT%
endlocal
