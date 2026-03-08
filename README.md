# Antigravity Sync

Script de sincronización automática bidireccional de extensiones de Antigravity entre entornos Windows y Linux (Ubuntu).

## Requisitos previos

- Git instalado
- Antigravity instalado en Windows y/o Ubuntu
- Cuenta de GitHub con un repositorio creado para esto (ej. `antigravity-sync`)
- Token de acceso personal (PAT) de GitHub configurado para operaciones de Git.

## Instalación en Windows

1. Clona el repositorio en una carpeta temporal o descarga los scripts.
2. Abre PowerShell y ejecuta el archivo de configuración:
   ```powershell
   .\setup_windows.ps1
   ```
3. Sigue las instrucciones en pantalla (introduce la URL de tu repositorio y configura tu cuenta de Git si es necesario).
4. El script clonará el repo en tu carpeta de usuario y creará una Tarea Programada que sincroniza las extensiones automáticamente al iniciar sesión.

## Instalación en Ubuntu

1. Clona el repositorio o descarga los archivos.
2. Dale permisos de ejecución y lanza el script:
   ```bash
   chmod +x setup_linux.sh
   ./setup_linux.sh
   ```
3. Sigue las instrucciones (se te pedirá la URL del repo).
4. El script configurará una ejecución automática en tu `~/.bashrc` para que las extensiones se actualicen una vez al día al abrir el terminal.

## Uso manual

Si quieres forzar una sincronización en cualquier momento, basta con ejecutar los scripts principales desde la carpeta en la que se clonó:

**Windows:**
```powershell
.\sync_windows.ps1
```

**Linux:**
```bash
./sync_linux.sh
```

## Cómo funciona

1. **En Windows:** El script comprueba si hay cambios remotos (hace pull). En caso de conflicto, predomina la versión en la nube. Luego, lee todas las extensiones instaladas en Antigravity localmente (filtrando advertencias de consola), las guarda en `extensiones.txt` y hace push al repositorio.
2. **En Linux:** Al abrir una terminal (máximo 1 vez al día), hace pull del repositorio. Lee el `extensiones.txt` que subió Windows, limpia el texto de formatos incompatibles, e instala todas las extensiones que falten. Después de instalar, vuelve a exportar y hace un push por si hubo cambios y mantiene los entornos parejos.

## Solución de problemas

- **Push falla por credenciales:** Asegúrate de usar un Token de Acceso Personal (PAT) de GitHub. Puedes cachear las credenciales usando `git config --global credential.helper store` e ingresando tu nombre de usuario y PAT la próxima vez que te pida la contraseña.
- **La extensión no se instala en Ubuntu:** Puede que el ID no exista o no sea compatible. Revisa el archivo `sync.log` en el directorio del repositorio para ver qué extensiones fallaron.
- **`extensiones.txt` aparece vacío:** El script de sincronización abortará si detecta que la exportación local retornó un archivo vacío por seguridad. Asegúrate de tener extensiones instaladas y de que el comando `antigravity --list-extensions` funciona sin devolver errores críticos.
- **Consultar logs:** Se genera automáticamente un archivo `sync.log` en la carpeta donde viven los scripts que almacena el historial de todas las sincronizaciones, con rotación a 1MB.
