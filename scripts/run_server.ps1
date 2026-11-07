# Sobe o MockServer em http://localhost:8000 (docs: /docs).
# Uso:  powershell -ExecutionPolicy Bypass -File scripts\run_server.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path (Split-Path -Parent $PSScriptRoot) 'server')
if (-not (Test-Path '.venv')) { python -m venv .venv }
.\.venv\Scripts\python.exe -m pip install -q -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
