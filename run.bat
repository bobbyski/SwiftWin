@echo off
setlocal

rem Runs a previously built demo executable.
rem
rem Usage:
rem   run.bat          runs SwiftWinUIDemo
rem   run.bat ui       runs SwiftWinUIDemo
rem   run.bat legacy   runs SwiftWinLegacyDemo

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
echo Use: run.bat [ui^|legacy] 1>&2
exit /b 64

:use_ui
set "PRODUCT=SwiftWinUIDemo"
goto find_exe

:use_legacy
set "PRODUCT=SwiftWinLegacyDemo"
goto find_exe

:find_exe
if exist "%ROOT%.build\debug\%PRODUCT%.exe" (
    "%ROOT%.build\debug\%PRODUCT%.exe"
    exit /b %errorlevel%
)

for /d %%D in ("%ROOT%.build\*\debug") do (
    if exist "%%~fD\%PRODUCT%.exe" (
        "%%~fD\%PRODUCT%.exe"
        exit /b %errorlevel%
    )
)

echo Could not find a built executable for %PRODUCT%. 1>&2
echo Run buildandrun.bat %DEMO% first. 1>&2
exit /b 66
