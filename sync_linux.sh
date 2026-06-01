#!/bin/bash
# sync_linux.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
LOG_FILE="$SCRIPT_DIR/sync.log"

# Función de log con rotación (máx 1MB)
write_log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    
    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -c%s "$LOG_FILE")
        if [ "$size" -gt 1048576 ]; then
            mv "$LOG_FILE" "$LOG_FILE.old"
        fi
    fi
    echo "$message" >> "$LOG_FILE"
}

write_log "Iniciando sincronización en Linux"

# 1. Leer URL
ENV_FILE="$HOME/.antigravity-sync.env"
if [ ! -f "$ENV_FILE" ]; then
    msg="Error: Archivo .env no encontrado. Ejecuta setup_linux.sh primero."
    echo -e "\e[31m$msg\e[0m"
    write_log "$msg"
    exit 1
fi

source "$ENV_FILE"

# 2. Verificar dependencias
if ! command -v antigravity &> /dev/null; then
    msg="Error: Antigravity no está instalado."
    echo -e "\e[31m$msg\e[0m"
    write_log "$msg"
    exit 1
fi

if ! command -v git &> /dev/null; then
    msg="Error: Git no está instalado."
    echo -e "\e[31m$msg\e[0m"
    write_log "$msg"
    exit 1
fi

cd "$SCRIPT_DIR" || exit 1

# 3. Pull con manejo de conflictos
write_log "Obteniendo cambios remotos..."
if ! git pull; then
    write_log "Conflicto en pull. Resolviendo a favor de versión remota."
    echo -e "\e[33mConflicto detectado en extensiones.txt. Manteniendo versión del servidor...\e[0m"
    git checkout --theirs extensiones.txt
    git add extensiones.txt
    git commit -m "Merge: resolución de conflicto a favor de repositorio remoto"
fi

# 4. Comprobar el fichero de extensiones
EXT_FILE="extensiones.txt"
COUNT_INSTALLED=0
COUNT_SKIPPED=0
COUNT_FAILED=0

if [ ! -s "$EXT_FILE" ]; then
    # Primer arranque (o repo vacío): no hay nada que instalar todavía.
    # No abortamos: continuamos para exportar las extensiones locales y subirlas.
    msg="extensiones.txt vacío (primer arranque). Se exportarán las extensiones locales."
    echo -e "\e[33m$msg\e[0m"
    write_log "$msg"
else
    # 5. Limpiar el archivo e instalar lo que falte
    TMP_FILE=$(mktemp)
    tr -d '\r' < "$EXT_FILE" | sed '/^[[:space:]]*$/d' | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' > "$TMP_FILE"

    INSTALLED_EXTS=$(antigravity --list-extensions 2>&1 | grep -v "createInstance")

    while read -r ext; do
        if echo "$INSTALLED_EXTS" | grep -i -q "^${ext}$"; then
            ((COUNT_SKIPPED++))
        else
            echo -e "\e[36mInstalando extensión: $ext\e[0m"
            if antigravity --install-extension "$ext" &> /dev/null; then
                ((COUNT_INSTALLED++))
            else
                ((COUNT_FAILED++))
                write_log "Error al instalar la extensión: $ext"
            fi
        fi
    done < "$TMP_FILE"
    rm -f "$TMP_FILE"
fi

# 6. Exportar de vuelta, hacer push y actualizar .last_sync
antigravity --list-extensions 2>&1 | grep -v "createInstance" | grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' > "$EXT_FILE"
TOTAL_EXTS=$(wc -l < "$EXT_FILE")

date +%s > "$HOME/.last_sync"

if git status --porcelain | grep -q "$EXT_FILE"; then
    git add "$EXT_FILE"
    git commit -m "Sincronización Linux: $(date +'%Y-%m-%d %H:%M:%S') ($TOTAL_EXTS extensiones)" >/dev/null
    if ! git push &> /dev/null; then
        write_log "Error en git push. Verifica las credenciales."
        echo -e "\e[31mError al hacer push. Revisa tu token de GitHub.\e[0m"
    fi
else
    write_log "Sin cambios para exportar después de sincronizar."
    echo -e "\e[33mSin cambios a hacer push.\e[0m"
fi

# 7. Resumen
msg="Sincronización completada. Instaladas: $COUNT_INSTALLED, Omitidas: $COUNT_SKIPPED, Fallidas: $COUNT_FAILED"
write_log "$msg"
echo -e "\e[32m$msg\e[0m"
echo -e "\e[36mTotal extensiones actuales: $TOTAL_EXTS\e[0m"
