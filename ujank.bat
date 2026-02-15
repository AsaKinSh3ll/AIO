@echo off
setlocal EnableExtensions EnableDelayedExpansion
title AIO: Firefox Auto Setup + 7-Zip + (Toggle) Mega Public Downloader
color 0A

:: ================================
:: TOGGLE MEGA (1=ON, 0=OFF)
:: ================================
set "ENABLE_MEGA=0"

:: ================================
:: CHECK ADMIN
:: ================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [!] Jalankan sebagai Administrator (Run as administrator).
  pause
  exit /b 1
)

:: ================================
:: PATHS
:: ================================
set "DESKTOP=%USERPROFILE%\Desktop"
set "WORK=%~dp0_work"
set "TOOLS=%WORK%\tools"
set "DL=%WORK%\downloads"

if not exist "%WORK%"  mkdir "%WORK%"
if not exist "%TOOLS%" mkdir "%TOOLS%"
if not exist "%DL%"    mkdir "%DL%"

:: Hasil Mega di Desktop
set "MEGA_OUT=%DESKTOP%\MegaDownloads"
set "EXTRACT_DIR=%MEGA_OUT%\extracted"
if not exist "%MEGA_OUT%" mkdir "%MEGA_OUT%"

echo.
echo ================================
echo  Mega: %ENABLE_MEGA%
echo  Output: %MEGA_OUT%
echo ================================
echo.

:: ================================
:: [1] FIREFOX: DOWNLOAD + SILENT INSTALL + VERIFY
:: ================================
echo [1/4] Download Firefox...
set "FF_EXE=%DL%\firefox_installer.exe"
curl -L --fail -o "%FF_EXE%" "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
if %errorlevel% neq 0 (
  echo [!] Gagal download Firefox.
  pause
  exit /b 1
)

echo [1/4] Install Firefox (auto setup / silent)...
start /wait "" "%FF_EXE%" /S

:: Verifikasi instalasi Firefox
set "FIREFOX_BIN="
if exist "C:\Program Files\Mozilla Firefox\firefox.exe" set "FIREFOX_BIN=C:\Program Files\Mozilla Firefox\firefox.exe"
if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" set "FIREFOX_BIN=C:\Program Files (x86)\Mozilla Firefox\firefox.exe"

if "%FIREFOX_BIN%"=="" (
  echo [!] Firefox tidak terdeteksi terinstall.
  echo     Cek policy/antivirus/installer.
  pause
  exit /b 1
) else (
  echo     OK: Firefox terinstall -> "%FIREFOX_BIN%"
)

:: ================================
:: [2] 7-ZIP: DOWNLOAD OFFICIAL + SILENT INSTALL
:: ================================
echo.
echo [2/4] Download 7-Zip (official 7-zip.org)...
set "SZ_PAGE=%DL%\7zip_download.html"
curl -L --fail -o "%SZ_PAGE%" "https://7-zip.org/download.html"
if %errorlevel% neq 0 (
  echo [!] Gagal akses halaman 7-Zip.
  pause
  exit /b 1
)

for /f "usebackq delims=" %%U in (`powershell -NoProfile -ExecutionPolicy Bypass ^
  "$h=Get-Content -Raw '%SZ_PAGE%';" ^
  "$m=[regex]::Match($h,'href=""(?<u>[^""]+7z[^""]+-x64\.msi)""',[Text.RegularExpressions.RegexOptions]::IgnoreCase);" ^
  "if($m.Success){$m.Groups['u'].Value}"`) do set "SZ_REL=%%U"

if "%SZ_REL%"=="" (
  echo [!] Tidak menemukan link MSI x64 di halaman 7-Zip.
  pause
  exit /b 1
)

set "SZ_URL=https://7-zip.org/%SZ_REL%"
set "SZ_MSI=%DL%\7zip-x64.msi"

echo [2/4] Download: %SZ_URL%
curl -L --fail -o "%SZ_MSI%" "%SZ_URL%"
if %errorlevel% neq 0 (
  echo [!] Gagal download 7-Zip MSI.
  pause
  exit /b 1
)

echo [2/4] Install 7-Zip (silent)...
start /wait "" msiexec /i "%SZ_MSI%" /qn /norestart

set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
if not exist "%SEVENZIP%" set "SEVENZIP=C:\Program Files (x86)\7-Zip\7z.exe"
if not exist "%SEVENZIP%" (
  echo [!] 7z.exe tidak ditemukan setelah install 7-Zip.
  pause
  exit /b 1
)

:: ================================
:: [3] MEGA (OPTIONAL): DOWNLOAD megadl.exe
:: ================================
if "%ENABLE_MEGA%"=="0" (
  echo.
  echo [3/4] Mega OFF -> skip download dari Mega.
  goto :SKIP_MEGA
)

echo.
echo [3/4] Mega ON -> Siapkan megadl.exe (Megatools)...
set "MEGATOOLS_ZIP=%DL%\megatools-win64.zip"
set "MEGATOOLS_DIR=%TOOLS%\megatools"

curl -L --fail -o "%MEGATOOLS_ZIP%" "https://xff.cz/megatools/builds/builds/megatools-1.11.3.20250401-win64.zip"
if %errorlevel% neq 0 (
  echo [!] Gagal download Megatools zip.
  pause
  exit /b 1
)

if exist "%MEGATOOLS_DIR%" rmdir /s /q "%MEGATOOLS_DIR%"
mkdir "%MEGATOOLS_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -Force '%MEGATOOLS_ZIP%' '%MEGATOOLS_DIR%'" >nul
if %errorlevel% neq 0 (
  echo [!] Gagal extract Megatools.
  pause
  exit /b 1
)

set "MEGADL="
for /r "%MEGATOOLS_DIR%" %%I in (megadl.exe) do (
  set "MEGADL=%%I"
  goto :FOUND_MEGADL
)
:FOUND_MEGADL

if "%MEGADL%"=="" (
  echo [!] megadl.exe tidak ditemukan.
  pause
  exit /b 1
)

echo     OK: %MEGADL%

:: ================================
:: DOWNLOAD MEGA PUBLIC LINKS -> DESKTOP
:: ================================
echo.
echo     Download tools dari Mega -> %MEGA_OUT%

:: ---- DAFTAR LINK MEGA (EDIT INI) ----
set "MEGA_LINKS[1]=https://mega.nz/file/XXXXXXXX#YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"
set "MEGA_LINKS[2]=https://mega.nz/file/AAAAAAAA#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
:: ------------------------------------

set /a i=1
:MEGA_LOOP
call set "L=%%MEGA_LINKS[%i%]%%"
if "%L%"=="" goto :MEGA_DONE

echo --- (%i%) %L%
"%MEGADL%" --path "%MEGA_OUT%" "%L%"
if %errorlevel% neq 0 (
  echo [!] Gagal download index %i% (Mega kadang membatasi client pihak-ketiga).
)
set /a i+=1
goto :MEGA_LOOP
:MEGA_DONE

:: ================================
:: [4] AUTO EXTRACT + AUTO INSTALL (dari hasil Mega)
:: ================================
echo.
echo [4/4] Extract & install hasil download Mega...
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

for %%F in ("%MEGA_OUT%\*.zip" "%MEGA_OUT%\*.7z" "%MEGA_OUT%\*.rar") do (
  if exist "%%~fF" (
    echo Extract: %%~nxF
    "%SEVENZIP%" x "%%~fF" -o"%EXTRACT_DIR%\%%~nF" -y >nul
  )
)

for %%F in ("%MEGA_OUT%\*.msi") do (
  if exist "%%~fF" (
    echo Install MSI: %%~nxF
    start /wait "" msiexec /i "%%~fF" /qn /norestart
  )
)

for %%F in ("%MEGA_OUT%\*.exe") do (
  if exist "%%~fF" (
    echo Install EXE: %%~nxF
    start /wait "" "%%~fF" /S
    if !errorlevel! neq 0 start /wait "" "%%~fF" /silent
    if !errorlevel! neq 0 start /wait "" "%%~fF" /verysilent
  )
)

:SKIP_MEGA

echo.
echo ================================
echo  SELESAI
echo  - Firefox: %FIREFOX_BIN%
if "%ENABLE_MEGA%"=="1" (
  echo  - Mega:   %MEGA_OUT%
  echo  - Extract:%EXTRACT_DIR%
) else (
  echo  - Mega:   OFF
)
echo ================================
pause
exit /b 0
