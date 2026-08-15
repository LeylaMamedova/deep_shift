param(
  [string]$Domain,
  [string]$Email
)

$ErrorActionPreference = "Stop"
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "Run this in an Administrator PowerShell so Caddy can bind ports 80 and 443."
}
$root = Split-Path -Parent $PSScriptRoot
$deploy = Join-Path $root "deploy"
$configPath = Join-Path $deploy "config.env"

if (-not $Domain -or -not $Email) {
  if (Test-Path $configPath) {
    Get-Content $configPath | ForEach-Object {
      if ($_ -match "^\s*DOMAIN=(.+)$") { if (-not $Domain) { $Domain = $Matches[1].Trim() } }
      if ($_ -match "^\s*EMAIL=(.+)$") { if (-not $Email) { $Email = $Matches[1].Trim() } }
    }
  }
}

if (-not $Domain -or $Domain -like "*yourdomain*") {
  throw "Set DOMAIN first. Example:`n  .\deploy\windows-caddy.ps1 -Domain game.yourdomain.com -Email you@yourdomain.com"
}
if (-not $Email -or $Email -like "*yourdomain*") {
  throw "Set EMAIL (needed for Let's Encrypt HTTPS)."
}

$siteRoot = ((Join-Path $root "public") -replace "\\", "/")
$caddyDir = Join-Path $env:LOCALAPPDATA "wirebound-caddy"
New-Item -ItemType Directory -Force -Path $caddyDir | Out-Null

@"
DOMAIN=$Domain
EMAIL=$Email
SITE_ROOT=$siteRoot
"@ | Set-Content -Encoding ascii (Join-Path $deploy "config.env")

$env:DOMAIN = $Domain
$env:EMAIL = $Email
$env:SITE_ROOT = $siteRoot

$caddyExe = Join-Path $caddyDir "caddy.exe"
if (-not (Test-Path $caddyExe)) {
  Write-Host "Downloading Caddy..."
  $zip = Join-Path $caddyDir "caddy.zip"
  Invoke-WebRequest -Uri "https://github.com/caddyserver/caddy/releases/latest/download/caddy_windows_amd64.zip" -OutFile $zip
  Expand-Archive -Path $zip -DestinationPath $caddyDir -Force
}

Write-Host ""
Write-Host "DNS: create an A record"
Write-Host "  $Domain  ->  YOUR PUBLIC IP"
Write-Host "Router: forward WAN ports 80 and 443 to this PC, TCP."
Write-Host "Then Caddy will get a free HTTPS certificate automatically."
Write-Host ""
Write-Host "Starting Caddy for https://$Domain ..."
Write-Host "Keep this window open, or install Caddy as a Windows service later."
Write-Host ""

& $caddyExe run --config (Join-Path $deploy "Caddyfile") --adapter caddyfile
