<#
.SYNOPSIS
  Builds, gathers dependencies (including MSVC C++ runtime DLLs), and creates a 100% portable zero-install ZIP
  and optional Inno Setup installer for Caskly POS Windows Desktop.

.USAGE
  Run in PowerShell from the Ruts directory on a Windows machine:
    powershell -ExecutionPolicy Bypass -File .\package_windows.ps1
#>

param(
    [switch]$SkipBuild = $false,
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Caskly POS - Windows Zero-Dependency Packager   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Ensure we are in the Ruts project directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "Please run this script from the 'Ruts' project root directory (where pubspec.yaml is located)."
}

# 2. Build release if not skipped
if (-not $SkipBuild) {
    Write-Host "`n[1/5] Building Flutter Windows Release..." -ForegroundColor Yellow
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter release build failed. Please resolve build errors and retry."
    }
} else {
    Write-Host "`n[1/5] Skipping Flutter build as requested (-SkipBuild)." -ForegroundColor Yellow
}

$ReleaseDir = "build\windows\x64\runner\Release"
if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Release directory '$ReleaseDir' not found. Build may have failed."
}

# 3. Verify and bundle Microsoft Visual C++ Runtime DLLs
Write-Host "`n[2/5] Checking and bundling MSVC C++ Runtime DLLs (vcruntime140.dll, msvcp140.dll)..." -ForegroundColor Yellow

$RequiredDlls = @(
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

$MissingDlls = @()
foreach ($dll in $RequiredDlls) {
    $dllPath = Join-Path $ReleaseDir $dll
    if (-not (Test-Path $dllPath)) {
        $MissingDlls += $dll
    }
}

if ($MissingDlls.Count -gt 0) {
    Write-Host "  CMake did not bundle all CRT DLLs. Locating Visual Studio Redistributable folder..." -ForegroundColor Cyan

    $VswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $VsPath = $null

    if (Test-Path $VswherePath) {
        $VsPath = & $VswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    }

    if (-not $VsPath -and $env:VSINSTALLDIR) {
        $VsPath = $env:VSINSTALLDIR
    }

    if (-not $VsPath) {
        $PossiblePaths = @(
            "C:\Program Files\Microsoft Visual Studio\2022\Community",
            "C:\Program Files\Microsoft Visual Studio\2022\Professional",
            "C:\Program Files\Microsoft Visual Studio\2022\Enterprise",
            "C:\Program Files\Microsoft Visual Studio\2022\BuildTools",
            "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community",
            "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional"
        )
        foreach ($p in $PossiblePaths) {
            if (Test-Path $p) {
                $VsPath = $p
                break
            }
        }
    }

    if ($VsPath) {
        $RedistBase = Join-Path $VsPath "VC\Redist\MSVC"
        if (Test-Path $RedistBase) {
            $LatestRedist = Get-ChildItem -Directory $RedistBase | Sort-Object Name -Descending | Select-Object -First 1
            if ($LatestRedist) {
                $CrtFolder = Join-Path $LatestRedist.FullName "x64\Microsoft.VC143.CRT"
                if (-not (Test-Path $CrtFolder)) {
                    $CrtFolder = Join-Path $LatestRedist.FullName "x64\Microsoft.VC142.CRT"
                }

                if (Test-Path $CrtFolder) {
                    Write-Host "  Found MSVC Redistributable CRT at: $CrtFolder" -ForegroundColor Green
                    foreach ($dll in $MissingDlls) {
                        $source = Join-Path $CrtFolder $dll
                        if (Test-Path $source) {
                            Copy-Item -Path $source -Destination $ReleaseDir -Force
                            Write-Host "  Copied $dll into Release bundle." -ForegroundColor Green
                        }
                    }
                }
            }
        }
    }
} else {
    Write-Host "  All required MSVC C++ runtime DLLs are present in the Release directory." -ForegroundColor Green
}

# Fallback: check Windows System32 if any DLL is still missing
foreach ($dll in $RequiredDlls) {
    $dllPath = Join-Path $ReleaseDir $dll
    if (-not (Test-Path $dllPath)) {
        $sys32Path = "C:\Windows\System32\$dll"
        if (Test-Path $sys32Path) {
            Copy-Item -Path $sys32Path -Destination $ReleaseDir -Force
            Write-Host "  Copied $dll from System32 into Release bundle." -ForegroundColor Cyan
        } else {
            Write-Warning "Could not find $dll. The client might need Visual C++ Redistributable if this is missing."
        }
    }
}

# 4. Create Desktop / Taskbar Shortcut Helper in the portable folder
Write-Host "`n[3/5] Adding desktop shortcut creator helper..." -ForegroundColor Yellow
$ShortcutScript = @"
@echo off
setlocal
cd /d "%~dp0"
set TARGET=%~dp0pos_app.exe
set SHORTCUT=%USERPROFILE%\Desktop\Caskly POS.lnk

echo Creating Desktop Shortcut for Caskly POS...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%TARGET%'; $s.WorkingDirectory = '%~dp0'; $s.Save()"

echo Done! Shortcut created on your Desktop.
echo Tip: Double-click the shortcut to run, then right-click its taskbar icon and click 'Pin to taskbar'.
pause
"@

$ShortcutScriptPath = Join-Path $ReleaseDir "Create_Desktop_Shortcut.bat"
Set-Content -Path $ShortcutScriptPath -Value $ShortcutScript -Encoding ASCII

# 5. Create Portable ZIP
Write-Host "`n[4/5] Compressing portable ZIP archive..." -ForegroundColor Yellow
$DistDir = "build\dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

$ZipFileName = "Caskly_POS_v${Version}_Windows_Portable.zip"
$ZipFilePath = Join-Path $DistDir $ZipFileName

if (Test-Path $ZipFilePath) {
    Remove-Item $ZipFilePath -Force
}

Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $ZipFilePath -CompressionLevel Optimal
Write-Host "  Successfully created portable ZIP: $ZipFilePath" -ForegroundColor Green

# 6. Optional: Compile Inno Setup installer if iscc.exe is available
Write-Host "`n[5/5] Checking for Inno Setup (ISCC.exe)..." -ForegroundColor Yellow
$IsccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)
$Iscc = $null
foreach ($path in $IsccPaths) {
    if (Test-Path $path) {
        $Iscc = $path
        break
    }
}

if (-not $Iscc) {
    $cmd = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($cmd) { $Iscc = $cmd.Source }
}

if ($Iscc -and (Test-Path "installer_script.iss")) {
    Write-Host "  Inno Setup detected at: $Iscc" -ForegroundColor Green
    Write-Host "  Compiling installer..." -ForegroundColor Cyan
    & $Iscc "installer_script.iss"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Installer generated at: build\windows\installer\" -ForegroundColor Green
    }
} else {
    Write-Host "  Inno Setup not installed or skipped. (Optional - portable ZIP is ready)." -ForegroundColor DarkGray
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "  SUCCESS! Windows Portable Build Ready:         " -ForegroundColor Green
Write-Host "  $ZipFilePath" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Client instructions:" -ForegroundColor Yellow
Write-Host "1. Send the client '$ZipFileName'."
Write-Host "2. Client extracts the ZIP anywhere on their PC."
Write-Host "3. Double-click 'pos_app.exe' (or 'Create_Desktop_Shortcut.bat')."
Write-Host "4. Right-click the app icon in the taskbar and select 'Pin to taskbar'."
Write-Host "No Visual Studio or C++ install needed!" -ForegroundColor Green
