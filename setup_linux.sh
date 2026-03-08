#!/bin/bash
# setup_linux.sh

echo -e "\e[36mIniciando configuración de antigravity-sync en Linux...\e[0m"

# 1. Verificar Git
if ! command -v git &> /dev/null; then
    echo -e "\e[33mGit no está instalado. Instalando...\e[0m"
    sudo apt update && sudo apt install git -y
fi

# 2. Verificar Antigravity
if ! command -v antigravity &> /dev/null; then
    echo -e "\e[31mError: Antigravity no está instalado. Por favor, instálalo antes de continuar.\e[0m"
    exit 1
fi

# 3. Pedir URL del repo y guardar en ~/.antigravity-sync.env
ENV_FILE="$HOME/.antigravity-sync.env"
read -p "Introduce la URL del repositorio GitHub (ej. https://github.com/usuario/antigravity-sync): " REPO_URL
if [ -z "$REPO_URL" ]; then
    echo -e "\e[31mURL no válida.\e[0m"
    exit 1
fi
echo "REPO_URL=$REPO_URL" > "$ENV_FILE"

# 4. Configurar Git user/email si no existen
if [ -z "$(git config --global user.name)" ]; then
    read -p "Introduce tu nombre para Git: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Introduce tu email para Git: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

# 5. Clonar repo
TARGET_DIR="$HOME/antigravity-sync"
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "\e[36mClonando repositorio en $TARGET_DIR...\e[0m"
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo -e "\e[33mEl directorio $TARGET_DIR ya existe. Omitiendo clonación.\e[0m"
fi

# 6. Añadir al ~/.bashrc si no existe
BASHRC_ENTRY="
# Antigravity Sync
if [ -f \"$TARGET_DIR/sync_linux.sh\" ]; then
    LAST_SYNC_FILE=\"$HOME/.last_sync\"
    if [ ! -f \"\$LAST_SYNC_FILE\" ] || [ \$(expr \$(date +%s) - \$(stat -c %Y \"\$LAST_SYNC_FILE\")) -gt 86400 ]; then
        bash \"$TARGET_DIR/sync_linux.sh\"
    fi
fi
"

if ! grep -q "Antigravity Sync" "$HOME/.bashrc"; then
    echo "$BASHRC_ENTRY" >> "$HOME/.bashrc"
    echo -e "\e[32mEjecución automática añadida a ~/.bashrc.\e[0m"
fi

# 7. Permisos de ejecución
chmod +x "$TARGET_DIR/sync_linux.sh"

echo -e "\e[32mConfiguración completada con éxito. Ya puedes usar antigravity-sync.\e[0m"
