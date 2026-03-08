# Antigravity Sync

Herramienta de sincronización automática y bidireccional de extensiones de Antigravity (VS Code) entre entornos Windows y Linux.

Utiliza Git como motor de sincronización y garantiza que el entorno de desarrollo sea idéntico en ambos sistemas operativos sin intervención manual diaria.

## Características

- Sincronización automática mediante tareas programadas (Windows) y perfil de bash (Linux).
- Resolución de conflictos priorizando la versión remota.
- Rotación automática de logs (límite de 1MB).
- Filtrado inteligente de errores de entorno para no corromper la lista de extensiones.

## Requisitos previos

- Git instalado y configurado en ambos sistemas.
- Antigravity instalado en el `PATH`.
- Un repositorio de GitHub vacío o inicializado para este propósito (ej. `antigravity-sync`).
- Configuración de autenticación en Git (recomendado usar [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) o SSH).

## Instalación

### En Windows

1. Clona el repositorio en la ubicación deseada.
2. Abre PowerShell como Administrador (si es necesario para la tarea programada) y ejecuta:
   ```powershell
   .\setup_windows.ps1
   ```
3. Sigue las instrucciones. El script te pedirá la URL del repositorio remoto.
4. Se creará una Tarea Programada que sincronizará las extensiones en cada inicio de sesión.

### En Linux (Ubuntu/Debian)

1. Clona el repositorio en la ubicación deseada.
2. Otorga permisos de ejecución al instalador y ejecútalo:
   ```bash
   chmod +x setup_linux.sh
   ./setup_linux.sh
   ```
3. Sigue las instrucciones e introduce la URL del repositorio.
4. Se añadirá una entrada en `~/.bashrc` para sincronizar una vez al día automáticamente al abrir la terminal.

## Sincronización manual

Puedes forzar la sincronización en cualquier momento ejecutando los scripts principales desde la raíz del proyecto:

**Windows:**
```powershell
.\sync_windows.ps1
```

**Linux:**
```bash
./sync_linux.sh
```

## Solución de problemas comunes

- **Fallo de push por credenciales:** Asegúrate de que Git tiene cacheadas tus credenciales. Puedes forzar el guardado usando `git config --global credential.helper store`.
- **Extensiones que no se instalan en Linux:** Revisa el archivo `sync.log` generado en el directorio del script. Algunas extensiones pueden ser incompatibles entre plataformas.
- **Exportación vacía:** Si `extensiones.txt` se queda vacío, asegúrate de que el comando `antigravity --list-extensions` funciona correctamente en tu terminal sin devolver errores críticos que bloqueen la salida.

---

### Autor

**Fran (ASIR)**

- [GitHub](https://github.com/Haplee)
- [Instagram](https://www.instagram.com/franvidalmateo)
- [X (Twitter)](https://x.com/FranVidalMateo)
