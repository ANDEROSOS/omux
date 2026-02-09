#!/bin/bash
# GESTION DE USUARIOS SSH - OMUX Panel
# Versión corregida para NPV Tunnel

source /etc/omux/module.sh 2>/dev/null || source "$(dirname "$0")/module.sh"

# Crear usuario SSH
crear_usuario() {
    title "CREAR USUARIO SSH"

    read -p "  Nombre de usuario: " usuario
    [[ -z $usuario ]] && msg -red "  Usuario vacio" && enter && return

    if id "$usuario" &>/dev/null; then
        msg -red "  El usuario ya existe"
        enter
        return
    fi

    read -p "  Contrasena: " -s pass
    echo ""
    [[ -z $pass ]] && msg -red "  Contrasena vacia" && enter && return

    read -p "  Dias de duracion (0=ilimitado): " dias
    [[ -z $dias ]] && dias=30

    read -p "  Limite de conexiones: " limite
    [[ -z $limite ]] && limite=1

    # Crear directorio tmp si no existe
    mkdir -p "${VPS_TMP}"
    chmod 777 "${VPS_TMP}"

    # Crear usuario
    if [[ $dias -eq 0 ]]; then
        useradd -M -s /bin/false -d ${VPS_TMP} "$usuario" 2>/dev/null
        echo "$usuario:$pass" | chpasswd
    else
        fecha_exp=$(date -d "+${dias} days" +%Y-%m-%d)
        useradd -M -s /bin/false -d ${VPS_TMP} -e "$fecha_exp" "$usuario" 2>/dev/null
        echo "$usuario:$pass" | chpasswd
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
        echo -e "  ${YELLOW}IP VPS:${NC} $(get_ip)"
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

    usuarios=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | grep -v "^$")
    if [[ -z $usuarios ]]; then
        msg -yellow "  No hay usuarios SSH"
        enter
        return
    fi

    echo "$usuarios" | nl -w2 -s") "
    bar2
    
    # Guardar usuarios en array
    mapfile -t lista_usuarios <<< "$usuarios"

    read -p "  Usuario a eliminar (numero o nombre): " seleccion
    [[ -z $seleccion ]] && return

    # Verificar si es numero
    if [[ "$seleccion" =~ ^[0-9]+$ ]]; then
        index=$((seleccion-1))
        if [[ $index -ge 0 && $index -lt ${#lista_usuarios[@]} ]]; then
            usuario="${lista_usuarios[$index]}"
        else
            usuario="$seleccion"
        fi
    else
        usuario="$seleccion"
    fi

    if id "$usuario" &>/dev/null; then
        # Matar procesos del usuario
        pkill -u "$usuario" 2>/dev/null
        # Eliminar usuario
        userdel -r "$usuario" 2>/dev/null || userdel -f "$usuario" 2>/dev/null
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

    usuarios=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
    
    if [[ -z "$usuarios" ]]; then
        msg -yellow "  No hay usuarios creados"
        bar
        enter
        return
    fi

    while read -r usuario; do
        [[ -z $usuario ]] && continue

        # Fecha expiracion
        exp=$(chage -l "$usuario" 2>/dev/null | grep "Account expires" | awk -F: '{print $2}' | xargs)
        [[ -z "$exp" || "$exp" == "never" ]] && exp="Nunca"

        # Limite
        if [[ -f ${VPS_USER}/${usuario}.limit ]]; then
            limite=$(cat ${VPS_USER}/${usuario}.limit)
        else
            limite="1"
        fi

        # Conexiones activas
        online=$(ps -u "$usuario" 2>/dev/null | grep -c "sshd\|dropbear")

        printf "  %-15s %-12s %-10s %-8s\n" "$usuario" "$exp" "$limite" "$online"
    done <<< "$usuarios"

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
    [[ -z $pass ]] && msg -red "  Contrasena vacia" && enter && return

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
    chage -E "$fecha_exp" "$usuario" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        msg -green "  Usuario renovado hasta: $fecha_exp"
    else
        msg -yellow "  Renovando usuario..."
        usermod -e "$fecha_exp" "$usuario" 2>/dev/null
        msg -green "  Usuario renovado hasta: $fecha_exp"
    fi
    enter
}

# Monitor de conexiones
monitor_conexiones() {
    title "MONITOR DE CONEXIONES"

    echo -e "  ${CYAN}Conexiones SSH/Dropbear activas:${NC}"
    bar2

    # Mostrar conexiones SSH
    who 2>/dev/null | head -20
    
    bar2
    echo -e "  ${CYAN}Conexiones por usuario:${NC}"
    bar2

    usuarios=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)
    
    while read -r usuario; do
        [[ -z $usuario ]] && continue
        online=$(ps -u "$usuario" 2>/dev/null | grep -c "sshd\|dropbear")
        [[ $online -gt 0 ]] && echo -e "  ${GREEN}$usuario${NC}: $online conexion(es)"
    done <<< "$usuarios"

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
