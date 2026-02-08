#!/bin/bash
# GESTION DE USUARIOS SSH - Menu VPS Libre

source /etc/vpsmenu/module.sh 2>/dev/null || source "$(dirname "$0")/module.sh"

# Crear usuario SSH
crear_usuario() {
    title "CREAR USUARIO SSH"

    read -p "  Nombre de usuario: " usuario
    [[ -z $usuario ]] && msg -red "  Usuario vacio" && return

    if id "$usuario" &>/dev/null; then
        msg -red "  El usuario ya existe"
        enter
        return
    fi

    read -p "  Contrasena: " -s pass
    echo ""
    [[ -z $pass ]] && msg -red "  Contrasena vacia" && return

    read -p "  Dias de duracion (0=ilimitado): " dias
    [[ -z $dias ]] && dias=30

    read -p "  Limite de conexiones: " limite
    [[ -z $limite ]] && limite=1

    # Crear usuario
    if [[ $dias -eq 0 ]]; then
        useradd -M -s /bin/false -p $(openssl passwd -1 "$pass") "$usuario" 2>/dev/null
    else
        fecha_exp=$(date -d "+${dias} days" +%Y-%m-%d)
        useradd -M -s /bin/false -e "$fecha_exp" -p $(openssl passwd -1 "$pass") "$usuario" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        # Guardar limite
        echo "$limite" > ${VPS_USER}/${usuario}.limit

        bar2
        msg -green "  Usuario creado exitosamente"
        bar2
        echo -e "  ${YELLOW}Usuario:${NC} $usuario"
        echo -e "  ${YELLOW}Contrasena:${NC} $pass"
        echo -e "  ${YELLOW}Limite:${NC} $limite conexiones"
        [[ $dias -gt 0 ]] && echo -e "  ${YELLOW}Expira:${NC} $fecha_exp"
        echo -e "  ${YELLOW}IP:${NC} $(get_ip)"
        bar2
    else
        msg -red "  Error al crear usuario"
    fi
    enter
}

# Eliminar usuario
eliminar_usuario() {
    title "ELIMINAR USUARIO SSH"

    # Listar usuarios
    echo -e "  ${CYAN}Usuarios existentes:${NC}"
    bar2

    usuarios=$(cat /etc/passwd | grep "/bin/false" | grep -v "syslog\|nologin" | awk -F: '{print $1}')
    if [[ -z $usuarios ]]; then
        msg -yellow "  No hay usuarios SSH"
        enter
        return
    fi

    echo "$usuarios" | nl -w2 -s") "
    bar2

    read -p "  Usuario a eliminar: " usuario
    [[ -z $usuario ]] && return

    if id "$usuario" &>/dev/null; then
        userdel -f "$usuario" 2>/dev/null
        rm -f ${VPS_USER}/${usuario}.limit 2>/dev/null
        msg -green "  Usuario $usuario eliminado"
    else
        msg -red "  Usuario no encontrado"
    fi
    enter
}

# Listar usuarios
listar_usuarios() {
    title "LISTA DE USUARIOS SSH"

    printf "  ${YELLOW}%-15s %-12s %-10s %-8s${NC}\n" "USUARIO" "EXPIRACION" "LIMITE" "ONLINE"
    bar2

    while read line; do
        [[ -z $line ]] && continue
        usuario=$(echo $line | cut -d: -f1)

        # Fecha expiracion
        exp=$(chage -l "$usuario" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        [[ "$exp" == "never" ]] && exp="Nunca"

        # Limite
        if [[ -f ${VPS_USER}/${usuario}.limit ]]; then
            limite=$(cat ${VPS_USER}/${usuario}.limit)
        else
            limite="1"
        fi

        # Conexiones activas
        online=$(ps -u "$usuario" 2>/dev/null | grep -c sshd)

        printf "  %-15s %-12s %-10s %-8s\n" "$usuario" "$exp" "$limite" "$online"

    done <<< "$(cat /etc/passwd | grep "/bin/false" | grep -v "syslog\|nologin")"

    bar
    enter
}

# Cambiar contrasena
cambiar_pass() {
    title "CAMBIAR CONTRASENA"

    read -p "  Usuario: " usuario
    [[ -z $usuario ]] && return

    if ! id "$usuario" &>/dev/null; then
        msg -red "  Usuario no existe"
        enter
        return
    fi

    read -p "  Nueva contrasena: " -s pass
    echo ""
    [[ -z $pass ]] && msg -red "  Contrasena vacia" && return

    echo "$usuario:$pass" | chpasswd

    if [[ $? -eq 0 ]]; then
        msg -green "  Contrasena cambiada exitosamente"
    else
        msg -red "  Error al cambiar contrasena"
    fi
    enter
}

# Renovar usuario
renovar_usuario() {
    title "RENOVAR USUARIO"

    read -p "  Usuario: " usuario
    [[ -z $usuario ]] && return

    if ! id "$usuario" &>/dev/null; then
        msg -red "  Usuario no existe"
        enter
        return
    fi

    read -p "  Dias a agregar: " dias
    [[ -z $dias ]] && dias=30

    fecha_exp=$(date -d "+${dias} days" +%Y-%m-%d)
    chage -E "$fecha_exp" "$usuario"

    msg -green "  Usuario renovado hasta: $fecha_exp"
    enter
}

# Monitor de conexiones
monitor_conexiones() {
    title "MONITOR DE CONEXIONES"

    echo -e "  ${CYAN}Conexiones SSH activas:${NC}"
    bar2

    who | grep -v "pts" | head -20

    bar2
    echo -e "  ${CYAN}Conexiones por usuario:${NC}"
    bar2

    while read line; do
        [[ -z $line ]] && continue
        usuario=$(echo $line | cut -d: -f1)
        online=$(ps -u "$usuario" 2>/dev/null | grep -c sshd)
        [[ $online -gt 0 ]] && echo -e "  ${GREEN}$usuario${NC}: $online conexion(es)"
    done <<< "$(cat /etc/passwd | grep "/bin/false" | grep -v "syslog")"

    bar
    enter
}

# Menu principal de usuarios
menu_usuarios() {
    while true; do
        title "GESTION DE USUARIOS SSH"

        echo -e "  ${GREEN}[1]${NC} > Crear usuario"
        echo -e "  ${GREEN}[2]${NC} > Eliminar usuario"
        echo -e "  ${GREEN}[3]${NC} > Listar usuarios"
        echo -e "  ${GREEN}[4]${NC} > Cambiar contrasena"
        echo -e "  ${GREEN}[5]${NC} > Renovar usuario"
        echo -e "  ${GREEN}[6]${NC} > Monitor conexiones"
        echo -e "  ${RED}[0]${NC} > Volver"

        bar
        read -p "  Opcion: " opc

        case $opc in
            1) crear_usuario ;;
            2) eliminar_usuario ;;
            3) listar_usuarios ;;
            4) cambiar_pass ;;
            5) renovar_usuario ;;
            6) monitor_conexiones ;;
            0) return ;;
            *) msg -red "  Opcion invalida" && sleep 1 ;;
        esac
    done
}

# Ejecutar si se llama directamente
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && menu_usuarios
