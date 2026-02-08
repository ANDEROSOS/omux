# Análisis de Logs SSH/Dropbear: Usuario Activo vs Caducado

Esta guía compara los logs de conexión de un túnel SSH (como NPV Tunnel) en dos escenarios: con un usuario **ACTIVO** y con un usuario **CADUCADO**.

## 🟢 1. Usuario ACTIVO (Conexión Exitosa)

Cuando el usuario tiene permisos vigentes, la conexión se establece correctamente y el tráfico fluye a través del túnel.

### Logs Típicos (Copiados de tu NPV Tunnel)
```text
20:43:09    Connected
20:43:07    Server Response: SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u7
20:43:07    Server Response: HTTP/1.1 101 Switching Protocols
20:43:04    Connecting...
20:43:04    VPN established
20:43:04    Starting VPN
```

### Proceso Interno (Éxito)
1.  **Starting VPN** -> **VPN established**: El servicio VPN local arranca.
2.  **Connecting...**: Inicia el intento de conexión al servidor.
3.  **HTTP/1.1 101 Switching Protocols**: El servidor acepta el upgrade a WebSocket ✅.
4.  **SSH-2.0-OpenSSH...**: El servidor SSH responde ✅.
5.  **Connected**: Autenticación exitosa y túnel establecido ✅.

---

## 🔴 2. Usuario CADUCADO (Conexión Fallida)

### Logs Típicos (Copiados de tu NPV Tunnel)
```text
13:38:11    Server Response: ... [HTML de Google/Error] ...
13:38:11    Server Response: HTTP/1.0 400 Bad Request
13:38:11    Server Response: HTTP/1.1 200 OK
13:38:11    Connecting...
13:38:10    Connection failed: tunnel failed
13:38:06    Server Response: SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u7
13:38:06    Server Response: HTTP/1.1 101 Switching Protocols
```

### Proceso Interno (Fallo)
1.  **HTTP/1.1 101** y **SSH-2.0...**: El servidor responde inicialmente ✅.
2.  **Connection failed: tunnel failed**: Aquí es donde Dropbear cierra la conexión porque el usuario expiró ❌.
3.  **Connecting...**: El cliente intenta re-conectar automáticamente.
4.  **HTTP/1.1 200 OK** y **HTTP/1.0 400 Bad Request**: El cliente recibe basura o páginas de error al intentar reconectar sobre una sesión cerrada o fallida, mostrando código HTML.

---

## 🔍 Comparación Lado a Lado

| Evento | Usuario ACTIVO ✅ | Usuario CADUCADO ❌ |
| :--- | :--- | :--- |
| **Inicio Conexión** | `Starting VPN` | A veces no se loguea si es reconexión |
| **Websocket Upgrade** | `101 Switching Protocols` | `101 Switching Protocols` (Igual) |
| **Versión SSH** | `SSH-2.0-OpenSSH...` | `SSH-2.0-OpenSSH...` (Igual) |
| **Autenticación** | ✅ **Aceptada** | ❌ **Rechazada** (Cierre de conexión) |
| **Mensaje Error** | Ninguno | `Connection failed: tunnel failed` |
| **Estado Final** | `Connected` | `HTTP/1.0 400 Bad Request` + HTML Basura |

## 🛠 Solución

Para arreglar el error de "Usuario Caducado":

1.  Usar el script de gestión:
    ```bash
    ./omux/user.sh
    ```
2.  Seleccionar opción **[5] Renovar usuario**.
3.  Ingresar el usuario y los días a extender.
4.  Reconectar el VPN.
