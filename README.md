26020_RTOS4 INSTALL README
=========================

Class:
    26020_RTOS4

Operating System:
    Windows 11

IMPORTANT:
    Run only this file:

        26020_RTOS4_Installer.bat

    Do not run Install-26020_RTOS4.ps1 directly.
    The PowerShell script is launched automatically by the .bat file.


1. Before Running the Installer
-------------------------------

After unzipping 26020_RTOS4_install.zip, confirm the folder contains:

    26020_RTOS4_Installer.bat
    Install-26020_RTOS4.ps1
    README.txt
    lab0
    lab1
    lab2
    lab3
    led
    Solutions

If any of these files or folders are missing, do not run the installer.


2. Run the Installer
--------------------

1. Open the unzipped 26020_RTOS4 installer folder.

2. Double-click:

       26020_RTOS4_Installer.bat

3. Wait for the installer to finish.

4. Do not close the installer window while it is running.

5. At the end, the window will say:

       Press any key to close this installer window...

6. Review the final message, then press any key to close the window.


3. What the Installer Creates
-----------------------------

The installer creates or copies files to these locations:

    C:\Backup\26020_RTOS4

    C:\Backup\26020_RTOS4\Solutions

    C:\Masters\26020_RTOS4

    C:\Masters\26020_RTOS4\zephyrproject

    C:\Masters\26020_RTOS4\zephyrproject\apps\lab0
    C:\Masters\26020_RTOS4\zephyrproject\apps\lab1
    C:\Masters\26020_RTOS4\zephyrproject\apps\lab2
    C:\Masters\26020_RTOS4\zephyrproject\apps\lab3

    C:\Masters\26020_RTOS4\zephyrproject\modules\led


4. Tools Checked by the Installer
---------------------------------

The installer checks that the required tools are already installed.

It checks for:

    Python 3.12.x
    Git
    CMake
    Ninja
    Device Tree Compiler, dtc
    Zephyr SDK 0.17.4
    OpenOCD 0.12.0

Expected Zephyr SDK location:

    C:\Users\Masters\zephyr-sdk-0.17.4

Expected OpenOCD location:

    C:\Masters\OpenOCD

The installer does not install Zephyr SDK or OpenOCD.
They are expected to already be present on the Windows 11 ghosting computer.


5. Log Files
------------

The installer saves log files here:

    C:\Masters\26020_RTOS4\install_logs

There will be two log files:

    batch_launcher_YYYYMMDD_HHMMSS.log
    powershell_install_YYYYMMDD_HHMMSS.log

If the installer fails, check these logs.


6. Quick Lab 0 Verification
---------------------------

After the installer completes successfully, verify lab0.

Open Command Prompt.

First activate the virtual environment:

    cd C:\Masters\26020_RTOS4\zephyrproject\.venv\Scripts
    activate

After activation, go to the lab0 folder:

    cd C:\Masters\26020_RTOS4\zephyrproject\apps\lab0

Build lab0:

    west build -p always -b same54_xpro -d build_same54_xpro

Connect the debug USB port of the SAME54 Xplained Pro board to the PC.

Open PuTTY:

    Select the correct COM port.
    Set baud rate to 115200.
    Open the serial connection.

Flash lab0:

    west flash -d build_same54_xpro

Press switch0 on the SAME54 Xplained Pro board.

Expected PuTTY message:

    Button is PRESSED!


7. If Something Goes Wrong
--------------------------

Do not manually edit the installed folders to fix the setup.

Instead:

    1. Check the log files in:

           C:\Masters\26020_RTOS4\install_logs

    2. Fix the installer package if needed.

    3. Run 26020_RTOS4_Installer.bat again.

The install process must be repeatable on Windows 11 ghosting computers.