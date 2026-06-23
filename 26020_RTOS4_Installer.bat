:: 26020_RTOS4_Installer
:: v11: flat layout + dependency warnings + final status + backup README
:: MASTERs class installer for 26020_RTOS4.
::
:: Event layout assumption:
::   Entire class package is copied by the MASTERs team to:
::       C:\Install\26020_RTOS4
::
:: Expected class package content:
::       C:\Install\26020_RTOS4\lab0
::       C:\Install\26020_RTOS4\lab1
::       C:\Install\26020_RTOS4\lab2
::       C:\Install\26020_RTOS4\lab3
::       C:\Install\26020_RTOS4\led
::       C:\Install\26020_RTOS4\Solutions
::       C:\Install\26020_RTOS4\.vscode
::       C:\Install\26020_RTOS4\26020_RTOS4_Installer.bat
::       C:\Install\26020_RTOS4\26020_restore.bat
::       C:\Install\26020_RTOS4\README.md
::
:: This script does NOT delete C:\Install\26020_RTOS4.
:: It installs Zephyr into C:\Masters\26020_RTOS4\zephyrproject,
:: copies labs into zephyrproject\apps, copies led into zephyrproject\modules,
:: copies .vscode into zephyrproject\.vscode,
:: and copies Solutions, .vscode, and this installer BAT into
:: C:\Backup\26020_RTOS4\Solutions. It also copies the installer BAT
:: 26020_restore.bat, and README.md into
:: C:\Backup\26020_RTOS4.
:: If restore.bat or 26020_restore.bat was copied into C:\Masters\26020_RTOS4
:: by restore flow, this script removes it from C:\Masters\26020_RTOS4.

@echo off
setlocal EnableExtensions

REM ============================================================
REM  These are the event/class-specific lines to edit if needed.
REM ============================================================
set "CLASS_NUMBER=26020"
set "CLASS_NAME=26020_RTOS4"
set "SRC_FOLDER=C:\Install\26020_RTOS4"

REM ============================================================
REM  Zephyr v4.3.0 Minimal CMD Installer + Lab Copy
REM  Workspace: C:\Masters\26020_RTOS4\zephyrproject
REM
REM  Zephyr installation logic is intentionally kept the same as the
REM  previously tested working CMD script.
REM ============================================================

set "WORKSPACE=C:\Masters\%CLASS_NAME%\zephyrproject"
set "CLASS_ROOT=C:\Masters\%CLASS_NAME%"
set "BACKUP_ROOT=C:\Backup\%CLASS_NAME%"
set "ZEPHYR_VERSION=v4.3.0"
set "ZEPHYR_URL=https://github.com/zephyrproject-rtos/zephyr"

REM Minimal modules for SAME54 Zephyr labs.
REM This intentionally does NOT download optional modules like lvgl, zcbor,
REM nanopb, mbedtls, mcuboot, openthread, littlefs, fatfs, etc.
set "REQUIRED_MODULES=cmsis cmsis_6 hal_atmel picolibc"

set "LABS_SRC=%SRC_FOLDER%"
set "SOLUTIONS_SRC=%SRC_FOLDER%\Solutions"
set "VSCODE_SRC=%SRC_FOLDER%\.vscode"
set "SCRIPT_FILE=%~f0"
set "RESTORE_SCRIPT_SRC=%SRC_FOLDER%\26020_restore.bat"
set "APPS_DIR=%WORKSPACE%\apps"
set "MODULES_DIR=%WORKSPACE%\modules"
set "LED_DST=%MODULES_DIR%\led"
set "VSCODE_DST=%WORKSPACE%\.vscode"
set "SOLUTIONS_DST=%BACKUP_ROOT%\Solutions"
set "SOLUTIONS_VSCODE_DST=%SOLUTIONS_DST%\.vscode"
set "SOLUTIONS_SCRIPT_DST=%SOLUTIONS_DST%\%~nx0"
set "BACKUP_INSTALLER_DST=%BACKUP_ROOT%\%~nx0"
set "BACKUP_RESTORE_DST=%BACKUP_ROOT%\26020_restore.bat"
set "README_SRC=%SRC_FOLDER%\README.md"
set "README_BACKUP_DST=%BACKUP_ROOT%\README.md"
set "RESTORE_BAT_IN_MASTER=%CLASS_ROOT%\restore.bat"
set "RESTORE_26020_BAT_IN_MASTER=%CLASS_ROOT%\26020_restore.bat"
set "DEPENDENCY_WARNINGS=%TEMP%\26020_RTOS4_dependency_warnings.txt"
if exist "%DEPENDENCY_WARNINGS%" del /F /Q "%DEPENDENCY_WARNINGS%" >nul 2>&1

REM ------------------------------------------------------------
REM Validate source folder layout.
REM ------------------------------------------------------------
if not exist "%SRC_FOLDER%\" (
    echo.
    echo ERROR: Source class folder not found:
    echo   %SRC_FOLDER%
    echo.
    echo For the MASTERs event, copy the full class package to:
    echo   C:\Install\%CLASS_NAME%
    goto :FAILED
)

if exist "%SRC_FOLDER%\README.txt" start "" notepad.exe "%SRC_FOLDER%\README.txt"

if not exist "%LABS_SRC%\lab0\" goto :BAD_SOURCE
if not exist "%LABS_SRC%\lab1\" goto :BAD_SOURCE
if not exist "%LABS_SRC%\lab2\" goto :BAD_SOURCE
if not exist "%LABS_SRC%\lab3\" goto :BAD_SOURCE
if not exist "%LABS_SRC%\led\" goto :BAD_SOURCE
if not exist "%VSCODE_SRC%\" goto :BAD_VSCODE
if not exist "%README_SRC%" goto :BAD_README

if not exist "%SOLUTIONS_SRC%\" (
    echo.
    echo WARNING: Solutions folder not found:
    echo   %SOLUTIONS_SRC%
    echo The install will continue, but Solutions will not be backed up.
    set "SOLUTIONS_SRC="
)

if not exist "%RESTORE_SCRIPT_SRC%" (
    echo.
    echo WARNING: 26020_restore.bat not found:
    echo   %RESTORE_SCRIPT_SRC%
    echo The install will continue, but the restore script will not be copied to backup.
    set "RESTORE_SCRIPT_SRC="
)

echo.
echo ============================================================
echo Zephyr %ZEPHYR_VERSION% Minimal CMD Installer + Lab Copy
echo ============================================================
echo Class name      : %CLASS_NAME%
echo Source folder   : %SRC_FOLDER%
echo Lab source      : %LABS_SRC%
echo Solutions source: %SOLUTIONS_SRC%
echo VS Code source : %VSCODE_SRC%
echo Installer BAT  : %SCRIPT_FILE%
echo Restore BAT    : %RESTORE_SCRIPT_SRC%
echo README source  : %README_SRC%
echo Workspace       : %WORKSPACE%
echo Backup root     : %BACKUP_ROOT%
echo Required modules: %REQUIRED_MODULES%
echo Restore cleanup: %RESTORE_BAT_IN_MASTER% and %RESTORE_26020_BAT_IN_MASTER%
echo.

REM ------------------------------------------------------------
REM Dependency checks
REM ------------------------------------------------------------
echo ============================================================
echo Checking required tools
echo ============================================================

call :WarnTool py "Python launcher"

py -3.12 --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: Python 3.12 was not detected by: py -3.12 --version
    call :AddDependencyWarning "Python 3.12 not detected. Manually check Python.Python.3.12."
) else (
    echo OK: Python 3.12
)

call :WarnTool git "Git"
call :WarnTool cmake "CMake"
call :WarnTool ninja "Ninja"
call :WarnTool dtc "Device Tree Compiler"
call :WarnTool gperf "gperf"
call :WarnTool openocd "OpenOCD"

call :WarnOpenOCDVersion
call :WarnZephyrSDKVersion

call :ShowDependencyWarnings

echo.
echo Tool versions detected where available:
py -3.12 --version 2>nul
git --version 2>nul
cmake --version 2>nul | findstr /R "cmake version"
ninja --version 2>nul
dtc --version 2>nul
gperf --version 2>nul
openocd --version 2>nul

REM ------------------------------------------------------------
REM Create workspace and virtual environment
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Creating workspace and Python virtual environment
echo ============================================================

if not exist "%CLASS_ROOT%" mkdir "%CLASS_ROOT%"
if not exist "%WORKSPACE%" mkdir "%WORKSPACE%"

cd /d "%WORKSPACE%"
if errorlevel 1 goto :FAILED

if not exist ".venv\Scripts\python.exe" (
    call :RunRetry py -3.12 -m venv .venv
    if errorlevel 1 goto :FAILED
) else (
    echo Virtual environment already exists. Skipping venv creation.
)

call ".venv\Scripts\activate.bat"
if errorlevel 1 goto :FAILED

call :RunRetry python -m pip install --upgrade pip
if errorlevel 1 goto :FAILED

call :RunRetry pip install west
if errorlevel 1 goto :FAILED

REM ------------------------------------------------------------
REM Download Zephyr source code using shallow clone
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Getting Zephyr source code %ZEPHYR_VERSION%
echo ============================================================

cd /d "%WORKSPACE%"
if errorlevel 1 goto :FAILED

if exist "zephyr\.git" (
    echo Zephyr repository already exists. Skipping clone.
    cd /d "%WORKSPACE%\zephyr"
    git describe --tags 2>nul | findstr /I "%ZEPHYR_VERSION%" >nul
    if errorlevel 1 (
        echo WARNING: Existing zephyr folder may not be %ZEPHYR_VERSION%.
        echo Current version is:
        git describe --tags 2>nul
        echo.
        echo To force a clean install, delete only this workspace:
        echo %WORKSPACE%
        goto :FAILED
    )
    cd /d "%WORKSPACE%"
) else (
    call :RunRetry git clone --branch %ZEPHYR_VERSION% --depth 1 --single-branch %ZEPHYR_URL% zephyr
    if errorlevel 1 goto :FAILED
)

REM ------------------------------------------------------------
REM Initialize west workspace
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Initializing west workspace
echo ============================================================

cd /d "%WORKSPACE%"
if errorlevel 1 goto :FAILED

if exist ".west\config" (
    echo West workspace already initialized. Skipping west init.
) else (
    call :RunRetry west init -l zephyr
    if errorlevel 1 goto :FAILED
)

REM ------------------------------------------------------------
REM Update only required modules
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Updating only required Zephyr modules
echo ============================================================
echo Required modules: %REQUIRED_MODULES%
echo.
echo First attempt uses narrow + shallow fetch.
echo If that fails, the script retries with narrow fetch only.
echo.

call :RunOnce west update -n -o=--depth=1 %REQUIRED_MODULES%
if errorlevel 1 (
    echo.
    echo Narrow + shallow update failed. Retrying with narrow only...
    call :RunRetry west update -n %REQUIRED_MODULES%
    if errorlevel 1 goto :FAILED
)

REM ------------------------------------------------------------
REM Export Zephyr and install Python packages
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Exporting Zephyr and installing Python packages
echo ============================================================

call :RunRetry west zephyr-export
if errorlevel 1 goto :FAILED

call :RunRetry west packages pip --install
if errorlevel 1 goto :FAILED

REM ------------------------------------------------------------
REM Copy lab files and Solutions after installation
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Copying labs, led module, VS Code settings, and Solutions backup
echo ============================================================

if not exist "%APPS_DIR%" mkdir "%APPS_DIR%"
if not exist "%MODULES_DIR%" mkdir "%MODULES_DIR%"
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"

call :CopyDir "%LABS_SRC%\lab0" "%APPS_DIR%\lab0"
if errorlevel 1 goto :FAILED
call :CopyDir "%LABS_SRC%\lab1" "%APPS_DIR%\lab1"
if errorlevel 1 goto :FAILED
call :CopyDir "%LABS_SRC%\lab2" "%APPS_DIR%\lab2"
if errorlevel 1 goto :FAILED
call :CopyDir "%LABS_SRC%\lab3" "%APPS_DIR%\lab3"
if errorlevel 1 goto :FAILED

call :CopyDir "%LABS_SRC%\led" "%LED_DST%"
if errorlevel 1 goto :FAILED

call :CopyDir "%VSCODE_SRC%" "%VSCODE_DST%"
if errorlevel 1 goto :FAILED

if not exist "%SOLUTIONS_DST%" mkdir "%SOLUTIONS_DST%"

if defined SOLUTIONS_SRC (
    call :CopyDir "%SOLUTIONS_SRC%" "%SOLUTIONS_DST%"
    if errorlevel 1 goto :FAILED
) else (
    echo WARNING: No Solutions folder found. Creating Solutions backup folder anyway.
    if not exist "%SOLUTIONS_DST%" mkdir "%SOLUTIONS_DST%"
)

call :CopyDir "%VSCODE_SRC%" "%SOLUTIONS_VSCODE_DST%"
if errorlevel 1 goto :FAILED

call :CopyFile "%SCRIPT_FILE%" "%SOLUTIONS_SCRIPT_DST%"
if errorlevel 1 goto :FAILED

call :CopyFile "%SCRIPT_FILE%" "%BACKUP_INSTALLER_DST%"
if errorlevel 1 goto :FAILED

if defined RESTORE_SCRIPT_SRC (
    call :CopyFile "%RESTORE_SCRIPT_SRC%" "%BACKUP_RESTORE_DST%"
    if errorlevel 1 goto :FAILED
) else (
    echo.
    echo WARNING: 26020_restore.bat was not copied because it was not found in the source folder.
)

call :CopyFile "%README_SRC%" "%README_BACKUP_DST%"
if errorlevel 1 goto :FAILED

REM Remove restore.bat from the final class folder if it was copied there by restore flow.
REM Do not remove any restore script under C:\Backup or anything under C:\Install.
echo.
if exist "%RESTORE_BAT_IN_MASTER%" (
    echo Removing restore script from Masters class folder:
    echo   %RESTORE_BAT_IN_MASTER%
    del /F /Q "%RESTORE_BAT_IN_MASTER%"
    if errorlevel 1 goto :FAILED
) else (
    echo No restore.bat found in Masters class folder. Nothing to remove.
)

if exist "%RESTORE_26020_BAT_IN_MASTER%" (
    echo Removing 26020 restore script from Masters class folder:
    echo   %RESTORE_26020_BAT_IN_MASTER%
    del /F /Q "%RESTORE_26020_BAT_IN_MASTER%"
    if errorlevel 1 goto :FAILED
) else (
    echo No 26020_restore.bat found in Masters class folder. Nothing to remove.
)

REM ------------------------------------------------------------
REM Verification
REM ------------------------------------------------------------
echo.
echo ============================================================
echo Verifying installation
echo ============================================================

cd /d "%WORKSPACE%\zephyr"
if errorlevel 1 goto :FAILED

echo Zephyr git version:
git describe --tags

echo.
echo VERSION file:
type VERSION

echo.
echo Checking copied folders:
dir "%APPS_DIR%\lab0" >nul 2>&1 || goto :FAILED
dir "%APPS_DIR%\lab1" >nul 2>&1 || goto :FAILED
dir "%APPS_DIR%\lab2" >nul 2>&1 || goto :FAILED
dir "%APPS_DIR%\lab3" >nul 2>&1 || goto :FAILED
dir "%LED_DST%" >nul 2>&1 || goto :FAILED
dir "%VSCODE_DST%" >nul 2>&1 || goto :FAILED
dir "%SOLUTIONS_DST%" >nul 2>&1 || goto :FAILED
dir "%SOLUTIONS_VSCODE_DST%" >nul 2>&1 || goto :FAILED
if not exist "%SOLUTIONS_SCRIPT_DST%" goto :FAILED
if not exist "%BACKUP_INSTALLER_DST%" goto :FAILED
if defined RESTORE_SCRIPT_SRC if not exist "%BACKUP_RESTORE_DST%" goto :FAILED
if not exist "%README_BACKUP_DST%" goto :FAILED
if exist "%RESTORE_BAT_IN_MASTER%" (
    echo ERROR: restore.bat still exists in Masters class folder:
    echo   %RESTORE_BAT_IN_MASTER%
    goto :FAILED
)
if exist "%RESTORE_26020_BAT_IN_MASTER%" (
    echo ERROR: 26020_restore.bat still exists in Masters class folder:
    echo   %RESTORE_26020_BAT_IN_MASTER%
    goto :FAILED
)

echo.
echo Installed west projects:
cd /d "%WORKSPACE%"
west list

echo.
echo ============================================================
echo FINAL STATUS: SUCCESSFUL
echo Zephyr v4.3.0/source setup and required module update completed.
echo Lab files and required backup files were verified in the expected locations.
echo ============================================================
echo Workspace is ready here:
echo %WORKSPACE%
echo.
echo Labs copied to:
echo %APPS_DIR%
echo.
echo Led module copied to:
echo %LED_DST%
echo.
echo VS Code settings copied to:
echo %VSCODE_DST%
echo.
echo Solutions backup copied to:
echo %SOLUTIONS_DST%
echo.
echo Installer BAT backed up to Solutions:
echo %SOLUTIONS_SCRIPT_DST%
echo.
echo Installer BAT backed up to backup root:
echo %BACKUP_INSTALLER_DST%
echo.
if defined RESTORE_SCRIPT_SRC (
    echo Restore BAT backed up to backup root:
    echo %BACKUP_RESTORE_DST%
    echo.
)
echo README backed up to backup root:
echo %README_BACKUP_DST%
echo.
call :ShowDependencyWarnings
echo.
echo Restore scripts removed from Masters class folder if present:
echo %RESTORE_BAT_IN_MASTER%
echo %RESTORE_26020_BAT_IN_MASTER%
echo.
echo Source folder was left untouched for MASTERs backup:
echo %SRC_FOLDER%
echo.
echo This installer intentionally downloaded only these modules:
echo %REQUIRED_MODULES%
echo.
echo If a future lab needs another module, run:
echo   cd /d %WORKSPACE%
echo   .venv\Scripts\activate.bat
echo   west update -n -o=--depth=1 MODULE_NAME
echo.
pause
exit /b 0

:BAD_SOURCE
echo.
echo ERROR: Expected lab folders were not found under:
echo   %LABS_SRC%
echo.
echo Required layout:
echo   %SRC_FOLDER%\lab0
echo   %SRC_FOLDER%\lab1
echo   %SRC_FOLDER%\lab2
echo   %SRC_FOLDER%\lab3
echo   %SRC_FOLDER%\led
goto :FAILED

:BAD_VSCODE
echo.
echo ERROR: Expected .vscode folder was not found:
echo   %VSCODE_SRC%
echo.
echo Required layout now includes:
echo   %SRC_FOLDER%\.vscode
goto :FAILED

:WarnTool
where %~1 >nul 2>&1
if errorlevel 1 (
    echo WARNING: %~2 not found in PATH. Missing command: %~1
    call :AddDependencyWarning "%~2 not found in PATH. Manually check command: %~1"
) else (
    echo OK: %~2
)
exit /b 0

:AddDependencyWarning
echo %~1>>"%DEPENDENCY_WARNINGS%"
exit /b 0

:WarnOpenOCDVersion
where openocd >nul 2>&1
if errorlevel 1 exit /b 0
set "OPENOCD_VERSION_FILE=%TEMP%\openocd_version_26020_RTOS4.txt"
openocd --version > "%OPENOCD_VERSION_FILE%" 2>&1
findstr /C:"0.12.0" "%OPENOCD_VERSION_FILE%" >nul 2>&1
if errorlevel 1 (
    echo WARNING: OpenOCD was found, but version 0.12.0 was not detected.
    echo Current OpenOCD output:
    type "%OPENOCD_VERSION_FILE%"
    echo.
    call :AddDependencyWarning "OpenOCD 0.12.0 not detected. Manually check OpenOCD version."
) else (
    echo OK: OpenOCD 0.12.0 detected.
)
exit /b 0

:WarnZephyrSDKVersion
echo.
echo Checking Zephyr SDK 0.17.4...
set "SDK_REQUIRED=0.17.4"

if defined ZEPHYR_SDK_INSTALL_DIR (
    call :CheckSDKCandidate "%ZEPHYR_SDK_INSTALL_DIR%"
    if not errorlevel 1 goto :SDK_FOUND_OK
)

call :CheckSDKCandidate "%USERPROFILE%\zephyr-sdk-0.17.4"
if not errorlevel 1 goto :SDK_FOUND_OK

call :CheckSDKCandidate "C:\zephyr-sdk-0.17.4"
if not errorlevel 1 goto :SDK_FOUND_OK

call :CheckSDKCandidate "C:\Tools\zephyr-sdk-0.17.4"
if not errorlevel 1 goto :SDK_FOUND_OK

call :CheckSDKCandidate "C:\Program Files\Zephyr SDK\0.17.4"
if not errorlevel 1 goto :SDK_FOUND_OK

echo WARNING: Zephyr SDK 0.17.4 was not detected by this script.
echo Checked:
echo   ZEPHYR_SDK_INSTALL_DIR if set
echo   %USERPROFILE%\zephyr-sdk-0.17.4
echo   C:\zephyr-sdk-0.17.4
echo   C:\Tools\zephyr-sdk-0.17.4
echo   C:\Program Files\Zephyr SDK\0.17.4
echo.
echo If Zephyr SDK 0.17.4 is installed somewhere else, manually verify it or set:
echo   set ZEPHYR_SDK_INSTALL_DIR=C:\path\to\zephyr-sdk-0.17.4
echo.
call :AddDependencyWarning "Zephyr SDK 0.17.4 not detected by script. Manually check SDK installation/path."
exit /b 0

:SDK_FOUND_OK
echo OK: Zephyr SDK 0.17.4 detected.
exit /b 0

:CheckSDKCandidate
set "SDK_CANDIDATE=%~1"
if "%SDK_CANDIDATE%"=="" exit /b 1
if not exist "%SDK_CANDIDATE%\" exit /b 1

REM Confirm this looks like Zephyr SDK 0.17.4.
echo %SDK_CANDIDATE% | findstr /I /C:"0.17.4" >nul 2>&1
if not errorlevel 1 goto :SDK_VERSION_OK

if exist "%SDK_CANDIDATE%\sdk_version" (
    findstr /C:"0.17.4" "%SDK_CANDIDATE%\sdk_version" >nul 2>&1
    if not errorlevel 1 goto :SDK_VERSION_OK
)

if exist "%SDK_CANDIDATE%\VERSION" (
    findstr /C:"0.17.4" "%SDK_CANDIDATE%\VERSION" >nul 2>&1
    if not errorlevel 1 goto :SDK_VERSION_OK
)

exit /b 1

:SDK_VERSION_OK
if not exist "%SDK_CANDIDATE%\cmake\Zephyr-sdkConfig.cmake" exit /b 1
if not exist "%SDK_CANDIDATE%\arm-zephyr-eabi\bin\arm-zephyr-eabi-gcc.exe" exit /b 1

echo   Found: %SDK_CANDIDATE%
exit /b 0

:ShowDependencyWarnings
if exist "%DEPENDENCY_WARNINGS%" (
    echo.
    echo ============================================================
    echo DEPENDENCY WARNING SUMMARY
    echo ============================================================
    echo The script did not detect the following dependencies.
    echo The installer does not stop only because of these checks,
    echo but please manually verify them before using the lab setup:
    type "%DEPENDENCY_WARNINGS%"
    echo ============================================================
) else (
    echo.
    echo Dependency check summary: no missing dependencies detected by script.
)
exit /b 0

:RunOnce
echo.
echo ^> %*
%*
exit /b %ERRORLEVEL%

:RunRetry
echo.
echo ^> %*
%*
if not errorlevel 1 exit /b 0

echo.
echo Command failed. Retrying once after 10 seconds...
timeout /t 10 /nobreak >nul

echo.
echo ^> %*
%*
if not errorlevel 1 exit /b 0

echo.
echo ERROR: Command failed twice:
echo %*
exit /b 1

:CopyDir
set "SRC=%~1"
set "DST=%~2"
echo.
echo Copying:
echo   from: %SRC%
echo   to  : %DST%
if not exist "%SRC%\" (
    echo ERROR: Source folder not found: %SRC%
    exit /b 1
)
if exist "%DST%\" rmdir /s /q "%DST%"
robocopy "%SRC%" "%DST%" /E /R:3 /W:5 /NFL /NDL /NP
if %ERRORLEVEL% GEQ 8 (
    echo ERROR: Robocopy failed with exit code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)
exit /b 0

:CopyFile
set "SRCFILE=%~1"
set "DSTFILE=%~2"
echo.
echo Copying file:
echo   from: %SRCFILE%
echo   to  : %DSTFILE%
if not exist "%SRCFILE%" (
    echo ERROR: Source file not found: %SRCFILE%
    exit /b 1
)
for %%D in ("%DSTFILE%") do if not exist "%%~dpD" mkdir "%%~dpD"
copy /Y "%SRCFILE%" "%DSTFILE%" >nul
if errorlevel 1 (
    echo ERROR: File copy failed.
    exit /b 1
)
exit /b 0

:FAILED
echo.
echo ============================================================
echo FINAL STATUS: FAILED
echo Zephyr v4.3.0/module installation or class file copy/verification did not complete successfully.
echo ============================================================
echo Do not delete C:\Install\%CLASS_NAME%.
echo Do not delete the workspace immediately. Many Git downloads can resume.
echo Failed workspace:
echo %WORKSPACE%
echo.
echo Common recovery:
echo   cd /d %WORKSPACE%
echo   .venv\Scripts\activate.bat
echo   west update -n -o=--depth=1 %REQUIRED_MODULES%
echo.
pause
exit /b 1
