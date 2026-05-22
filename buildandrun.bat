@echo off
setlocal

rem Builds the selected demo, then runs it.
rem
rem Usage:
rem   buildandrun.bat          builds and runs SwiftWinUIDemo
rem   buildandrun.bat ui       builds and runs SwiftWinUIDemo
rem   buildandrun.bat legacy   builds and runs SwiftWinLegacyDemo

set "ROOT=%~dp0"
cd /d "%ROOT%" || exit /b 1

set "DEMO=%~1"
if "%DEMO%"=="" set "DEMO=ui"

if /i "%DEMO%"=="ui" goto use_ui
if /i "%DEMO%"=="swiftwinui" goto use_ui
if /i "%DEMO%"=="SwiftWinUIDemo" goto use_ui
if /i "%DEMO%"=="legacy" goto use_legacy
if /i "%DEMO%"=="swiftwinlegacy" goto use_legacy
if /i "%DEMO%"=="SwiftWinLegacyDemo" goto use_legacy

echo Unknown demo: %DEMO% 1>&2
echo Use: buildandrun.bat [ui^|legacy] 1>&2
exit /b 64

:use_ui
set "PRODUCT=SwiftWinUIDemo"
goto build

:use_legacy
set "PRODUCT=SwiftWinLegacyDemo"
goto build

:build
swift build --product "%PRODUCT%"
if errorlevel 1 exit /b %errorlevel%

call "%ROOT%run.bat" "%DEMO%"
exit /b %errorlevel%
