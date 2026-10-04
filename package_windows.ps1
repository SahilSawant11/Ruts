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
    Write-Host "`n[1/6] Building Flutter Windows Release..." -ForegroundColor Yellow
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter release build failed. Please resolve build errors and retry."
    }
} else {
    Write-Host "`n[1/6] Skipping Flutter build as requested (-SkipBuild)." -ForegroundColor Yellow
}

$ReleaseDir = "build\windows\x64\runner\Release"
if (-not (Test-Path $ReleaseDir)) {
    # Fallback check for non-x64 path
    if (Test-Path "build\windows\runner\Release") {
        $ReleaseDir = "build\windows\runner\Release"
    } else {
        Write-Error "Release directory '$ReleaseDir' not found. Build may have failed."
    }
}

$DataDir = Join-Path $ReleaseDir "data"
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# 3. Verify and safeguard Flutter core files & AOT snapshot (app.so)
Write-Host "`n[2/6] Verifying Flutter engine, assets, and AOT data (app.so)..." -ForegroundColor Yellow

$TargetAppSo = Join-Path $DataDir "app.so"
if (-not (Test-Path $TargetAppSo)) {
    Write-Host "  app.so not in Release\data. Searching build outputs..." -ForegroundColor Yellow
    $PossibleAppSo = @(
        "build\windows\x64\app.so",
        "build\windows\app.so",
        "build\windows\x64\extracted\app.so",
        "build\app.so"
    )
    $FoundSo = $null
    foreach ($path in $PossibleAppSo) {
        if (Test-Path $path) {
            $FoundSo = $path
            break
        }
    }

    if (-not $FoundSo) {
        $FoundSo = Get-ChildItem -Path "build" -Filter "app.so" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }

    if ($FoundSo) {
        Copy-Item -Path $FoundSo -Destination $TargetAppSo -Force
        Write-Host "  Copied AOT snapshot from $FoundSo to $TargetAppSo" -ForegroundColor Green
    } else {
        Write-Error "CRITICAL: app.so (AOT compiled Flutter snapshot) was not found in the build folder! Flutter Windows engine cannot launch without app.so."
    }
} else {
    Write-Host "  app.so verified in $TargetAppSo" -ForegroundColor Green
}

# Verify other essential Flutter files
$Icudtl = Join-Path $DataDir "icudtl.dat"
if (-not (Test-Path $Icudtl)) {
    $foundIcu = Get-ChildItem -Path "windows" -Filter "icudtl.dat" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($foundIcu) {
        Copy-Item -Path $foundIcu -Destination $Icudtl -Force
    }
}

# 4. Verify and bundle Microsoft Visual C++ Runtime DLLs (vcruntime140, msvcp140, etc.)
Write-Host "`n[3/6] Checking and bundling MSVC C++ Runtime DLLs (vcruntime140.dll, msvcp140.dll)..." -ForegroundColor Yellow

$RequiredDlls = @(
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "msvcp140_codecvt_ids.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "vcomp140.dll"
)

$MissingDlls = @()
foreach ($dll in $RequiredDlls) {
    $dllPath = Join-Path $ReleaseDir $dll
    if (-not (Test-Path $dllPath)) {
        $MissingDlls += $dll
    }
}

if ($MissingDlls.Count -gt 0) {
    Write-Host "  Locating Visual Studio Redistributable folder..." -ForegroundColor Cyan

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
            "C:\Program Files\Microsoft Visual Studio\2022\Enterprise",
            "C:\Program Files\Microsoft Visual Studio\2022\Community",
            "C:\Program Files\Microsoft Visual Studio\2022\Professional",
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
}

# Fallback: check Windows System32 if any critical DLL is still missing
$CriticalDlls = @("msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll")
foreach ($dll in $CriticalDlls) {
    $dllPath = Join-Path $ReleaseDir $dll
    if (-not (Test-Path $dllPath)) {
        $sys32Path = "C:\Windows\System32\$dll"
        if (Test-Path $sys32Path) {
            Copy-Item -Path $sys32Path -Destination $ReleaseDir -Force
            Write-Host "  Copied $dll from System32 into Release bundle." -ForegroundColor Cyan
        }
    }
}

# 5. Verify and bundle sqlite3.dll for Drift / SQLite database
Write-Host "`n[4/7] Checking and bundling sqlite3.dll..." -ForegroundColor Yellow
$SqliteDllPath = Join-Path $ReleaseDir "sqlite3.dll"
if (-not (Test-Path $SqliteDllPath)) {
    $PossibleSqlite = @(
        "windows\sqlite3.dll",
        "windows\runner\resources\sqlite3.dll"
    )
    $foundSqlite = $null
    foreach ($p in $PossibleSqlite) {
        if (Test-Path $p) {
            $foundSqlite = $p
            break
        }
    }
    if (-not $foundSqlite) {
        $foundSqlite = Get-ChildItem -Path "windows", "build", ".dart_tool" -Filter "sqlite3.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    }
    if ($foundSqlite) {
        Copy-Item -Path $foundSqlite -Destination $SqliteDllPath -Force
        Write-Host "  Copied sqlite3.dll from $foundSqlite to $SqliteDllPath" -ForegroundColor Green
    } else {
        Write-Host "  sqlite3.dll not found locally. Downloading official SQLite x64 DLL..." -ForegroundColor Cyan
        try {
            $SqliteZipUrl = "https://www.sqlite.org/2024/sqlite-dll-win-x64-3460100.zip"
            $TempZip = Join-Path $env:TEMP "sqlite_x64.zip"
            $TempExtract = Join-Path $env:TEMP "sqlite_x64_extracted"
            Invoke-WebRequest -Uri $SqliteZipUrl -OutFile $TempZip -UseBasicParsing
            Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
            $DownloadedDll = Join-Path $TempExtract "sqlite3.dll"
            if (Test-Path $DownloadedDll) {
                Copy-Item -Path $DownloadedDll -Destination $SqliteDllPath -Force
                Write-Host "  Successfully downloaded and bundled sqlite3.dll" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Failed to download sqlite3.dll: $_"
        }
    }
} else {
    Write-Host "  sqlite3.dll verified in $SqliteDllPath" -ForegroundColor Green
}

# 6. Create Desktop / Taskbar Shortcut Helper in the portable folder
Write-Host "`n[5/7] Adding desktop shortcut creator helper..." -ForegroundColor Yellow
$ShortcutScript = @"
@echo off
setlocal
cd /d "%~dp0"
set TARGET=%~dp0pos_app.exe
set SHORTCUT=%USERPROFILE%\Desktop\Caskly POS.lnk

echo Creating Desktop Shortcut for Caskly POS...
powershell -NoProfile -Command "`$ws = New-Object -ComObject WScript.Shell; `$s = `$ws.CreateShortcut('%SHORTCUT%'); `$s.TargetPath = '%TARGET%'; `$s.WorkingDirectory = '%~dp0'; `$s.Save()"

echo Done! Shortcut created on your Desktop.
echo Tip: Double-click the shortcut to run, then right-click its taskbar icon and click 'Pin to taskbar'.
pause
"@

$ShortcutScriptPath = Join-Path $ReleaseDir "Create_Desktop_Shortcut.bat"
Set-Content -Path $ShortcutScriptPath -Value $ShortcutScript -Encoding ASCII

# 6. Create Portable ZIP (Ensuring all subfolders like data/ and assets are preserved)
Write-Host "`n[5/6] Compressing portable ZIP archive..." -ForegroundColor Yellow
$DistDir = "build\dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

$ZipFileName = "Caskly_POS_v${Version}_Windows_Portable.zip"
$ZipFilePath = Join-Path (Get-Item $DistDir).FullName $ZipFileName

if (Test-Path $ZipFilePath) {
    Remove-Item $ZipFilePath -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory((Get-Item $ReleaseDir).FullName, $ZipFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
Write-Host "  Successfully created portable ZIP: $ZipFilePath" -ForegroundColor Green

# 7. Optional: Compile Inno Setup installer if iscc.exe is available
Write-Host "`n[6/6] Checking for Inno Setup (ISCC.exe)..." -ForegroundColor Yellow
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
    Write-Host "  Compiling single-file Setup Installer (.exe)..." -ForegroundColor Cyan
    & $Iscc "installer_script.iss"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Installer generated at: build\windows\installer\" -ForegroundColor Green
    }
} else {
    Write-Host "  Inno Setup not installed or skipped. (Portable ZIP is ready)." -ForegroundColor DarkGray
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "  SUCCESS! Windows Build & Package Complete:      " -ForegroundColor Green
Write-Host "  Portable ZIP: $ZipFilePath" -ForegroundColor White
if (Test-Path "build\windows\installer\Caskly_POS_Setup_v${Version}.exe") {
    Write-Host "  Setup Wizard: build\windows\installer\Caskly_POS_Setup_v${Version}.exe" -ForegroundColor White
}
Write-Host "==================================================" -ForegroundColor Green
