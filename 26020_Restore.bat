@echo off
setlocal EnableExtensions

REM ============================================================
REM 26020_RTOS4 Restore Script
REM ============================================================
REM Expected location:
REM   C:\Backup\26020_RTOS4\26020_restore.bat
REM
REM Behavior:
REM   1. Copy only 26020_RTOS4_Installer.bat from C:\Backup\26020_RTOS4
REM      to C:\Masters\26020_RTOS4
REM   2. Run that installer from C:\Masters\26020_RTOS4
REM   3. Delete 26020_RTOS4_Installer.bat from C:\Masters\26020_RTOS4
REM
REM This restore script does not copy Solutions, README, or any other files.
REM ============================================================

set "BACKUP_ROOT=%~dp0"
set "MASTER_ROOT=C:\Masters\26020_RTOS4"
set "INSTALLER_NAME=26020_RTOS4_Installer.bat"
set "SRC_INSTALLER=%BACKUP_ROOT%%INSTALLER_NAME%"
set "DST_INSTALLER=%MASTER_ROOT%\%INSTALLER_NAME%"
set "RESTORE_STATUS=SUCCESSFUL"
set "INSTALLER_EXIT=0"

echo.
echo ============================================================
echo Starting 26020_RTOS4 restore
echo ============================================================
echo Backup root : %BACKUP_ROOT%
echo Masters root: %MASTER_ROOT%
echo.

if not exist "%SRC_INSTALLER%" (
    echo ERROR: Installer not found in backup folder:
    echo %SRC_INSTALLER%
    set "RESTORE_STATUS=FAILED"
    goto :END
)

if not exist "%MASTER_ROOT%" (
    echo Creating Masters folder:
    echo %MASTER_ROOT%
    mkdir "%MASTER_ROOT%"
    if errorlevel 1 (
        echo ERROR: Could not create Masters folder.
        set "RESTORE_STATUS=FAILED"
        goto :END
    )
)

echo Copying installer to Masters folder...
copy /Y "%SRC_INSTALLER%" "%DST_INSTALLER%" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy installer to:
    echo %DST_INSTALLER%
    set "RESTORE_STATUS=FAILED"
    goto :END
)

if not exist "%DST_INSTALLER%" (
    echo ERROR: Installer copy verification failed:
    echo %DST_INSTALLER%
    set "RESTORE_STATUS=FAILED"
    goto :END
)

echo Running installer from Masters folder...
echo.
pushd "%MASTER_ROOT%"
call "%DST_INSTALLER%"
set "INSTALLER_EXIT=%ERRORLEVEL%"
popd

echo.
echo Deleting temporary installer from Masters folder...
if exist "%DST_INSTALLER%" (
    del /F /Q "%DST_INSTALLER%"
)

if exist "%DST_INSTALLER%" (
    echo ERROR: Could not delete temporary installer:
    echo %DST_INSTALLER%
    set "RESTORE_STATUS=FAILED"
    goto :END
)

if not "%INSTALLER_EXIT%"=="0" (
    echo ERROR: Installer returned exit code %INSTALLER_EXIT%.
    set "RESTORE_STATUS=FAILED"
    goto :END
)

:END
echo.
echo ============================================================
echo RESTORE STATUS: %RESTORE_STATUS%
echo ============================================================
echo.
echo This restore script only copies and runs:
echo   %INSTALLER_NAME%
echo It does not copy Solutions, README, or other backup files directly.
echo.
pause

if /I "%RESTORE_STATUS%"=="SUCCESSFUL" (
    exit /b 0
) else (
    exit /b 1
)
