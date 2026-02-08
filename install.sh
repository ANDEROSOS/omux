#!/bin/bash
# Instalador de OMUX (SSH Dropbear Standalone)
# Extraido de ADMRufu

# Directorio actual
DIR="$(dirname "$(readlink -f "$0")")"
INSTALL_DIR="/etc/omux"

# Cargar modulo
if [[ -f "$DIR/module.sh" ]]; then
    source "$DIR/module.sh"
else
    echo "Error: No se encuentra module.sh"
    exit 1
fi

check_root

title "INSTALADOR OMUX - SSH DROPBEAR"

print_center "Instalando dependencias..."
apt-get update -y
apt-get install -y curl wget lsof

# Crear directorio de instalacion
if [[ ! -d "$INSTALL_DIR" ]]; then
    mkdir -p "$INSTALL_DIR"
    print_center "Creando directorio $INSTALL_DIR..."
fi

# Copiar archivos
cp "$DIR/user.sh" "$INSTALL_DIR/"
cp "$DIR/services.sh" "$INSTALL_DIR/"
cp "$DIR/module.sh" "$INSTALL_DIR/"
cp "$DIR/menu" "$INSTALL_DIR/"
cp "$DIR/badvpn-udpgw" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/"*.sh
chmod +x "$INSTALL_DIR/menu"

# Cargar funciones de servicios para instalar dropbear
if [[ -f "$INSTALL_DIR/services.sh" ]]; then
    source "$INSTALL_DIR/services.sh"
    # Ejecutar instalacion de Dropbear si se desea auto-instalar, 
    # o dejar que el usuario lo haga desde el menu.
    # Por defecto en el script original parecia manual, pero aqui
    # podemos ofrecerlo. Lo dejaremos manual via menu para evitar conflictos inesperados,
    # o llamamos a install_dropbear si queremos que quede listo 'out of the box'.
    # Para ser seguros, solo instalamos dependencias binarias.
else
    echo "Error al copiar scripts a $INSTALL_DIR"
    exit 1
fi

# Crear enlaces simbolicos
ln -sf "$INSTALL_DIR/menu" /usr/bin/omux 2>/dev/null
ln -sf "$INSTALL_DIR/menu" /usr/bin/menu 2>/dev/null

msg -bar
print_center "INSTALACION COMPLETADA"
msg -bar
print_center "Dropbear/SSH Manager instalado."
print_center "Archivos en: $INSTALL_DIR"
print_center "Ejecute 'menu' o 'omux' para iniciar."
msg -bar
