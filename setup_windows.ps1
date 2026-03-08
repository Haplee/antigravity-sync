# setup_windows.ps1
# Codificación: UTF-8

Write-Host "Iniciando configuración de antigravity-sync en Windows..." -ForegroundColor Cyan

# 1. Verificar Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git no está instalado. Instalando..." -ForegroundColor Yellow
    winget install Git.Git --silent
    Write-Host "Git instalado. Por favor, reinicia PowerShell y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}

# 2. Verificar Antigravity
if (-not (Get-Command antigravity -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Antigravity no está instalado o no está en el PATH." -ForegroundColor Red
    exit 1
}

# 3. Pedir URL del repo y guardar en .env
$envFile = "$PSScriptRoot\.env"
$repoUrl = Read-Host "Introduce la URL del repositorio GitHub (ej. https://github.com/usuario/antigravity-sync)"
if ([string]::IsNullOrWhiteSpace($repoUrl)) {
    Write-Host "URL no válida." -ForegroundColor Red
    exit 1
}
Set-Content -Path $envFile -Value "REPO_URL=$repoUrl" -Encoding UTF8

# 4. Configurar Git user/email si no existen
$gitName = git config --global user.name
if (-not $gitName) {
    $newName = Read-Host "Introduce tu nombre para Git"
    git config --global user.name $newName
}

$gitEmail = git config --global user.email
if (-not $gitEmail) {
    $newEmail = Read-Host "Introduce tu email para Git"
    git config --global user.email $newEmail
}

# 5. Clonar el repositorio si no existe
$targetDir = "$env:USERPROFILE\antigravity-sync"
if (-not (Test-Path $targetDir)) {
    Write-Host "Clonando repositorio en $targetDir..." -ForegroundColor Cyan
    git clone $repoUrl $targetDir
} else {
    Write-Host "El directorio $targetDir ya existe. Omitiendo clonación." -ForegroundColor Yellow
}

# 6. Crear tarea programada
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetDir\sync_windows.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$taskName = "AntigravitySync"
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
Write-Host "Tarea programada '$taskName' creada para ejecutarse al iniciar sesión." -ForegroundColor Green

Write-Host "Configuración completada con éxito. Ya puedes usar antigravity-sync." -ForegroundColor Green
