# OMUX PRO - SSH Dropbear Standalone

Este paquete contiene la versión standalone del módulo SSH/Dropbear extraído de ADMRufu, optimizado para la gestión de túneles SSH.

## Contenido

- `install.sh`: Script de instalación automatizada.
- `services.sh`: Lógica de instalación y configuración de servicios (Dropbear, Stunnel, Squid, BadVPN).
- `user.sh`: Gestor de usuarios SSH (Crear, borrar, monitorizar, limitar).
- `module.sh`: Librería de funciones y colores.

## Instalación

1.  Subir la carpeta `omux` a tu VPS (ej. en `/root/omux`).
2.  Dar permisos de ejecución:
    ```bash
    chmod +x install.sh user.sh services.sh module.sh
    ```
3.  Ejecutar el instalador:
    ```bash
    ./install.sh
    ```

## Uso

### Gestión de Usuarios
Para crear, borrar o gestionar usuarios SSH, ejecuta:
```bash
./user.sh
```
O si usaste el instalador:
```bash
omux-user
```
Opción 1: Crear usuario (Define usuario, contraseña y días de expiración).

### Gestión de Servicios
Para reinstalar o configurar puertos de Dropbear, Stunnel, etc., ejecuta:
```bash
./services.sh
```

## Validación de Usuarios (Active vs Expired)
El sistema utiliza las cuentas de usuario nativas de Linux (`/etc/passwd`, `/etc/shadow`) y la caducidad de cuenta (`chage`).
- **Usuario Activo**: Fecha de expiración futura o nula. El login es permitido por SSH/Dropbear.
- **Usuario Caducado**: Fecha de expiración pasada. El sistema (PAM/SSH) rechaza la conexión automáticamente, resultando en el cierre de conexión tras la autenticación.

Los logs mostrarán "Connection closed" o "Password authentication failed" (dependiendo de la configuración PAM) para usuarios caducados.
