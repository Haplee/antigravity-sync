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

# 4. Comprobar el fichero del repo e instalar lo que falte (sincronización bidireccional)
$extFile = "extensiones.txt"
$countInstalled = 0
$countSkipped = 0
$countFailed = 0

$repoExtCount = 0
if (Test-Path $extFile) {
    $repoExtCount = @(Get-Content $extFile | Where-Object { $_.Trim() -ne "" }).Count
}

if ($repoExtCount -eq 0) {
    # Primer arranque (o repo vacío): no hay nada que instalar todavía.
    # No abortamos: continuamos para exportar las extensiones locales y subirlas.
    $msg = "extensiones.txt vacío (primer arranque). Se exportarán las extensiones locales."
    Write-Host $msg -ForegroundColor Yellow
    Write-Log $msg
} else {
    $installedExts = antigravity --list-extensions 2>&1 | Select-String -NotMatch "createInstance" | ForEach-Object { $_.ToString().Trim() }
    Get-Content $extFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' } | ForEach-Object {
        $ext = $_
        if ($installedExts -contains $ext) {
            $countSkipped++
        } else {
            Write-Host "Instalando extensión: $ext" -ForegroundColor Cyan
            antigravity --install-extension $ext 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $countInstalled++ } else { $countFailed++; Write-Log "Error al instalar la extensión: $ext" }
        }
    }
}

# 5. Exportar de vuelta las extensiones locales (filtrando el warning known)
antigravity --list-extensions 2>&1 | Select-String -NotMatch "createInstance" | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -match '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' } | Out-File $extFile -Encoding UTF8
$extCount = @(Get-Content $extFile | Where-Object { $_.Trim() -ne "" }).Count

# 6. Comprobar si hay cambios en git
$status = git status --porcelain $extFile
if (-not $status) {
    $msg = "Sin cambios a hacer push."
    Write-Host $msg -ForegroundColor Yellow
    Write-Log $msg
} else {
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
}

# 8. Log resumen
$msg = "Sincronización completada. Instaladas: $countInstalled, Omitidas: $countSkipped, Fallidas: $countFailed"
Write-Log $msg
Write-Host $msg -ForegroundColor Green
Write-Host "Total extensiones actuales: $extCount" -ForegroundColor Cyan
