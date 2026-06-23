# 26020_RTOS4 Installer README

This README is for the person running the `26020_RTOS4_Installer.bat` script for the MASTERs class **26020_RTOS4**.

You do **not** need Zephyr knowledge to run this installer. The script installs Zephyr v4.3.0, downloads the required Zephyr modules for the labs, and copies the class files into the expected folders.

---

## 1. Expected source folder before running the installer

The complete class package should already be copied to:

```cmd
C:\Install\26020_RTOS4
```

The installer expects this layout:

```text
C:\Install\26020_RTOS4
│
├── 26020_RTOS4_Installer.bat
├── 26020_restore.bat
├── .vscode
├── Solutions
├── lab0
├── lab1
├── lab2
├── lab3
└── led
```

Do **not** delete this folder:

```cmd
C:\Install\26020_RTOS4
```

The MASTERs team may use this folder later to recreate or back up the ghosting computer setup.

---

## 2. How to run the installer

Open **Command Prompt** and run:

```cmd
cd /d C:\Install\26020_RTOS4
26020_RTOS4_Installer.bat
```

Let the script run until the end.

The script may take time because it downloads Zephyr source code and Zephyr modules from GitHub.

---

## 3. What the installer does

The installer creates the Zephyr workspace here:

```cmd
C:\Masters\26020_RTOS4\zephyrproject
```

It installs Zephyr source code v4.3.0 here:

```cmd
C:\Masters\26020_RTOS4\zephyrproject\zephyr
```

It creates a Python virtual environment here:

```cmd
C:\Masters\26020_RTOS4\zephyrproject\.venv
```

It downloads only the required Zephyr modules used by the labs:

```text
cmsis
cmsis_6
hal_atmel
picolibc
```

The script intentionally does **not** download all optional Zephyr modules such as `lvgl`, `zcbor`, `nanopb`, `mbedtls`, `mcuboot`, `openthread`, `littlefs`, or `fatfs`.

---

## 4. Dependency checks

The script checks for these dependencies:

```text
Python 3.12
Git
CMake
Ninja
DTC
gperf
Zephyr SDK 0.17.4
OpenOCD 0.12.0
```

These checks are warnings only. If a dependency is not detected, the script continues and prints a warning summary near the end.

However, if a required tool such as Python or Git is truly missing, the install may still fail when the script tries to use it.

---

## 5. Final status message

At the end, the script prints one of these messages:

```text
FINAL STATUS: SUCCESSFUL
```

or

```text
FINAL STATUS: FAILED
```

`FINAL STATUS: SUCCESSFUL` means both of these completed and were verified:

1. Zephyr v4.3.0 source code and required Zephyr modules were installed successfully.
2. The lab files, `led` folder, `.vscode` folder, `Solutions` folder, installer script, and restore script were copied to the expected locations.

`FINAL STATUS: FAILED` means one or both of those checks failed. Follow the manual recovery steps in section 8.

---

## 6. Check these locations if the script is successful

If the script shows:

```text
FINAL STATUS: SUCCESSFUL
```

check the following locations.

### Zephyr workspace

```cmd
C:\Masters\26020_RTOS4\zephyrproject
```

Expected important folders:

```text
C:\Masters\26020_RTOS4\zephyrproject\.venv
C:\Masters\26020_RTOS4\zephyrproject\zephyr
C:\Masters\26020_RTOS4\zephyrproject\modules
C:\Masters\26020_RTOS4\zephyrproject\apps
C:\Masters\26020_RTOS4\zephyrproject\.vscode
```

### Lab folders

The lab folders should be copied here:

```text
C:\Masters\26020_RTOS4\zephyrproject\apps\lab0
C:\Masters\26020_RTOS4\zephyrproject\apps\lab1
C:\Masters\26020_RTOS4\zephyrproject\apps\lab2
C:\Masters\26020_RTOS4\zephyrproject\apps\lab3
```

### Custom `led` module

The `led` module should be copied here:

```cmd
C:\Masters\26020_RTOS4\zephyrproject\modules\led
```

### VS Code settings

The `.vscode` folder should be copied here:

```cmd
C:\Masters\26020_RTOS4\zephyrproject\.vscode
```

### Backup folder

The backup folder should exist here:

```cmd
C:\Backup\26020_RTOS4
```

Expected backup contents:

```text
C:\Backup\26020_RTOS4\Solutions
C:\Backup\26020_RTOS4\Solutions\.vscode
C:\Backup\26020_RTOS4\Solutions\26020_RTOS4_Installer.bat
C:\Backup\26020_RTOS4\26020_RTOS4_Installer.bat
C:\Backup\26020_RTOS4\26020_restore.bat
```

The backup folder should **not** contain the downloaded Zephyr source code or downloaded Zephyr modules.

---

## 7. Optional verification commands

Open Command Prompt and run:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject
.venv\Scripts\activate.bat
```

Verify Zephyr version:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject\zephyr
git describe --tags
type VERSION
```

Expected Zephyr version:

```text
v4.3.0
VERSION_MAJOR = 4
VERSION_MINOR = 3
PATCHLEVEL = 0
```

Verify required modules:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject
west list cmsis cmsis_6 hal_atmel picolibc
```

Verify the build system is available:

```cmd
west help build
```

---

## 8. If the script fails

If the script shows:

```text
FINAL STATUS: FAILED
```

or stops with an error, do **not** delete this folder:

```cmd
C:\Install\26020_RTOS4
```

Also, do not immediately delete the Zephyr workspace. Many Git downloads can resume from an incomplete workspace.

Failed or partial workspace:

```cmd
C:\Masters\26020_RTOS4\zephyrproject
```

### 8.1 Stop stuck Git or west processes

Open Command Prompt and run:

```cmd
taskkill /F /IM git.exe
taskkill /F /IM git-remote-https.exe
taskkill /F /IM python.exe
taskkill /F /IM pythonw.exe
taskkill /F /IM west.exe
```

It is okay if some commands say the process was not found.

---

## 9. Manual Zephyr v4.3.0 installation steps

Use these steps if the installer fails and Zephyr must be installed manually.

Open **Command Prompt** and run:

```cmd
mkdir C:\Masters\26020_RTOS4
cd /d C:\Masters\26020_RTOS4

py -3.12 -m venv zephyrproject\.venv
zephyrproject\.venv\Scripts\activate.bat

python -m pip install --upgrade pip
pip install west
```

Download Zephyr v4.3.0 source code using a shallow clone:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject

git clone --branch v4.3.0 --depth 1 --single-branch https://github.com/zephyrproject-rtos/zephyr zephyr
```

Initialize west:

```cmd
west init -l zephyr
```

Download only the required Zephyr modules:

```cmd
west update -n -o=--depth=1 cmsis cmsis_6 hal_atmel picolibc
```

Export Zephyr CMake package:

```cmd
west zephyr-export
```

Install Zephyr Python packages:

```cmd
west packages pip --install
```

Verify Zephyr:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject\zephyr
git describe --tags
type VERSION
```

---

## 10. Manual file copy steps

Use these steps if Zephyr was installed manually, or if the installer failed during the copy stage.

### Create required folders

```cmd
mkdir C:\Masters\26020_RTOS4\zephyrproject\apps
mkdir C:\Masters\26020_RTOS4\zephyrproject\modules
mkdir C:\Backup\26020_RTOS4
mkdir C:\Backup\26020_RTOS4\Solutions
```

### Copy lab folders to Zephyr apps folder

```cmd
robocopy C:\Install\26020_RTOS4\lab0 C:\Masters\26020_RTOS4\zephyrproject\apps\lab0 /E
robocopy C:\Install\26020_RTOS4\lab1 C:\Masters\26020_RTOS4\zephyrproject\apps\lab1 /E
robocopy C:\Install\26020_RTOS4\lab2 C:\Masters\26020_RTOS4\zephyrproject\apps\lab2 /E
robocopy C:\Install\26020_RTOS4\lab3 C:\Masters\26020_RTOS4\zephyrproject\apps\lab3 /E
```

### Copy `led` module

```cmd
robocopy C:\Install\26020_RTOS4\led C:\Masters\26020_RTOS4\zephyrproject\modules\led /E
```

### Copy `.vscode` into Zephyr workspace

```cmd
robocopy C:\Install\26020_RTOS4\.vscode C:\Masters\26020_RTOS4\zephyrproject\.vscode /E
```

### Copy `Solutions` to backup

```cmd
robocopy C:\Install\26020_RTOS4\Solutions C:\Backup\26020_RTOS4\Solutions /E
```

### Copy `.vscode` to backup Solutions folder

```cmd
robocopy C:\Install\26020_RTOS4\.vscode C:\Backup\26020_RTOS4\Solutions\.vscode /E
```

### Copy installer script and restore script to backup

```cmd
copy /Y C:\Install\26020_RTOS4\26020_RTOS4_Installer.bat C:\Backup\26020_RTOS4\26020_RTOS4_Installer.bat
copy /Y C:\Install\26020_RTOS4\26020_RTOS4_Installer.bat C:\Backup\26020_RTOS4\Solutions\26020_RTOS4_Installer.bat
copy /Y C:\Install\26020_RTOS4\26020_restore.bat C:\Backup\26020_RTOS4\26020_restore.bat
```

### Remove restore scripts from Masters folder if present

These should not remain in the final Masters class folder:

```cmd
if exist C:\Masters\26020_RTOS4\restore.bat del /F /Q C:\Masters\26020_RTOS4\restore.bat
if exist C:\Masters\26020_RTOS4\26020_restore.bat del /F /Q C:\Masters\26020_RTOS4\26020_restore.bat
```

---

## 11. Manual final check

After manual recovery, verify these folders exist:

```text
C:\Masters\26020_RTOS4\zephyrproject\zephyr
C:\Masters\26020_RTOS4\zephyrproject\apps\lab0
C:\Masters\26020_RTOS4\zephyrproject\apps\lab1
C:\Masters\26020_RTOS4\zephyrproject\apps\lab2
C:\Masters\26020_RTOS4\zephyrproject\apps\lab3
C:\Masters\26020_RTOS4\zephyrproject\modules\led
C:\Masters\26020_RTOS4\zephyrproject\.vscode
C:\Backup\26020_RTOS4\Solutions
C:\Backup\26020_RTOS4\Solutions\.vscode
C:\Backup\26020_RTOS4\26020_RTOS4_Installer.bat
C:\Backup\26020_RTOS4\26020_restore.bat
```

Then try building one lab:

```cmd
cd /d C:\Masters\26020_RTOS4\zephyrproject
.venv\Scripts\activate.bat
west build -p always -b same54_xpro apps\lab0 -d build_lab0
```

If this build finishes without errors, the Zephyr environment and lab copy are likely usable.

---

## 12. Important notes

- Do not delete `C:\Install\26020_RTOS4`.
- Do not copy Zephyr source code or downloaded Zephyr modules into `C:\Backup\26020_RTOS4`.
- `C:\Backup\26020_RTOS4` should contain backup class material such as `Solutions`, `.vscode`, installer script, and restore script.
- `C:\Masters\26020_RTOS4\zephyrproject` is the working Zephyr installation used for the labs.
