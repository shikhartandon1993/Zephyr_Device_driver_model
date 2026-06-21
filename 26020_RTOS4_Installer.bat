@echo off
REM ============================================================================
REM 26020_RTOS4 Complex Installer Launcher
REM ============================================================================
REM This batch file is the official entry point for the MASTERs installation.
REM
REM It performs launcher-level logging and then starts the PowerShell installer.
REM The PowerShell installer creates its own transcript log.
REM
REM Log folder:
REM   C:\Masters\26020_RTOS4\install_logs
REM
REM This window remains open at the end and closes only when the user presses
REM any key.
REM ============================================================================

setlocal EnableExtensions

REM Class name used for destination folders.
set CLASS_NAME=26020_RTOS4

REM The folder where this .bat file is located.
set SCRIPT_DIR=%~dp0

REM PowerShell installer file.
set PS_INSTALLER=%SCRIPT_DIR%Install-26020_RTOS4.ps1

REM Installer log folder.
set LOG_DIR=C:\Masters\%CLASS_NAME%\install_logs

REM Create log folder before doing anything else.
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%" >nul 2>&1
)

REM Create a timestamp for both the batch log and PowerShell log.
for /f %%i in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%i

REM Batch launcher log file.
set BATCH_LOG=%LOG_DIR%\batch_launcher_%TIMESTAMP%.log

REM PowerShell transcript log file.
set PS_LOG=%LOG_DIR%\powershell_install_%TIMESTAMP%.log

call :Log "============================================================"
call :Log "Starting %CLASS_NAME% installer"
call :Log "Timestamp       : %TIMESTAMP%"
call :Log "Source folder   : %SCRIPT_DIR%"
call :Log "Batch log       : %BATCH_LOG%"
call :Log "PowerShell log  : %PS_LOG%"
call :Log "============================================================"
call :Log ""

REM Check that the PowerShell installer exists.
if not exist "%PS_INSTALLER%" (
    call :Log "ERROR: Could not find PowerShell installer:"
    call :Log "       %PS_INSTALLER%"
    call :Log ""
    call :Log "Please make sure Install-26020_RTOS4.ps1 is in the same folder as this batch file."
    goto END_WITH_ERROR
)

REM Open README for the install manager, if present.
if exist "%SCRIPT_DIR%README.txt" (
    call :Log "Opening README.txt for installation instructions..."
    start notepad.exe "%SCRIPT_DIR%README.txt"
) else (
    call :Log "WARNING: README.txt was not found in the source folder."
)

call :Log ""
call :Log "Launching PowerShell installer..."
call :Log ""

REM Run the PowerShell installer.
REM -LaunchedFromBatch tells the PowerShell script it is allowed to run.
REM -PowerShellLogPath tells the PowerShell script exactly where to save its transcript.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_INSTALLER%" -LaunchedFromBatch -PowerShellLogPath "%PS_LOG%"

set RESULT=%ERRORLEVEL%

call :Log ""
if "%RESULT%"=="0" (
    call :Log "============================================================"
    call :Log "%CLASS_NAME% installation completed successfully."
    call :Log "============================================================"
) else (
    call :Log "============================================================"
    call :Log "ERROR: %CLASS_NAME% installation failed with code %RESULT%."
    call :Log "Please review the logs:"
    call :Log "  Batch log      : %BATCH_LOG%"
    call :Log "  PowerShell log : %PS_LOG%"
    call :Log "============================================================"
)

goto END

:END_WITH_ERROR
set RESULT=1

:END
call :Log ""
call :Log "Installer finished."
call :Log "Batch log saved at:"
call :Log "  %BATCH_LOG%"
call :Log "PowerShell log saved at:"
call :Log "  %PS_LOG%"
call :Log ""

echo.
echo Logs saved at:
echo   %LOG_DIR%
echo.
echo Press any key to close this installer window...
pause >nul

exit /b %RESULT%


REM ----------------------------------------------------------------------------
REM Logging helper
REM Writes a line to both the console and the batch log file.
REM ----------------------------------------------------------------------------
:Log
if "%~1"=="" (
    echo.
    >>"%BATCH_LOG%" echo.
) else (
    echo %~1
    >>"%BATCH_LOG%" echo %~1
)
exit /b 0