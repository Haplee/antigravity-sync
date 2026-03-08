# sync_windows.ps1
# Codificación: UTF-8

$logFile = "$PSScriptRoot\sync.log"

# Función de log con rotación (máx 1MB)
function Write-Log {
    param([string]$Message)
    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "[$dateStr] $Message"
    
    if (Test-Path $logFile) {
        $fileSize = (Get-Item $logFile).Length
        if ($fileSize -gt 1MB) {
            Move-Item -Path $logFile -Destination "$logFile.old" -Force
        }
    }
    Add-Content -Path $logFile -Value $fullMessage -Encoding UTF8
}

Write-Log "Iniciando sincronización en Windows"

# 1. Leer URL
$envFile = "$PSScriptRoot\.env"
if (-not (Test-Path $envFile)) {
    $msg = "Error: Archivo .env no encontrado. Ejecuta setup_windows.ps1 primero."
    Write-Host $msg -ForegroundColor Red
    Write-Log $msg
    exit 1
}

# 2. Verificar dependencias
if (-not (Get-Command antigravity -ErrorAction SilentlyContinue)) {
    $msg = "Error: Antigravity no está instalado."
    Write-Host $msg -ForegroundColor Red
    Write-Log $msg
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $msg = "Error: Git no está instalado."
    Write-Host $msg -ForegroundColor Red
    Write-Log $msg
    exit 1
}

# Entrar al directorio
Set-Location $PSScriptRoot

# 3. Pull con manejo de conflictos
Write-Log "Obteniendo cambios remotos..."
$pullOutput = git pull 2>&1
if ($LASTEXITCODE -ne 0 -and $pullOutput -match "conflict") {
    Write-Log "Conflicto en pull. Resolviendo a favor de versión remota."
    Write-Host "Conflicto detectado en extensiones.txt. Manteniendo versión del servidor..." -ForegroundColor Yellow
    git checkout --theirs extensiones.txt
    git add extensiones.txt
    git commit -m "Merge: resolución de conflicto a favor de repositorio remoto"
}

# 4. Exportar extensiones (filtrando el warning known)
$extFile = "extensiones.txt"
antigravity --list-extensions 2>&1 | Select-String -NotMatch "createInstance" | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" } | Out-File $extFile -Encoding UTF8

# 5. Verificar que no esté vacío
$extCount = 0
if (Test-Path $extFile) {
    # Evitar conteo de líneas vacías adicionales
    $extCount = @(Get-Content $extFile | Where-Object { $_.Trim() -ne "" }).Count
}

if ($extCount -eq 0) {
    $msg = "Error: El archivo exportado está vacío. Abortando sincronización."
    Write-Host $msg -ForegroundColor Red
    Write-Log $msg
    exit 1
}

# 6. Comprobar si hay cambios en git
$status = git status --porcelain
if (-not $status) {
    $msg = "Sin cambios, sincronización omitida."
    Write-Host $msg -ForegroundColor Yellow
    Write-Log $msg
    exit 0
}

# 7. Add, commit y push
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git add $extFile
git commit -m "Sincronización Windows: $dateStr ($extCount extensiones)" | Out-Null
$pushOutput = git push 2>&1

if ($LASTEXITCODE -ne 0) {
    $msg = "Error en git push. Comprueba tus credenciales de GitHub (Personal Access Token)."
    Write-Host $msg -ForegroundColor Red
    Write-Log "Error de credenciales en push: $pushOutput"
    exit 1
}

# 8. Log resumen
$msg = "Sincronización finalizada con éxito. Exportadas $extCount extensiones."
Write-Log $msg
Write-Host $msg -ForegroundColor Green
Write-Host "Hora: $dateStr" -ForegroundColor Cyan
