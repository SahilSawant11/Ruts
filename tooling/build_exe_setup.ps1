# Automated build script for Caskly POS Windows EXE Setup
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building Flutter Windows Release App... " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter Windows build failed!" -ForegroundColor Red
    exit 1
}

# Locate Inno Setup Compiler (ISCC.exe)
$isccPath = ""

# Check Registry for Inno Setup installation path
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*Inno Setup*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*Inno Setup*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*Inno Setup*"
)
foreach ($regPath in $regPaths) {
    $foundReg = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty InstallLocation -ErrorAction SilentlyContinue
    if ($foundReg -and (Test-Path (Join-Path $foundReg "ISCC.exe"))) {
        $isccPath = Join-Path $foundReg "ISCC.exe"
        break
    }
}

if (-not $isccPath) {
    $commonPaths = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 5\ISCC.exe",
        "C:\Program Files\Inno Setup 5\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            $isccPath = $p
            break
        }
    }
}

if (-not $isccPath) {
    $cmd = Get-Command iscc -ErrorAction SilentlyContinue
    if ($cmd) { $isccPath = $cmd.Source }
}

if (-not $isccPath) {
    Write-Host "Error: Inno Setup Compiler (ISCC.exe) not found!" -ForegroundColor Red
    Write-Host "Please restart your terminal or verify Inno Setup installation." -ForegroundColor Yellow
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Compiling Inno Setup EXE Installer...    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

& "$isccPath" "installer_script.iss"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host " SUCCESS! Standalone Setup EXE created:  " -ForegroundColor Green
    Write-Host " build\windows\installer\Caskly_POS_Setup_v0.1.0.exe" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "This single EXE file can be installed on ANY Windows PC without any third-party app!" -ForegroundColor Cyan
    explorer.exe "build\windows\installer"
} else {
    Write-Host "Error compiling installer script!" -ForegroundColor Red
}
