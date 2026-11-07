# Prepara o projeto no Windows: gera as pastas android/ios e baixa as dependências.
# Uso (na raiz do repositório):  powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Run-In($dir, [scriptblock]$block) {
  Write-Host "==> $dir" -ForegroundColor Green
  Push-Location (Join-Path $root $dir)
  try { & $block } finally { Pop-Location }
}

Run-In 'packages\design_system' { flutter pub get }
Run-In 'packages\core' { flutter pub get }
Run-In 'packages\design_system\example' {
  flutter create . --platforms=android,ios --project-name ace_design_system_example
  flutter pub get
}
Run-In 'apps\mobile' {
  flutter create . --platforms=android,ios --project-name ace_control_app
  flutter pub get
}

# O MockServer usa HTTP (sem TLS): libera tráfego "cleartext" no Android.
$manifest = Join-Path $root 'apps\mobile\android\app\src\main\AndroidManifest.xml'
if (Test-Path $manifest) {
  $xml = Get-Content $manifest -Raw
  if ($xml -notmatch 'usesCleartextTraffic') {
    $xml = $xml -replace '<application', '<application android:usesCleartextTraffic="true"'
    Set-Content -Path $manifest -Value $xml -NoNewline
    Write-Host 'AndroidManifest: usesCleartextTraffic habilitado.' -ForegroundColor Yellow
  }
}
Write-Host 'Pronto. Suba o servidor (scripts\run_server.ps1) e rode: cd apps\mobile; flutter run' -ForegroundColor Green
