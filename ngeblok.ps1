# Cek apakah sudah dijalankan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Restarting as Administrator..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$entry = "127.0.0.1 api.telegram.org"

# Cek apakah entri sudah ada
if (Select-String -Path $hostsPath -Pattern "^\s*127\.0\.0\.1\s+api\.telegram\.org" -Quiet) {
    Write-Host "Entry already exists in hosts file."
} else {
    Add-Content -Path $hostsPath -Value "`r`n$entry"
    Write-Host "Entry successfully added to hosts file."
}
