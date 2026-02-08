# Análisis de Logs SSH/Dropbear: Usuario Activo vs Caducado

Esta referencia técnica explica las diferencias exactas en los logs de conexión (NPV Tunnel) entre un usuario válido y uno expirado.

## 🟢 1. Usuario ACTIVO (Conexión Exitosa)

Cuando el usuario tiene permisos vigentes, el servidor acepta la autenticación y establece el túnel.

### Logs Típicos (NPV Tunnel)
```text
20:43:04    Starting VPN
20:43:04    VPN established
20:43:04    Connecting...
20:43:07    Server Response:
            HTTP/1.1 101 Switching Protocols
20:43:07    Server Response:
            SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u7
20:43:09    Connected ✅
```
*Duración aprox: 5 segundos*

### Proceso Interno (Éxito)
1.  **Starting VPN** -> **VPN established**: El servicio VPN local arranca correctamente.
2.  **Connecting...**: Inicia el handshake.
3.  **HTTP/1.1 101 Switching Protocols**: El servidor acepta upgrade a WebSocket ✅.
4.  **SSH-2.0...**: El servidor SSH responde y solicita credenciales ✅.
5.  **Connected**: Usuario/Pass correctos y vigentes. Túnel establecido.

---

## 🔴 2. Usuario CADUCADO (Conexión Fallida)

Cuando el usuario existe pero su fecha de expiración ha pasado, el servidor acepta la conexión inicial pero **rechaza la autenticación**.

### Logs Típicos (NPV Tunnel)
```text
13:38:06    Server Response:
            HTTP/1.1 101 Switching Protocols
13:38:06    Server Response:
            SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u7
13:38:10    Connection failed: tunnel failed ❌
13:38:11    Connecting...
13:38:11    Server Response:
            HTTP/1.1 200 OK
13:38:11    Server Response:
            HTTP/1.0 400 Bad Request ❌
13:38:11    Server Response: ... [HTML de Google/Error] ...
```

### Proceso Interno (Fallo)
1.  **HTTP/1.1 101** y **SSH-2.0...**: El servidor responde inicialmente ✅ (porque la IP es accesible).
2.  **Connection failed**: Dropbear valida la fecha de expiración y **cierra la conexión** de golpe ❌.
3.  **Connecting...**: La App intenta reconectar automáticamente.
4.  **400 Bad Request / HTML**: Al intentar reconectar sobre una sesión cerrada o recibir basura, la App interpreta respuestas erróneas (como páginas de error del operador o del proxy).

---

## 🔍 Comparación Lado a Lado

| Evento | Usuario ACTIVO ✅ | Usuario CADUCADO ❌ |
| :--- | :--- | :--- |
| **Inicio Conexión** | `Starting VPN` | A veces no aparece en reconexiones |
| **Websocket Upgrade** | `101 Switching Protocols` | `101 Switching Protocols` (Igual) |
| **Versión SSH** | `SSH-2.0-OpenSSH...` | `SSH-2.0-OpenSSH...` (Igual) |
| **Autenticación** | ✅ **Aceptada** | ❌ **Rechazada** (Cierre de conexión) |
| **Mensaje Error** | Ninguno | `Connection failed: tunnel failed` |
| **Estado Final** | `Connected` | `HTTP/1.0 400 Bad Request` + HTML Basura |

## 🛠 Solución

Para arreglar el error de "Usuario Caducado" en tu panel OMUX:

1.  Ejecuta `omux`.
2.  Ve a **[1] ADMINISTRAR CUENTAS**.
3.  Selecciona **[5] Renovar usuario**.
4.  Introduce el nombre del usuario y los días extra.
5.  ¡Intenta conectar de nuevo!
