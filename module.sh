#!/bin/bash
# MODULO DE FUNCIONES - Menu VPS Libre
# Sin licencia - Uso libre

# Colores
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export CYAN='\033[1;36m'
export WHITE='\033[1;37m'
export NC='\033[0m'

# Directorios
export VPS_DIR="/etc/omux"
export VPS_USER="${VPS_DIR}/user"
export VPS_TMP="${VPS_DIR}/tmp"

# Crear directorios si no existen
[[ ! -d ${VPS_DIR} ]] && mkdir -p ${VPS_DIR}
[[ ! -d ${VPS_USER} ]] && mkdir -p ${VPS_USER}
[[ ! -d ${VPS_TMP} ]] && mkdir -p ${VPS_TMP}

# Funcion para imprimir barra
bar() {
    echo -e "${RED}=====================================================${NC}"
}

bar2() {
    echo -e "${RED}-----------------------------------------------------${NC}"
}

# Funcion para imprimir mensaje
msg() {
    case $1 in
        -red)    echo -e "${RED}$2${NC}";;
        -green)  echo -e "${GREEN}$2${NC}";;
        -yellow) echo -e "${YELLOW}$2${NC}";;
        -blue)   echo -e "${BLUE}$2${NC}";;
        -cyan)   echo -e "${CYAN}$2${NC}";;
        -white)  echo -e "${WHITE}$2${NC}";;
        *)       echo -e "$1";;
    esac
}

# Centrar texto
print_center() {
    local text="$1"
    local width=53
    local len=${#text}
    local padding=$(( (width - len) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# Titulo
title() {
    clear
    bar
    print_center "$1"
    bar
}

# Presionar enter para continuar
enter() {
    echo ""
    read -p "  Presione ENTER para continuar..."
}

# Obtener IP publica
get_ip() {
    curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "No disponible"
}

# Verificar si es root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        msg -red "Este script debe ejecutarse como root"
        exit 1
    fi
}
