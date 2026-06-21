<# 
===============================================================================
26020_RTOS4 PowerShell Complex Installer

This script installs the 26020_RTOS4 Zephyr class on Windows 11 MASTERs machines.

Official entry point:
    26020_RTOS4_Installer.bat

Do not run this PowerShell script directly.

This script performs the following actions:

1. Copies the full installer package to:
      C:\Backup\26020_RTOS4

2. Explicitly copies the Solutions folder to:
      C:\Backup\26020_RTOS4\Solutions

3. Creates the class folder:
      C:\Masters\26020_RTOS4

4. Checks required pre-installed dependencies:
      - Python 3.12.x
      - Git
      - CMake
      - Ninja
      - Device Tree Compiler, dtc
      - OpenOCD 0.12.0 at C:\Masters\OpenOCD
      - Zephyr SDK 0.17.4 at C:\Users\Masters\zephyr-sdk-0.17.4

5. Creates a Python virtual environment inside:
      C:\Masters\26020_RTOS4\.venv

6. Installs west inside that virtual environment.

7. Downloads Zephyr source code version v4.3.0 into:
      C:\Masters\26020_RTOS4\zephyrproject

8. Copies labs into:
      C:\Masters\26020_RTOS4\zephyrproject\apps

9. Copies the led module into:
      C:\Masters\26020_RTOS4\zephyrproject\modules\led

10. Verifies that Zephyr source is v4.3.0.

IMPORTANT:
- This script uses a virtual environment for all Python work.
- This script does not install the Zephyr SDK.
- This script does not install OpenOCD.
- The Solutions folder is copied only to C:\Backup\26020_RTOS4\Solutions.
===============================================================================
#>

[CmdletBinding()]
param(
    [switch]$LaunchedFromBatch,

    [string]$PowerShellLogPath = ""
)

# -----------------------------------------------------------------------------
# Direct-run protection
# -----------------------------------------------------------------------------
# This PowerShell script must only be launched by:
#
#     26020_RTOS4_Installer.bat
#
# The .bat file passes -LaunchedFromBatch when it calls this script.
# If that switch is missing, stop immediately and warn the user.
# -----------------------------------------------------------------------------

if (-not $LaunchedFromBatch) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "WARNING: Do not run this PowerShell script directly." -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please close this window and run the official installer:"
    Write-Host ""
    Write-Host "    26020_RTOS4_Installer.bat"
    Write-Host ""
    Write-Host "This PowerShell script must only be launched by the .bat file."
    Write-Host ""

    Write-Host "Press any key to close this window..."
    try {
        [void][System.Console]::ReadKey($true)
    }
    catch {
        Read-Host "Press ENTER to close this window"
    }

    exit 1
}

# Stop on errors.
$ErrorActionPreference = "Stop"

# Track whether PowerShell transcript logging has started.
$TranscriptStarted = $false

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$ClassName = "26020_RTOS4"

$SourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$BackupRoot = "C:\Backup\$ClassName"
$ClassRoot  = "C:\Masters\$ClassName"

$ZephyrProjectRoot = Join-Path $ClassRoot "zephyrproject"
$AppsRoot          = Join-Path $ZephyrProjectRoot "apps"
$ModulesRoot       = Join-Path $ZephyrProjectRoot "modules"

$VenvRoot          = Join-Path $ClassRoot ".venv"
$VenvPython        = Join-Path $VenvRoot "Scripts\python.exe"
$VenvWest          = Join-Path $VenvRoot "Scripts\west.exe"

$ExpectedPythonMajor = 3
$ExpectedPythonMinor = 12

$ExpectedZephyrTag = "v4.3.0"

$ExpectedOpenOCDVersion = "0.12.0"
$OpenOCDExe = "C:\Masters\OpenOCD\bin\openocd.exe"

$ExpectedSDKVersion = "0.17.4"
$ZephyrSDKRoot = "C:\Users\Masters\zephyr-sdk-0.17.4"

$LogRoot = Join-Path $ClassRoot "install_logs"

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

function Write-Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$CommandName)

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

function Wait-BeforeExit {
    param(
        [int]$ExitCode
    )

    # The normal launcher is the .bat file, so the .bat file handles the final
    # pause. This function exists for safety.
    if (-not $LaunchedFromBatch) {
        Write-Host ""
        Write-Host "Press any key to close this PowerShell installer window..."

        try {
            [void][System.Console]::ReadKey($true)
        }
        catch {
            Read-Host "Press ENTER to close this PowerShell installer window"
        }
    }

    exit $ExitCode
}

function Start-InstallerTranscript {
    New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null

    if ([string]::IsNullOrWhiteSpace($PowerShellLogPath)) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:PowerShellLogPath = Join-Path $LogRoot "powershell_install_$Timestamp.log"
    }

    $PowerShellLogDirectory = Split-Path -Parent $PowerShellLogPath

    if (!(Test-Path $PowerShellLogDirectory)) {
        New-Item -ItemType Directory -Path $PowerShellLogDirectory -Force | Out-Null
    }

    Start-Transcript -Path $PowerShellLogPath -Force | Out-Null
    $script:TranscriptStarted = $true

    Write-Info "PowerShell transcript log: $PowerShellLogPath"
}

function Stop-InstallerTranscript {
    if ($script:TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Ignore transcript stop errors.
        }
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = ""
    )

    if ($WorkingDirectory -ne "") {
        Write-Info "Running in $WorkingDirectory : $FilePath $($Arguments -join ' ')"
        Push-Location $WorkingDirectory
    }
    else {
        Write-Info "Running: $FilePath $($Arguments -join ' ')"
    }

    try {
        & $FilePath @Arguments
        $exitCode = $LASTEXITCODE

        if ($null -ne $exitCode -and $exitCode -ne 0) {
            throw "Command failed with exit code $exitCode : $FilePath $($Arguments -join ' ')"
        }
    }
    finally {
        if ($WorkingDirectory -ne "") {
            Pop-Location
        }
    }
}

function Copy-WithRobocopy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (!(Test-Path $Source)) {
        throw "Source path does not exist: $Source"
    }

    if (!(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    Write-Info "Copying from '$Source' to '$Destination'"

    robocopy $Source $Destination /E /R:3 /W:5 /NFL /NDL /NP

    $rc = $LASTEXITCODE

    # Robocopy exit codes:
    # 0-7 are success or non-fatal copy conditions.
    # 8 or higher means failure.
    if ($rc -ge 8) {
        throw "Robocopy failed with exit code $rc while copying '$Source' to '$Destination'"
    }
}

function Find-SourceFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName
    )

    $candidates = @(
        (Join-Path $SourceRoot $FolderName),
        (Join-Path $SourceRoot "ClassMaterial\$FolderName"),
        (Join-Path $SourceRoot "ClassMaterial\apps\$FolderName"),
        (Join-Path $SourceRoot "apps\$FolderName")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

# -----------------------------------------------------------------------------
# Start installation
# -----------------------------------------------------------------------------

try {
    Write-Section "Starting $ClassName installation"

    New-Item -ItemType Directory -Path $ClassRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

    Start-InstallerTranscript

    Write-Info "Source root: $SourceRoot"
    Write-Info "Backup root: $BackupRoot"
    Write-Info "Class root : $ClassRoot"

    # -------------------------------------------------------------------------
    # Check Windows version
    # -------------------------------------------------------------------------

    Write-Section "Checking Windows version"

    $os = Get-CimInstance Win32_OperatingSystem
    Write-Info "Detected OS: $($os.Caption) $($os.Version)"

    if ($os.Caption -notlike "*Windows 11*") {
        Write-Warn "This script is intended for Windows 11 MASTERs ghosting machines."
        Write-Warn "Continuing anyway, but please verify the installation carefully."
    }

    # -------------------------------------------------------------------------
    # Copy full installer package to C:\Backup
    # -------------------------------------------------------------------------

    Write-Section "Copying full installer package to C:\Backup"

    Copy-WithRobocopy -Source $SourceRoot -Destination $BackupRoot

    # -------------------------------------------------------------------------
    # Explicitly copy Solutions folder to C:\Backup\26020_RTOS4\Solutions
    # -------------------------------------------------------------------------

    Write-Section "Copying Solutions folder to C:\Backup"

    $SolutionsSource = Find-SourceFolder -FolderName "Solutions"
    $SolutionsDestination = Join-Path $BackupRoot "Solutions"

    if ($null -eq $SolutionsSource) {
        throw "Required Solutions folder was not found in the installer package. Expected a folder named 'Solutions'."
    }

    if (Test-Path $SolutionsDestination) {
        Write-Info "Removing existing Backup Solutions folder: $SolutionsDestination"
        Remove-Item $SolutionsDestination -Recurse -Force
    }

    Copy-WithRobocopy -Source $SolutionsSource -Destination $SolutionsDestination

    Write-Info "Solutions folder copied successfully."
    Write-Info "Solutions source     : $SolutionsSource"
    Write-Info "Solutions destination: $SolutionsDestination"

    # -------------------------------------------------------------------------
    # Copy installer files and README to C:\Masters class folder
    # -------------------------------------------------------------------------

    Write-Section "Copying README and installer files to C:\Masters"

    $filesToCopy = @(
        "README.txt",
        "26020_RTOS4_Installer.bat",
        "Install-26020_RTOS4.ps1"
    )

    foreach ($file in $filesToCopy) {
        $srcFile = Join-Path $SourceRoot $file

        if (Test-Path $srcFile) {
            Copy-Item $srcFile $ClassRoot -Force
            Write-Info "Copied $file to $ClassRoot"
        }
        else {
            Write-Warn "$file was not found in source package."
        }
    }

    # -------------------------------------------------------------------------
    # Check required pre-installed dependencies
    # -------------------------------------------------------------------------

    Write-Section "Checking required pre-installed dependencies"

    if (!(Test-CommandExists "python")) {
        throw "Python was not found in PATH. Python 3.12.x is required."
    }

    $pythonVersionText = python --version 2>&1
    Write-Info "Detected Python: $pythonVersionText"

    if ($pythonVersionText -notmatch "Python\s+(\d+)\.(\d+)\.(\d+)") {
        throw "Could not parse Python version from: $pythonVersionText"
    }

    $pyMajor = [int]$Matches[1]
    $pyMinor = [int]$Matches[2]

    if ($pyMajor -ne $ExpectedPythonMajor -or $pyMinor -ne $ExpectedPythonMinor) {
        throw "Python $ExpectedPythonMajor.$ExpectedPythonMinor.x is required. Detected: $pythonVersionText"
    }

    if (!(Test-CommandExists "git")) {
        throw "Git was not found in PATH."
    }

    Write-Info "Detected Git: $(git --version)"

    if (!(Test-CommandExists "cmake")) {
        throw "CMake was not found in PATH."
    }

    Write-Info "Detected CMake: $(cmake --version | Select-Object -First 1)"

    if (!(Test-CommandExists "ninja")) {
        throw "Ninja was not found in PATH."
    }

    Write-Info "Detected Ninja: $(ninja --version)"

    if (!(Test-CommandExists "dtc")) {
        throw "Device Tree Compiler 'dtc' was not found in PATH."
    }

    Write-Info "Detected DTC: $(dtc --version)"

    if (!(Test-Path $OpenOCDExe)) {
        throw "OpenOCD executable was not found at expected path: $OpenOCDExe"
    }

    $openocdVersionOutput = & $OpenOCDExe --version 2>&1

    Write-Info "Detected OpenOCD output:"
    $openocdVersionOutput | ForEach-Object {
        Write-Info $_
    }

    if (($openocdVersionOutput -join "`n") -notmatch [regex]::Escape($ExpectedOpenOCDVersion)) {
        throw "OpenOCD version $ExpectedOpenOCDVersion is required."
    }

    if (!(Test-Path $ZephyrSDKRoot)) {
        throw "Zephyr SDK $ExpectedSDKVersion was not found at expected path: $ZephyrSDKRoot"
    }

    $sdkSetupCmd = Join-Path $ZephyrSDKRoot "setup.cmd"

    if (!(Test-Path $sdkSetupCmd)) {
        Write-Warn "Zephyr SDK folder exists, but setup.cmd was not found at: $sdkSetupCmd"
        Write-Warn "The SDK may still work if registry entries were already created."
    }

    Write-Info "Zephyr SDK $ExpectedSDKVersion folder found at $ZephyrSDKRoot"

    # -------------------------------------------------------------------------
    # Create required Zephyr folder structure
    # -------------------------------------------------------------------------

    Write-Section "Creating Zephyr class folder structure"

    New-Item -ItemType Directory -Path $ZephyrProjectRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $AppsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $ModulesRoot -Force | Out-Null

    Write-Info "Created/verified: $ZephyrProjectRoot"
    Write-Info "Created/verified: $AppsRoot"
    Write-Info "Created/verified: $ModulesRoot"

    # -------------------------------------------------------------------------
    # Create Python virtual environment
    # -------------------------------------------------------------------------

    Write-Section "Creating Python virtual environment"

    if (!(Test-Path $VenvPython)) {
        Write-Info "Creating virtual environment at: $VenvRoot"
        Invoke-External -FilePath "python" -Arguments @("-m", "venv", $VenvRoot)
    }
    else {
        Write-Info "Virtual environment already exists at: $VenvRoot"
    }

    if (!(Test-Path $VenvPython)) {
        throw "Virtual environment Python was not found after creation: $VenvPython"
    }

    Write-Info "Virtual environment Python: $VenvPython"

    Invoke-External -FilePath $VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "pip")
    Invoke-External -FilePath $VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "west")

    if (!(Test-Path $VenvWest)) {
        throw "west was not found in the virtual environment after installation: $VenvWest"
    }

    Write-Info "west installed in virtual environment: $VenvWest"

    # -------------------------------------------------------------------------
    # Install Zephyr source code v4.3.0
    # -------------------------------------------------------------------------

    Write-Section "Installing Zephyr source code $ExpectedZephyrTag"

    $WestConfigFolder = Join-Path $ZephyrProjectRoot ".west"
    $ZephyrSourceRoot = Join-Path $ZephyrProjectRoot "zephyr"

    if (!(Test-Path $WestConfigFolder)) {
        Write-Info "Initializing Zephyr workspace at: $ZephyrProjectRoot"

        Invoke-External `
            -FilePath $VenvWest `
            -Arguments @(
                "init",
                "-m", "https://github.com/zephyrproject-rtos/zephyr",
                "--mr", $ExpectedZephyrTag,
                $ZephyrProjectRoot
            )
    }
    else {
        Write-Info "Existing west workspace detected at: $ZephyrProjectRoot"
    }

    Write-Info "Running west update. This may take a while because Zephyr is large."
    Invoke-External -FilePath $VenvWest -Arguments @("update") -WorkingDirectory $ZephyrProjectRoot

    Write-Info "Exporting Zephyr CMake package."
    Invoke-External -FilePath $VenvWest -Arguments @("zephyr-export") -WorkingDirectory $ZephyrProjectRoot

    Write-Info "Installing Zephyr Python dependencies inside the virtual environment."

    $requirementsFile = Join-Path $ZephyrSourceRoot "scripts\requirements.txt"

    if (Test-Path $requirementsFile) {
        Invoke-External -FilePath $VenvPython -Arguments @("-m", "pip", "install", "-r", $requirementsFile)
    }
    else {
        Write-Warn "Could not find requirements file: $requirementsFile"
        Write-Warn "Trying west packages pip --install instead."
        Invoke-External -FilePath $VenvWest -Arguments @("packages", "pip", "--install") -WorkingDirectory $ZephyrProjectRoot
    }

    # -------------------------------------------------------------------------
    # Verify Zephyr source version
    # -------------------------------------------------------------------------

    Write-Section "Verifying Zephyr source version"

    if (!(Test-Path $ZephyrSourceRoot)) {
        throw "Zephyr source folder was not found: $ZephyrSourceRoot"
    }

    Invoke-External -FilePath "git" -Arguments @("-C", $ZephyrSourceRoot, "fetch", "--tags", "--force")

    $currentCommit = git -C $ZephyrSourceRoot rev-parse HEAD
    $expectedCommit = git -C $ZephyrSourceRoot rev-list -n 1 $ExpectedZephyrTag

    Write-Info "Current Zephyr commit         : $currentCommit"
    Write-Info "Expected $ExpectedZephyrTag commit : $expectedCommit"

    if ($currentCommit -ne $expectedCommit) {
        throw "Zephyr source is not at $ExpectedZephyrTag. Current commit: $currentCommit"
    }

    Write-Info "Zephyr source version verified as $ExpectedZephyrTag"

    # -------------------------------------------------------------------------
    # Copy labs into zephyrproject\apps
    # -------------------------------------------------------------------------

    Write-Section "Copying lab folders into zephyrproject\apps"

    $labs = @("lab0", "lab1", "lab2", "lab3")

    foreach ($lab in $labs) {
        $labSource = Find-SourceFolder -FolderName $lab
        $labDestination = Join-Path $AppsRoot $lab

        if ($null -eq $labSource) {
            throw "Required lab folder '$lab' was not found in the installer package."
        }

        if (Test-Path $labDestination) {
            Write-Info "Removing existing destination lab folder: $labDestination"
            Remove-Item $labDestination -Recurse -Force
        }

        Copy-WithRobocopy -Source $labSource -Destination $labDestination
        Write-Info "Installed $lab to $labDestination"
    }

    # -------------------------------------------------------------------------
    # Copy led module into zephyrproject\modules
    # -------------------------------------------------------------------------

    Write-Section "Copying led module into zephyrproject\modules"

    $ledSource = Find-SourceFolder -FolderName "led"
    $ledDestination = Join-Path $ModulesRoot "led"

    if ($null -eq $ledSource) {
        throw "Required led module folder was not found in the installer package."
    }

    if (Test-Path $ledDestination) {
        Write-Info "Removing existing led module folder: $ledDestination"
        Remove-Item $ledDestination -Recurse -Force
    }

    Copy-WithRobocopy -Source $ledSource -Destination $ledDestination
    Write-Info "Installed led module to $ledDestination"

    # -------------------------------------------------------------------------
    # Final success message
    # -------------------------------------------------------------------------

    Write-Section "$ClassName installation completed successfully"

    Write-Host ""
    Write-Host "Installed locations:"
    Write-Host "  Backup package : $BackupRoot"
    Write-Host "  Solutions      : $SolutionsDestination"
    Write-Host "  Class folder   : $ClassRoot"
    Write-Host "  Zephyr project : $ZephyrProjectRoot"
    Write-Host "  Apps folder    : $AppsRoot"
    Write-Host "  LED module     : $ledDestination"
    Write-Host ""
    Write-Host "Next verification step:"
    Write-Host "  Build and flash lab0 using the instructions in README.txt"
    Write-Host ""

    Stop-InstallerTranscript

    Wait-BeforeExit -ExitCode 0
}
catch {
    Write-Fail $_.Exception.Message

    Write-Host ""
    Write-Host "The installation did not complete successfully."
    Write-Host "Please review the log folder:"
    Write-Host "  $LogRoot"
    Write-Host ""

    Stop-InstallerTranscript

    Wait-BeforeExit -ExitCode 1
}