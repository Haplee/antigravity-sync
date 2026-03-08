## [2026-03-08] — Creación inicial del proyecto antigravity-sync

- Creada la estructura base del repositorio con los scripts de instalación y sincronización para Windows y Linux
- Implementada la lógica de sincronización bidireccional usando Git como motor de sincronización
- Añadido el README explicativo con las instrucciones de uso y resolución de problemas
- Incluida gestión avanzada de variables de entorno, logs rotativos y gestión de conflictos
- Estado actual del proyecto: Listo para probar en los entornos locales de Windows y Linux

## [2026-03-08] — Corrección del comando list-extensions

- Se actualizó el comando `antigravity --list-extensions` para incluir `2>&1 | grep -v "createInstance"` en lugar de silenciar por completo la salida de error
- Se hizo para solucionar el problema donde no se exportaban todas las extensiones correctamente debido a los warnings del entorno
- Estado actual del proyecto: Sincronización en Linux pulida y lista para usar

## [2026-03-08] — Mejora del README

- Se reestructuró y mejoró redactacionalmente el README para que sea más profesional y conciso
- Se añadieron los enlaces obligatorios a redes sociales en cumplimiento con los estándares del autor
- Se añadieron requisitos previos y detalles de instalación extendidos
- Estado actual del proyecto: Documentación final mejorada y lista para compartir
