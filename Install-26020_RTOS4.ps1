<# 
===============================================================================
26020_RTOS4 PowerShell Complex Installer

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
      - OpenOCD version 0.12.0
      - Zephyr SDK version 0.17.4

   Important:
      OpenOCD and Zephyr SDK are checked by version only.
      This script does not require a fixed OpenOCD install location.
      This script does not require a fixed Zephyr SDK install location.

5. Creates a Python virtual environment inside:
      C:\Masters\26020_RTOS4\zephyrproject\.venv

6. Installs west inside that virtual environment.

7. Downloads Zephyr source code version v4.3.0 into:
      C:\Masters\26020_RTOS4\zephyrproject

8. Copies labs into:
      C:\Masters\26020_RTOS4\zephyrproject\apps

9. Copies the led module into:
      C:\Masters\26020_RTOS4\zephyrproject\modules\led

10. Verifies that Zephyr source is v4.3.0.

Logging:
- The .bat file creates the batch launcher log.
- This script creates the PowerShell transcript log.
- All collected errors are printed together in one final ERROR SUMMARY section.

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

$ErrorActionPreference = "Stop"

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

# Virtual environment is intentionally inside zephyrproject.
$VenvRoot          = Join-Path $ZephyrProjectRoot ".venv"
$VenvPython        = Join-Path $VenvRoot "Scripts\python.exe"
$VenvWest          = Join-Path $VenvRoot "Scripts\west.exe"

$ExpectedPythonMajor = 3
$ExpectedPythonMinor = 12

$ExpectedZephyrTag = "v4.3.0"

$ExpectedOpenOCDVersion = "0.12.0"
$ExpectedSDKVersion     = "0.17.4"

$LogRoot = Join-Path $ClassRoot "install_logs"

# -----------------------------------------------------------------------------
# Script-level state
# -----------------------------------------------------------------------------

$script:TranscriptStarted = $false
$script:ResolvedPowerShellLogPath = $PowerShellLogPath
$script:ErrorSummary = New-Object System.Collections.Generic.List[string]

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

function Add-InstallerError {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

    if (-not $script:ErrorSummary.Contains($Message)) {
        $script:ErrorSummary.Add($Message) | Out-Null
    }
}

function Write-ErrorSummarySection {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "ERROR SUMMARY" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""

    if ($script:ErrorSummary.Count -eq 0) {
        Write-Host "The installer failed, but no detailed error was collected." -ForegroundColor Red
        Write-Host "Review the PowerShell transcript log for more information." -ForegroundColor Red
    }
    else {
        Write-Host "The installer cannot continue because of the following issue(s):" -ForegroundColor Red
        Write-Host ""

        $index = 1
        foreach ($err in $script:ErrorSummary) {
            Write-Host "  $index. $err" -ForegroundColor Red
            $index++
        }
    }

    Write-Host ""
    Write-Host "Recommended action:" -ForegroundColor Yellow
    Write-Host "  1. Review the errors above."
    Write-Host "  2. Correct the missing tools, wrong versions, or installer package."
    Write-Host "  3. Run 26020_RTOS4_Installer.bat again."
    Write-Host ""
    Write-Host "Log folder:"
    Write-Host "  $LogRoot"
    Write-Host ""
}

function Wait-BeforeExit {
    param(
        [int]$ExitCode
    )

    # The .bat launcher handles the final pause.
    # This fallback is kept for controlled non-batch launch cases.
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

    if ([string]::IsNullOrWhiteSpace($script:ResolvedPowerShellLogPath)) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:ResolvedPowerShellLogPath = Join-Path $LogRoot "powershell_install_$Timestamp.log"
    }

    $PowerShellLogDirectory = Split-Path -Parent $script:ResolvedPowerShellLogPath

    if (!(Test-Path $PowerShellLogDirectory)) {
        New-Item -ItemType Directory -Path $PowerShellLogDirectory -Force | Out-Null
    }

    Start-Transcript -Path $script:ResolvedPowerShellLogPath -Force | Out-Null
    $script:TranscriptStarted = $true

    Write-Info "PowerShell transcript log: $script:ResolvedPowerShellLogPath"
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

    $displayCommand = "$FilePath $($Arguments -join ' ')"

    if ($WorkingDirectory -ne "") {
        Write-Info "Running in $WorkingDirectory : $displayCommand"
        Push-Location $WorkingDirectory
    }
    else {
        Write-Info "Running: $displayCommand"
    }

    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE

        if ($output) {
            Write-Info "Command output:"
            $output | ForEach-Object {
                Write-Host "       $_"
            }
        }

        if ($null -ne $exitCode -and $exitCode -ne 0) {
            $outputText = ($output | Out-String).Trim()

            if ([string]::IsNullOrWhiteSpace($outputText)) {
                $outputText = "No command output was captured."
            }

            Add-InstallerError "Command failed with exit code $exitCode. Command: $displayCommand. Output: $outputText"
            throw "External command failed: $displayCommand"
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
        Add-InstallerError "Source path does not exist: $Source"
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
        Add-InstallerError "Robocopy failed with exit code $rc while copying '$Source' to '$Destination'."
        throw "Robocopy failed with exit code $rc."
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

function Get-VersionFromText {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    if ($Text -match "(\d+\.\d+\.\d+)") {
        return $Matches[1]
    }

    return $null
}

function Add-ZephyrSdkCandidate {
    param(
        [System.Collections.Generic.List[string]]$Candidates,
        [string]$CandidateText
    )

    if ([string]::IsNullOrWhiteSpace($CandidateText)) {
        return
    }

    # Match strings like:
    #   zephyr-sdk-0.17.4
    #   zephyr-sdk_0.17.4
    #   zephyr_sdk-0.17.4
    #   ZEPHYR_SDK_INSTALL_DIR=C:\...\zephyr-sdk-0.17.4
    if ($CandidateText -match "zephyr[-_]?sdk[-_]?(\d+\.\d+\.\d+)") {
        $version = $Matches[1]

        if (-not $Candidates.Contains($version)) {
            $Candidates.Add($version) | Out-Null
        }
    }
}

function Get-ZephyrSdkVersionCandidates {
    $candidates = New-Object System.Collections.Generic.List[string]

    # 1. Check environment variables that mention Zephyr and SDK.
    Get-ChildItem Env: | ForEach-Object {
        $name = $_.Name
        $value = $_.Value

        if ($name -match "ZEPHYR|SDK" -or $value -match "zephyr[-_]?sdk") {
            Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText "$name=$value"
        }
    }

    # 2. Check PATH entries for zephyr-sdk-x.y.z.
    $pathValue = [Environment]::GetEnvironmentVariable("PATH", "Process")
    if (-not [string]::IsNullOrWhiteSpace($pathValue)) {
        $pathValue.Split(";") | ForEach-Object {
            Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText $_
        }
    }

    $userPathValue = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not [string]::IsNullOrWhiteSpace($userPathValue)) {
        $userPathValue.Split(";") | ForEach-Object {
            Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText $_
        }
    }

    $machinePathValue = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if (-not [string]::IsNullOrWhiteSpace($machinePathValue)) {
        $machinePathValue.Split(";") | ForEach-Object {
            Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText $_
        }
    }

    # 3. Check CMake package registry entries.
    # Zephyr SDK setup.cmd normally registers CMake package information.
    $registryRoots = @(
        "HKCU:\Software\Kitware\CMake\Packages",
        "HKLM:\Software\Kitware\CMake\Packages",
        "HKLM:\Software\WOW6432Node\Kitware\CMake\Packages"
    )

    foreach ($root in $registryRoots) {
        if (Test-Path $root) {
            try {
                Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                    $keyPath = $_.PsPath
                    Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText $keyPath

                    try {
                        $props = Get-ItemProperty -Path $_.PsPath -ErrorAction SilentlyContinue
                        if ($null -ne $props) {
                            $props.PSObject.Properties | ForEach-Object {
                                Add-ZephyrSdkCandidate -Candidates $candidates -CandidateText "$($_.Name)=$($_.Value)"
                            }
                        }
                    }
                    catch {
                        # Ignore registry property read errors.
                    }
                }
            }
            catch {
                Write-Warn "Could not fully read CMake package registry root: $root"
            }
        }
    }

    return $candidates
}

function Test-RequiredDependencies {
    Write-Section "Checking required pre-installed dependencies"

    $errorCountAtStart = $script:ErrorSummary.Count

    # -----------------------------
    # Python check
    # -----------------------------
    Write-Info "Checking Python..."

    $pythonCmd = Get-Command "python" -ErrorAction SilentlyContinue

    if ($null -eq $pythonCmd) {
        Add-InstallerError "Python was not found in PATH. Required version: Python 3.12.x."
    }
    else {
        try {
            $pythonVersionText = python --version 2>&1
            Write-Info "Detected Python: $pythonVersionText"

            if ($pythonVersionText -notmatch "Python\s+(\d+)\.(\d+)\.(\d+)") {
                Add-InstallerError "Python was found, but the version could not be parsed. Output: $pythonVersionText"
            }
            else {
                $pyMajor = [int]$Matches[1]
                $pyMinor = [int]$Matches[2]

                if ($pyMajor -ne $ExpectedPythonMajor -or $pyMinor -ne $ExpectedPythonMinor) {
                    Add-InstallerError "Wrong Python version. Required: Python $ExpectedPythonMajor.$ExpectedPythonMinor.x. Detected: $pythonVersionText"
                }
            }
        }
        catch {
            Add-InstallerError "Python was found, but running 'python --version' failed. Error: $($_.Exception.Message)"
        }
    }

    # -----------------------------
    # Git check
    # -----------------------------
    Write-Info "Checking Git..."

    $gitCmd = Get-Command "git" -ErrorAction SilentlyContinue

    if ($null -eq $gitCmd) {
        Add-InstallerError "Git was not found in PATH."
    }
    else {
        try {
            $gitVersion = git --version 2>&1
            Write-Info "Detected Git: $gitVersion"
        }
        catch {
            Add-InstallerError "Git was found, but running 'git --version' failed. Error: $($_.Exception.Message)"
        }
    }

    # -----------------------------
    # CMake check
    # -----------------------------
    Write-Info "Checking CMake..."

    $cmakeCmd = Get-Command "cmake" -ErrorAction SilentlyContinue

    if ($null -eq $cmakeCmd) {
        Add-InstallerError "CMake was not found in PATH."
    }
    else {
        try {
            $cmakeVersion = cmake --version 2>&1 | Select-Object -First 1
            Write-Info "Detected CMake: $cmakeVersion"
        }
        catch {
            Add-InstallerError "CMake was found, but running 'cmake --version' failed. Error: $($_.Exception.Message)"
        }
    }

    # -----------------------------
    # Ninja check
    # -----------------------------
    Write-Info "Checking Ninja..."

    $ninjaCmd = Get-Command "ninja" -ErrorAction SilentlyContinue

    if ($null -eq $ninjaCmd) {
        Add-InstallerError "Ninja was not found in PATH."
    }
    else {
        try {
            $ninjaVersion = ninja --version 2>&1
            Write-Info "Detected Ninja: $ninjaVersion"
        }
        catch {
            Add-InstallerError "Ninja was found, but running 'ninja --version' failed. Error: $($_.Exception.Message)"
        }
    }

    # -----------------------------
    # Device Tree Compiler check
    # -----------------------------
    Write-Info "Checking Device Tree Compiler, dtc..."

    $dtcCmd = Get-Command "dtc" -ErrorAction SilentlyContinue

    if ($null -eq $dtcCmd) {
        Add-InstallerError "Device Tree Compiler 'dtc' was not found in PATH."
    }
    else {
        try {
            $dtcVersion = dtc --version 2>&1
            Write-Info "Detected DTC: $dtcVersion"
        }
        catch {
            Add-InstallerError "dtc was found, but running 'dtc --version' failed. Error: $($_.Exception.Message)"
        }
    }

    # -----------------------------
    # OpenOCD version check only
    # -----------------------------
    Write-Info "Checking OpenOCD version only..."

    $openocdCmd = Get-Command "openocd" -ErrorAction SilentlyContinue

    if ($null -eq $openocdCmd) {
        Add-InstallerError "OpenOCD version could not be checked because 'openocd' was not found in PATH. Required version: $ExpectedOpenOCDVersion."
    }
    else {
        Write-Info "OpenOCD command found: $($openocdCmd.Source)"

        # Some OpenOCD builds, including Sysprogs, print the version banner on
        # stderr. With `$ErrorActionPreference = "Stop"`, PowerShell can treat
        # that stderr text as a failure even when OpenOCD is working correctly.
        # Temporarily relax ErrorActionPreference and check the captured text
        # ourselves instead of letting PowerShell turn the banner into an error.
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        try {
            $openocdVersionOutput = & $openocdCmd.Source --version 2>&1
            $openocdExitCode = $LASTEXITCODE
        }
        catch {
            $openocdVersionOutput = @($_.Exception.Message)
            $openocdExitCode = 1
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $openocdVersionText = (($openocdVersionOutput | ForEach-Object { $_.ToString() }) -join "`n").Trim()

        Write-Info "Detected OpenOCD output:"
        if ([string]::IsNullOrWhiteSpace($openocdVersionText)) {
            Write-Host "       <no output>"
        }
        else {
            $openocdVersionText -split "`r?`n" | ForEach-Object {
                Write-Host "       $_"
            }
        }

        if ($openocdVersionText -notmatch [regex]::Escape($ExpectedOpenOCDVersion)) {
            Add-InstallerError "Wrong OpenOCD version. Required: $ExpectedOpenOCDVersion. Detected output: $openocdVersionText"
        }
        elseif ($null -ne $openocdExitCode -and $openocdExitCode -ne 0) {
            Add-InstallerError "OpenOCD version text contains $ExpectedOpenOCDVersion, but 'openocd --version' returned exit code $openocdExitCode. Output: $openocdVersionText"
        }
    }

    # -----------------------------
    # Zephyr SDK version check only
    # -----------------------------
    Write-Info "Checking Zephyr SDK version only..."

    $sdkCandidates = Get-ZephyrSdkVersionCandidates

    if ($sdkCandidates.Count -eq 0) {
        Add-InstallerError "Zephyr SDK version could not be detected. Required version: $ExpectedSDKVersion. Make sure the Zephyr SDK setup has been run and registered with the environment/CMake package registry."
    }
    else {
        Write-Info "Detected Zephyr SDK version candidate(s): $($sdkCandidates -join ', ')"

        if (-not $sdkCandidates.Contains($ExpectedSDKVersion)) {
            Add-InstallerError "Wrong Zephyr SDK version. Required: $ExpectedSDKVersion. Detected candidate version(s): $($sdkCandidates -join ', ')"
        }
    }

    # -----------------------------
    # Final dependency result
    # -----------------------------
    if ($script:ErrorSummary.Count -gt $errorCountAtStart) {
        throw "Required dependency check failed."
    }
    else {
        Write-Host ""
        Write-Host "All required dependency checks passed." -ForegroundColor Green
        Write-Host ""
    }
}

function Get-GitSingleLineOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    $output = & git @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $outputText = ($output | Out-String).Trim()
        Add-InstallerError "$FailureMessage Output: $outputText"
        throw $FailureMessage
    }

    return (($output | Select-Object -First 1).ToString().Trim())
}

# -----------------------------------------------------------------------------
# Main installation flow
# -----------------------------------------------------------------------------

try {
    Write-Section "Starting $ClassName installation"

    # Create main folders early so logging can start.
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
        Add-InstallerError "Required Solutions folder was not found in the installer package. Expected a folder named 'Solutions'."
        throw "Required Solutions folder was not found."
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
    # Copy README and installer files to C:\Masters
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
    # Check dependencies before Zephyr installation
    # -------------------------------------------------------------------------

    Test-RequiredDependencies

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
        Add-InstallerError "Virtual environment Python was not found after creation: $VenvPython"
        throw "Virtual environment creation failed."
    }

    Write-Info "Virtual environment Python: $VenvPython"

    Invoke-External -FilePath $VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "pip")
    Invoke-External -FilePath $VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "west")

    if (!(Test-Path $VenvWest)) {
        Add-InstallerError "west was not found in the virtual environment after installation: $VenvWest"
        throw "west installation failed."
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
        Add-InstallerError "Zephyr source folder was not found: $ZephyrSourceRoot"
        throw "Zephyr source folder was not found."
    }

    Invoke-External -FilePath "git" -Arguments @("-C", $ZephyrSourceRoot, "fetch", "--tags", "--force")

    $currentCommit = Get-GitSingleLineOutput `
        -Arguments @("-C", $ZephyrSourceRoot, "rev-parse", "HEAD") `
        -FailureMessage "Could not determine current Zephyr commit."

    $expectedCommit = Get-GitSingleLineOutput `
        -Arguments @("-C", $ZephyrSourceRoot, "rev-list", "-n", "1", $ExpectedZephyrTag) `
        -FailureMessage "Could not determine expected Zephyr commit for tag $ExpectedZephyrTag."

    Write-Info "Current Zephyr commit             : $currentCommit"
    Write-Info "Expected $ExpectedZephyrTag commit: $expectedCommit"

    if ($currentCommit -ne $expectedCommit) {
        Add-InstallerError "Zephyr source is not at $ExpectedZephyrTag. Current commit: $currentCommit. Expected commit: $expectedCommit."
        throw "Zephyr source version verification failed."
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
            Add-InstallerError "Required lab folder '$lab' was not found in the installer package."
            throw "Required lab folder '$lab' was not found."
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
        Add-InstallerError "Required led module folder was not found in the installer package."
        throw "Required led module folder was not found."
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
    Write-Host "  Virtual env    : $VenvRoot"
    Write-Host "  Apps folder    : $AppsRoot"
    Write-Host "  LED module     : $ledDestination"
    Write-Host ""
    Write-Host "Logs:"
    Write-Host "  PowerShell log : $script:ResolvedPowerShellLogPath"
    Write-Host "  Log folder     : $LogRoot"
    Write-Host ""
    Write-Host "Next verification step:"
    Write-Host "  Activate the virtual environment and build/flash lab0 using README.txt."
    Write-Host ""

    Stop-InstallerTranscript

    Wait-BeforeExit -ExitCode 0
}
catch {
    $exceptionMessage = $_.Exception.Message

    $genericMessagesToSkip = @(
        "Required dependency check failed.",
        "External command failed"
    )

    $shouldAddException = $true

    foreach ($generic in $genericMessagesToSkip) {
        if ($exceptionMessage -like "$generic*") {
            $shouldAddException = $false
        }
    }

    if ($shouldAddException) {
        Add-InstallerError $exceptionMessage
    }

    Write-ErrorSummarySection

    Stop-InstallerTranscript

    Wait-BeforeExit -ExitCode 1
}