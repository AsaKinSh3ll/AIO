# ========================================
# RDP Auto Setup Script
# All-in-One Setup Tool
# ========================================

# Requires Admin Rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Script harus dijalankan sebagai Administrator!"
    Write-Host "Klik kanan PowerShell dan pilih 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   RDP AUTO SETUP SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Fungsi untuk download file
function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    try {
        Write-Host "[+] Downloading: $output" -ForegroundColor Green
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $output)
        Write-Host "[✓] Download selesai!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[✗] Download gagal: $_" -ForegroundColor Red
        return $false
    }
}

# Fungsi untuk install aplikasi
function Install-App {
    param (
        [string]$installerPath,
        [string]$arguments = "/S"
    )
    try {
        Write-Host "[+] Installing: $installerPath" -ForegroundColor Green
        Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait
        Write-Host "[✓] Instalasi selesai!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[✗] Instalasi gagal: $_" -ForegroundColor Red
        return $false
    }
}

# ========================================
# 1. INSTALL FIREFOX
# ========================================
Write-Host ""
Write-Host "1. Install Firefox?" -ForegroundColor Yellow
$installFirefox = Read-Host "   (Y/N)"

if ($installFirefox -eq 'Y' -or $installFirefox -eq 'y') {
    Write-Host ""
    Write-Host "[*] Memulai instalasi Firefox..." -ForegroundColor Cyan
    
    $firefoxUrl = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
    $firefoxInstaller = "$env:TEMP\FirefoxInstaller.exe"
    
    if (Download-File -url $firefoxUrl -output $firefoxInstaller) {
        # Silent install Firefox
        Install-App -installerPath $firefoxInstaller -arguments "/S /MaintenanceService=false"
        Remove-Item $firefoxInstaller -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host "[SKIP] Firefox installation" -ForegroundColor Gray
}

# ========================================
# 2. DOWNLOAD FROM MEGA.NZ
# ========================================
Write-Host ""
Write-Host "2. Download file dari Mega.nz?" -ForegroundColor Yellow
$downloadMega = Read-Host "   (Y/N)"

if ($downloadMega -eq 'Y' -or $downloadMega -eq 'y') {
    Write-Host ""
    $megaUrl = Read-Host "   Masukkan URL Mega.nz"
    
    if ($megaUrl) {
        Write-Host "[*] Memulai download dari Mega.nz..." -ForegroundColor Cyan
        
        # Install MegaCMD jika belum ada
        $megacmdPath = "$env:LOCALAPPDATA\MEGAcmd\mega-get.exe"
        
        if (-not (Test-Path $megacmdPath)) {
            Write-Host "[+] Installing MegaCMD..." -ForegroundColor Green
            $megacmdUrl = "https://mega.nz/MEGAcmdSetup64.exe"
            $megacmdInstaller = "$env:TEMP\MEGAcmdSetup.exe"
            
            if (Download-File -url $megacmdUrl -output $megacmdInstaller) {
                Install-App -installerPath $megacmdInstaller -arguments "/S"
                Start-Sleep -Seconds 5
                Remove-Item $megacmdInstaller -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Download file dari Mega
        $downloadPath = "$env:USERPROFILE\Downloads"
        Write-Host "[+] Download ke: $downloadPath" -ForegroundColor Green
        
        try {
            # Menggunakan mega-get untuk download
            if (Test-Path $megacmdPath) {
                & $megacmdPath $megaUrl $downloadPath
                Write-Host "[✓] Download dari Mega selesai!" -ForegroundColor Green
            }
            else {
                Write-Host "[!] MegaCMD tidak ditemukan. Buka URL di browser:" -ForegroundColor Yellow
                Write-Host "    $megaUrl" -ForegroundColor White
                Start-Process $megaUrl
            }
        }
        catch {
            Write-Host "[!] Error downloading. Opening in browser..." -ForegroundColor Yellow
            Start-Process $megaUrl
        }
    }
}
else {
    Write-Host "[SKIP] Mega.nz download" -ForegroundColor Gray
}

# ========================================
# 3. INSTALL 7-ZIP
# ========================================
Write-Host ""
Write-Host "3. Install 7-Zip?" -ForegroundColor Yellow
$install7zip = Read-Host "   (Y/N)"

if ($install7zip -eq 'Y' -or $install7zip -eq 'y') {
    Write-Host ""
    Write-Host "[*] Memulai instalasi 7-Zip..." -ForegroundColor Cyan
    
    # Detect system architecture
    if ([Environment]::Is64BitOperatingSystem) {
        $7zipUrl = "https://www.7-zip.org/a/7z2408-x64.exe"
    }
    else {
        $7zipUrl = "https://www.7-zip.org/a/7z2408.exe"
    }
    
    $7zipInstaller = "$env:TEMP\7zInstaller.exe"
    
    if (Download-File -url $7zipUrl -output $7zipInstaller) {
        Install-App -installerPath $7zipInstaller -arguments "/S"
        Remove-Item $7zipInstaller -Force -ErrorAction SilentlyContinue
        
        # Add 7-Zip to PATH
        $7zipPath = "C:\Program Files\7-Zip"
        if (Test-Path $7zipPath) {
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$7zipPath*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$7zipPath", "Machine")
                Write-Host "[✓] 7-Zip ditambahkan ke PATH" -ForegroundColor Green
            }
        }
    }
}
else {
    Write-Host "[SKIP] 7-Zip installation" -ForegroundColor Gray
}

# ========================================
# SETUP SELESAI
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   SETUP SELESAI!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Aplikasi yang terinstall:" -ForegroundColor Cyan

if ($installFirefox -eq 'Y' -or $installFirefox -eq 'y') {
    Write-Host "  [✓] Firefox" -ForegroundColor Green
}
if ($install7zip -eq 'Y' -or $install7zip -eq 'y') {
    Write-Host "  [✓] 7-Zip" -ForegroundColor Green
}

Write-Host ""
Write-Host "Tekan tombol apapun untuk keluar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
