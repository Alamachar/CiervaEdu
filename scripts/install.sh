#!/bin/bash
#
# ██████╗  █████╗ ██████╗ ██╗      ██████╗ ███╗   ███╗██████╗  
# ██╔══██╗██╔══██╗██╔══██╗██║     ██╔═══██╗████╗ ████║██╔══██╗ 
# ██████╔╝███████║██████╔╝██║     ██║   ██║██╔████╔██║██████╔╝ 
# ██╔═══╝ ██╔══██║██╔══██╗██║     ██║   ██║██║╚██╔╝██║██╔═══╝  
# ██║     ██║  ██║██████╔╝███████╗╚██████╔╝██║ ╚═╝ ██║██║      
# ╚═╝     ╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝      
#
#   Script de instalacion de CiervaEdu.
#   Author: Alamachar
#   url: https://github.com/alamachar
#   Version: CLI


# Si algo falla para el script
set -euo pipefail

# --- Logging Function ---
log_message() {
    local type="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Colores ANSI
    local COLOR_RESET="\e[0m"
    local COLOR_INFO="\e[32m"    # Verde
    local COLOR_WARN="\e[33m"    # Amarillo
    local COLOR_ERROR="\e[31m"   # Rojo
    local COLOR_DEBUG="\e[34m"   # Azul

    case "$type" in
        INFO)
            echo -e "${COLOR_INFO}[$timestamp] [INFO] $message${COLOR_RESET}" >&2
            ;;
        WARN)
            echo -e "${COLOR_WARN}[$timestamp] [WARN] $message${COLOR_RESET}" >&2
            ;;
        ERROR)
            echo -e "${COLOR_ERROR}[$timestamp] [ERROR] $message${COLOR_RESET}" >&2
            ;;
        *)
            echo -e "${COLOR_DEBUG}[$timestamp] [DEBUG] $message${COLOR_RESET}" >&2
            ;;
    esac
}

# --- Verificar usuario ---
if [ "$EUID" -ne 0 ]; then
    log_message ERROR "Por favor, ejecuta este script como root o con sudo."
    exit 1
fi

# --- Manejo de errores ---
handle_error() {
    local exit_code=$?
    local cmd="$BASH_COMMAND" # Comando que fallo
    log_message ERROR "El comando '$cmd' (código de salida: $exit_code) falló."
    log_message ERROR "Saliendo del script debido a un error crítico."
    exit "$exit_code"
         
   
}

# Si hay error llama a la funcion de manejar errores
trap 'handle_error' ERR

confirmar_accion() {
    local mensaje="$1"
    local respuesta

    while true; do
        read -p "$mensaje (S/n): " respuesta
        if [[ -z "$respuesta" || "$respuesta" =~ ^[sS]$ ]]; then
            return 0  # Sí
        elif [[ "$respuesta" =~ ^[nN]$ ]]; then
            return 1  # No
        else
            echo "Por favor, responde con 's', 'n' o presiona Enter para aceptar por defecto (sí)."
        fi
    done
}


# --- Funcion que maneja el preguntar al usuario si quiere descargar 
#     el recurso de la fuente dada por el script o si quiere usar su archivo ---
download_or_copy() {
    local base_filename="$1"
    local remote_url="$2"
    local local_dir="$3"
    local prompt_msg="$4"

    local default_path="$local_dir/$base_filename"
    local user_input=""

    read -p "$prompt_msg (dejar en blanco para descargar de la web, o introduce una ruta local completa del archivo): " user_input

    if [ -n "$user_input" ]; then
        if [ -f "$user_input" ]; then
            log_message INFO "Copiando archivo local: $user_input a $default_path"
            sudo cp "$user_input" "$default_path"
            if [ $? -eq 0 ]; then
                echo "$default_path"
                return 0
            else
                log_message ERROR "Fallo al copiar el archivo local: $user_input"
                return 1
            fi
        else
            log_message ERROR "El archivo local especificado no existe: $user_input"
            return 1
        fi
    else
        log_message INFO "Descargando $base_filename de la web desde: $remote_url..."
        sudo wget -q --show-progress -O "$default_path" "$remote_url"
        if [ $? -eq 0 ]; then
            echo "$default_path"
            return 0
        else
            log_message ERROR "Fallo al descargar el archivo: $remote_url"
            return 1
        fi
    fi
}

# --- Directorios dinamicos ---
#Asume que el script esta en la carpeta script en relacion a la raiz del proyecto
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directorios generales
readonly DIR_BIN="${SCRIPT_DIR}/bin"
readonly DIR_DCONF="${SCRIPT_DIR}/dconf"
readonly DIR_EXTENSIONS="${SCRIPT_DIR}/extensiones"
readonly DIR_PLYMOUTH="${SCRIPT_DIR}/plymouth"
readonly DIR_SCRIPTS="${SCRIPT_DIR}/scripts"
readonly DIR_SBIN="${SCRIPT_DIR}/sbin"
readonly DIR_USERCONFIG="${SCRIPT_DIR}/userconfig"
readonly DIR_WALLPAPERS="${SCRIPT_DIR}/wallpapers"
readonly DIR_CIERVAEDU="${SCRIPT_DIR}/ciervaedu" # Directorio de aplicaciones

# Directorios de aplicaciones
readonly DIR_DOCADM="${DIR_CIERVAEDU}/dockeradmin"
readonly DIR_LWP="${DIR_CIERVAEDU}/localwebpage"
readonly DIR_WEBAPP_MANAGER="${DIR_CIERVAEDU}/webapp-manager"
readonly DIR_WEB_FILEBROWSER="${DIR_CIERVAEDU}/web-filebrowser"
readonly DIR_WALLPAPERAPP="${DIR_CIERVAEDU}/wallpaperapp"

# --- Verificacion de la estructura ---
check_directories() {
    log_message INFO "Verificando estructura de directorios..."
    local required_dirs=(
        "${DIR_BIN}"
        "${DIR_DCONF}"
        "${DIR_EXTENSIONS}"
        "${DIR_PLYMOUTH}"
        "${DIR_SCRIPTS}"
        "${DIR_SBIN}"
        "${DIR_USERCONFIG}"
        "${DIR_WALLPAPERS}"
        "${DIR_LWP}"
        "${DIR_WEBAPP_MANAGER}"
        "${DIR_WEB_FILEBROWSER}"
        "${DIR_WALLPAPERAPP}"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_message ERROR "Directorio requerido no encontrado: $dir"
            log_message ERROR "Asegúrate de que el script se ejecuta desde la carpeta 'scripts/' y que la estructura del proyecto es correcta."
            exit 1
        fi
    done
    log_message INFO "Estructura de directorios verificada correctamente."
}

# --- Mostrar rutas (debug) ---
show_paths() {
    echo "================================================================"
    log_message DEBUG "Rutas configuradas:"
    log_message DEBUG " - Directorio raíz del proyecto: ${SCRIPT_DIR}"
    log_message DEBUG " - Directorio de scripts:        ${DIR_SCRIPTS}"
    log_message DEBUG " - Directorio Plymouth:          ${DIR_PLYMOUTH}"
    log_message DEBUG " - Directorio bin:               ${DIR_BIN}"
    log_message DEBUG " - Directorio wallpapers:        ${DIR_WALLPAPERS}"
    log_message DEBUG " - Directorio de extensiones:    ${DIR_EXTENSIONS}"
    log_message DEBUG " - Directorio de configuración de usuario: ${DIR_USERCONFIG}"
    log_message DEBUG " - Directorio local webpage:     ${DIR_LWP}"
    log_message DEBUG " - Directorio webapp manager:    ${DIR_WEBAPP_MANAGER}"
    log_message DEBUG " - Directorio web filebrowser:   ${DIR_WEB_FILEBROWSER}"
    log_message DEBUG " - Directorio wallpaper app:     ${DIR_WALLPAPERAPP}"
    echo "================================================================"
}

# =================================================================
# Principal
# =================================================================

log_message INFO "Iniciando script de instalación..."

# Comprobaciones
check_directories
show_paths

# --- Mensaje ---
echo "================================================================"
log_message INFO "Bienvenido al instalador de CiervaEdu"
echo "================================================================"

if confirmar_accion "¿Deseas instalar CiervaEdu?"; then
    # --- Instalacion ---
    echo "================================================================"
    log_message INFO "INSTALACIÓN DE DEPENDENCIAS BÁSICAS"
    echo "================================================================"
    
    log_message INFO "Eliminando gnome-initial-setup (si existe)..."
    sudo apt remove --autoremove -y gnome-initial-setup || true # '|| true' impide que cierre el sript si no esta instalado

    log_message INFO "Actualizando listas de paquetes e instalando herramientas esenciales..."
    sudo apt update
    sudo apt install -y curl wget gpg ca-certificates software-properties-common apt-transport-https htop bpytop cbonsai net-tools lolcat tree unzip figlet screen git whois ssh sshpass
    log_message INFO "Instalando PHP CLI (si no está ya instalado)..."
    sudo apt install -y php-cli php8.3 php8.3-dev libpam0g-dev

    if ! php -m | grep -qi "^pam$"; then
    if pecl list | grep -q "^pam\s"; then
        log_message INFO "La extensión PAM ya está instalada por PECL, pero no está cargada en PHP."
    else
        log_message INFO "Instalando extensión PAM con PECL..."
        install_output=$(sudo pecl install -n pam 2>&1)
        install_code=$?

        if [[ $install_output == *"is already installed"* ]]; then
            log_message INFO "PECL reporta que 'pam' ya está instalada. Continuando..."
        elif [[ $install_code -ne 0 ]]; then
            log_message ERROR "El comando 'sudo pecl install pam' falló (código de salida: $install_code)."
            log_message ERROR "Salida: $install_output"
            exit 1
        else
            log_message INFO "Extensión PAM instalada correctamente."
        fi
    fi
    else
        log_message INFO "La extensión PAM ya está cargada. Omitiendo instalación."
    fi



    log_message INFO "Instalando paquetes de escritorio y desarrollo..."
    sudo apt install -y virt-manager filezilla libreoffice qbittorrent remmina blender gimp openshot-qt arduino inkscape rpi-imager virtualbox ubuntu-restricted-extras flameshot dos2unix ranger tmux fzf libfuse2 lsd bat vim rabbitvcs-core rabbitvcs-cli rabbitvcs-nautilus
    
    #log_message INFO "Instalando Gestor de extensiones"
    #sudo apt install -y gnome-shell-extension-manager

    log_message INFO "Dependencias básicas instaladas."


# --- Flatpak ---
echo "================================================================"
log_message INFO "FLATPAK"
echo "================================================================"

    log_message INFO "Instalando Flatpak..."
    sudo apt install -y flatpak

    log_message INFO "Añadiendo el repositorio Flathub..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    log_message INFO "Instalando aplicaciones Flatpak (esto puede tardar)..."
    sudo flatpak install -y flathub \
        io.dbeaver.DBeaverCommunity \
        org.gnome.gitlab.YaLTeR.VideoTrimmer \
        app.drey.Warp \
        com.github.finefindus.eyedropper \
        org.gaphor.Gaphor \
        io.gitlab.adhami3310.Impression \
        com.github.PintaProject.Pinta \
        io.missioncenter.MissionCenter \
        io.github.ronniedroid.concessio \
        com.github.unrud.VideoDownloader \
        re.sonny.Playhouse \
        app.drey.Blurble \
        fr.romainvigier.MetadataCleaner \
        app.drey.Dialect \
        io.github.nokse22.Exhibit
    log_message INFO "Aplicaciones Flatpak instaladas."


# --- Docker Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE DOCKER"
echo "================================================================"

    log_message INFO "Añadiendo la clave GPG oficial de Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    log_message INFO "Añadiendo el repositorio de Docker a las fuentes de Apt..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log_message INFO "Actualizando listas de paquetes e instalando Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    log_message INFO "Docker instalado."


# --- Snap Removal ---
echo "================================================================"
log_message INFO "ELIMINACIÓN DE SNAP"
echo "================================================================"

log_message INFO "Verificando si Snap está instalado..."
if ! command -v snap &> /dev/null; then
    log_message INFO "Snap no parece estar instalado. Omitiendo eliminación."
else
    log_message INFO "Listando y eliminando todos los paquetes Snap instalados (esto puede tomar tiempo)..."
    sudo systemctl is-active --quiet snapd.service || sudo systemctl start snapd.service || true

    snap list | awk 'NR>1 {print $1}' | while read -r pkg; do
        if [ -n "$pkg" ]; then
            log_message INFO "Eliminando paquete Snap: $pkg"
            sudo snap remove --purge "$pkg" || true
        fi
    done

    log_message INFO "Deteniendo y deshabilitando servicios de Snap..."
    sudo systemctl stop snapd.service snapd.socket || true
    sudo systemctl disable snapd.service snapd.socket || true

    log_message INFO "Desinstalando Snap completamente..."
    sudo apt purge -y snapd || true

    log_message INFO "Eliminando archivos residuales de Snap..."
    sudo rm -rf /var/snap || true
    sudo rm -rf /snap || true
    sudo rm -rf ~/snap || true

    log_message INFO "Bloqueando Snap en APT para prevenir futuras instalaciones..."
    echo "Package: snapd
Pin: release a=*
Pin-Priority: -1" | sudo tee /etc/apt/preferences.d/no-snap.pref > /dev/null

    log_message INFO "Bloqueando instalación con apt-mark..."
    sudo apt-mark hold snapd || true

    log_message INFO "Previniendo promoción de snaps en Ubuntu..."
    echo 'APT::Get::Snap::Allowed "false";' | sudo tee /etc/apt/apt.conf.d/no-snap > /dev/null

    log_message INFO "Actualizando listas de paquetes después de eliminar Snap..."
    sudo apt update -y

    log_message INFO "Snap y todos sus componentes han sido eliminados."
    log_message INFO "La instalación de Snap ha sido bloqueada permanentemente."
fi



# --- Firefox Installation (from Mozilla APT repository) ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE FIREFOX"
echo "================================================================"

    log_message INFO "Configurando repositorio de Mozilla Firefox..."
    sudo install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

    log_message INFO "Estableciendo la preferencia para Firefox desde el repositorio de Mozilla..."
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null

    log_message INFO "Actualizando listas de paquetes y eliminando la versión existente de Firefox (si es Snap)..."
    sudo apt update

    log_message INFO "Instalando Firefox y el paquete de idioma español..."
    sudo apt install -y firefox firefox-l10n-es-es
    log_message INFO "Firefox instalado y configurado como navegador por defecto."
    sudo update-alternatives --set x-www-browser /usr/bin/firefox
    sudo update-alternatives --set gnome-www-browser /usr/bin/firefox


# --- Fastfetch Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE FASTFETCH"
echo "================================================================"

# Crear directorio temporal
log_message INFO "Creando directorio temporal para Fastfetch..."
mkdir -p /tmp/fastfetch

# Obtener URL del último release
FASTFETCH_URL="https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest"
FASTFETCH_DEB_URL=""
FASTFETCH_DOWNLOADED_NAME=""

log_message INFO "Obteniendo la última URL de descarga de Fastfetch..."

# Usar jq si está disponible para parsear JSON, o grep como fallback
if command -v jq >/dev/null 2>&1; then
    FASTFETCH_DEB_URL=$(curl -s "$FASTFETCH_URL" | jq -r '.assets[] | select(.name | contains("linux-amd64.deb")) | .browser_download_url' | head -n 1)
else
    FASTFETCH_DEB_URL=$(curl -s "$FASTFETCH_URL" | grep -Eo 'https://[^"]+fastfetch[^"]+-linux-amd64\.deb' | head -n 1)
fi

if [[ -n "$FASTFETCH_DEB_URL" ]]; then
    FASTFETCH_DOWNLOADED_NAME=$(basename "$FASTFETCH_DEB_URL")
    log_message INFO "URL de descarga de Fastfetch obtenida: $FASTFETCH_DEB_URL"
else
    log_message ERROR "No se pudo obtener la URL de descarga de Fastfetch. Omitiendo instalación."
    exit 1
fi

# Descargar e instalar
if [[ -n "$FASTFETCH_DEB_URL" ]]; then
    log_message INFO "Descargando Fastfetch..."
    if wget -q "$FASTFETCH_DEB_URL" -O "/tmp/fastfetch/$FASTFETCH_DOWNLOADED_NAME"; then
        log_message INFO "Instalando fastfetch..."
        sudo dpkg -i "/tmp/fastfetch/$FASTFETCH_DOWNLOADED_NAME"
        sudo apt-get install -f -y
        log_message INFO "Fastfetch instalado correctamente."
    else
        log_message ERROR "No se pudo descargar Fastfetch."
        exit 1
    fi
fi



# --- Microsoft Edge Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE MICROSOFT EDGE"
echo "================================================================"

    log_message INFO "Añadiendo clave GPG de Microsoft Edge..."
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo rm microsoft.gpg

    log_message INFO "Añadiendo repositorio de Microsoft Edge..."
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-stable.list' # Changed to stable.list

    log_message INFO "Actualizando listas de paquetes e instalando Microsoft Edge..."
    sudo apt update
    sudo apt install -y microsoft-edge-stable
    log_message INFO "Microsoft Edge instalado."


# --- Visual Studio Code Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE VISUAL STUDIO CODE"
echo "================================================================"

    log_message INFO "Añadiendo clave GPG de Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo rm -f packages.microsoft.gpg

    log_message INFO "Añadiendo repositorio de Visual Studio Code..."
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    log_message INFO "Actualizando listas de paquetes e instalando Visual Studio Code..."

    sudo rm /etc/apt/sources.list.d/microsoft-edge-stable.list

    sudo apt update
    sudo apt install -y code # or code-insiders
    log_message INFO "Visual Studio Code instalado."


# --- Google Chrome Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE GOOGLE CHROME"
echo "================================================================"

    log_message INFO "Añadiendo clave GPG de Google Chrome..."
    curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >> /dev/null
    
    log_message INFO "Añadiendo repositorio de Google Chrome..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    
    log_message INFO "Actualizando listas de paquetes e instalando Google Chrome..."
    sudo apt update
    sudo apt install -y google-chrome-stable
    log_message INFO "Google Chrome instalado."

# --- Starship Prompt Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE STARSHIP PROMPT"
echo "================================================================"

    log_message INFO "Descargando e instalando Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y # -y for non-interactive install
    log_message INFO "Starship instalado."


# --- Cisco Packet Tracer Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE CISCO PACKET TRACER"
echo "================================================================"


    log_message INFO "Creando directorio temporal para Cisco Packet Tracer..."
    mkdir -p /tmp/cisco

    log_message INFO "Descargando instaladores de Cisco Packet Tracer y dependencias..."
    # Definir nombre de los archivos en las URL
    CiscoPT_FILE="CiscoPacketTracer822_amd64_signed.deb"
    libegl1_FILE="libegl1-mesa_23.0.4-0ubuntu1.22.04.1_amd64.deb"
    libgl1_FILE="libgl1-mesa-glx_23.0.4-0ubuntu1.22.04.1_amd64.deb"

    log_message INFO "Obteniendo Cisco Packet Tracer installer..."
    if ! cisco_pt_path=$(download_or_copy "$CiscoPT_FILE" "https://resources.ciervaedu.pablomp.es/software/$CiscoPT_FILE" "/tmp/cisco" "Introduce la ruta para $CiscoPT_FILE"); then
        log_message ERROR "No se pudo obtener el instalador principal de Cisco Packet Tracer. Omitiendo instalación."
        rm -rf /tmp/cisco || true
        return 1
    fi

    log_message INFO "Obteniendo dependencia: $libegl1_FILE..."
    if ! libegl1_path=$(download_or_copy "$libegl1_FILE" "https://resources.ciervaedu.pablomp.es/software/$libegl1_FILE" "/tmp/cisco" "Introduce la ruta para $libegl1_FILE"); then
        log_message WARN "No se pudo obtener la dependencia $libegl1_FILE. La instalación de Packet Tracer podría enfrentar problemas."
    fi

    log_message INFO "Obteniendo dependencia: $libgl1_FILE..."
    if ! libgl1_path=$(download_or_copy "$libgl1_FILE" "https://resources.ciervaedu.pablomp.es/software/$libgl1_FILE" "/tmp/cisco" "Introduce la ruta para $libgl1_FILE"); then
        log_message WARN "No se pudo obtener la dependencia $libgl1_FILE. La instalación de Packet Tracer podría enfrentar problemas."
    fi

    log_message INFO "Instalando Cisco Packet Tracer y sus dependencias..."

    sudo apt install dialog libpthread-stubs0-dev libxau-dev libxcb-xinerama0-dev libxcb1-dev libxdmcp-dev x11proto-dev xorg-sgml-doctools -y
    sudo dpkg -i /tmp/cisco/*

    log_message INFO "Limpiando archivos temporales de Cisco Packet Tracer..."
    rm -rf /tmp/cisco || true

    log_message INFO "Instalación de Cisco Packet Tracer finalizada."


# --- Docker Admin Configuration ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN DE CIERVAEDU-DOCKER"
echo "================================================================"


    # Variables
    DATA_DIR="/var/lib/ciervaedu-docker"
    SOCKET="/var/run/ciervaedu-docker.sock"
    PIDFILE="/var/run/ciervaedu-docker.pid"
    SERVICE_FILE="/etc/systemd/system/ciervaedu-docker.service"
    DOCKERD_BIN="/usr/bin/dockerd"
    DOCKER_GROUP="root"

    log_message INFO "Creando directorio de datos en $DATA_DIR..."
    sudo mkdir -p "$DATA_DIR"
    sudo chown root:root "$DATA_DIR"
    sudo chmod 755 "$DATA_DIR"

    log_message INFO "Creando servicio systemd para ciervaedu-docker..."
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine Admin
After=network.target

[Service]
Type=notify
ExecStart=$DOCKERD_BIN -H unix://$SOCKET --data-root $DATA_DIR --pidfile $PIDFILE --group $DOCKER_GROUP
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    log_message INFO "Recargando configuración de systemd..."
    sudo systemctl daemon-reload

    log_message INFO "Iniciando servicio ciervaedu-docker..."
    sudo systemctl start ciervaedu-docker.service

    log_message INFO "Habilitando servicio para inicio automático..."
    sudo systemctl enable ciervaedu-docker.service

    log_message INFO "Creando comando 'dockeradmin' (para administrar la instancia aislada)..."
    sudo tee "/usr/local/bin/ciervaedu-docker" > /dev/null <<EOF
#!/bin/bash
DOCKER_HOST=unix://$SOCKET /usr/bin/docker "\$@"
EOF
    sudo chmod +x "/usr/local/bin/ciervaedu-docker"

    log_message INFO "Listo. La instancia 'ciervaedu-docker' está en funcionamiento."
    log_message INFO "Para administrar esta instancia usa: ciervaedu-docker ps -a"
    
    sudo mkdir -p /opt/ciervaedu/ciervaedu-docker/
    sudo cp -r "${DIR_DOCADM}/"* "/opt/ciervaedu/ciervaedu-docker/"

    log_message INFO "Iniciando contenedores del sistema."

    sudo ciervaedu-docker compose -f "/opt/ciervaedu/ciervaedu-docker/convertx/docker-compose.yml" up -d

# --- Wallpaper Application Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE APLICACIÓN DE FONDO DE PANTALLA"
echo "================================================================"

    log_message INFO "Creando directorio de instalación para wallpaperapp."

    sudo mkdir -p /opt/ciervaedu/wallpaperapp

    log_message INFO "Instalando dependencias"
    sudo apt install -y python3-gi python3-gi-cairo

    log_message INFO "Copiando archivos de la aplicación."
    sudo cp "${DIR_WALLPAPERAPP}/main.py" "/opt/ciervaedu/wallpaperapp/main.py"
    sudo cp "${DIR_WALLPAPERAPP}/icon.png" "/opt/ciervaedu/wallpaperapp/icon.png"

    log_message INFO "Creando el lanzador de la aplicación."
    sudo cat > "/usr/share/applications/wallpaperapp.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Fondos
Exec=python3 /opt/ciervaedu/wallpaperapp/main.py
Comment=Cambiar fondo y tema
Icon=/opt/ciervaedu/wallpaperapp/icon.png
Terminal=false
StartupNotify=true
StartupWMClass=wallpaperapp
Categories=Utility;GTK;System;Settings;
Keywords=wallpaper;background;theme;desktop;
EOF

    
    sudo chmod 644 "/usr/share/applications/wallpaperapp.desktop"

    log_message INFO "Actualizando base de datos de aplicaciones."
    sudo update-desktop-database /usr/share/applications/

    log_message INFO "Copiando imágenes de fondo de pantalla."
    sudo mkdir -p "/usr/share/backgrounds/ciervaedu"
    sudo cp "${DIR_WALLPAPERS}/backgrounds/"* "/usr/share/backgrounds/ciervaedu/"

    sudo cp "${DIR_WALLPAPERS}/ciervaedu-wallpapers.xml" "/usr/share/gnome-background-properties/ciervaedu-wallpapers.xml"
    log_message INFO "Aplicación de fondo de pantalla y recursos relacionados instalados."
    
    
    log_message INFO "Copiando comandos personalizados."
    sudo chmod 755 "${DIR_BIN}/"* "${DIR_SBIN}/"* || true # Ensure executables are runnable
    sudo cp "${DIR_BIN}/"* "/usr/bin/" || true
    sudo cp "${DIR_SBIN}/"* "/usr/sbin/" || true

    


# --- Dconf and Extensions Setup (System-Wide) ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN GRAFICA"
echo "================================================================"

    log_message INFO "Creando directorio para la base de datos de dconf a nivel de sistema."
    sudo mkdir -p /etc/dconf/db/ciervaedu.d

    log_message INFO "Copiando configuración de dconf."
    sudo cp "${DIR_DCONF}/ciervaedu-settings" "/etc/dconf/db/ciervaedu.d/ciervaedu-settings"

    sudo cp "${DIR_DCONF}/dconf-profile" "/etc/dconf/profile/user"

    log_message INFO "Actualizando la base de datos de dconf.."
    sudo dconf update

    log_message INFO "Instalando extensiones de Gnome."
    TARGET_GNOME_EXT_DIR="/usr/share/gnome-shell/extensions"
    log_message INFO "Verificando si existe el directorio destino para extensiones: $TARGET_GNOME_EXT_DIR"
    if [ ! -d "$TARGET_GNOME_EXT_DIR" ]; then
        log_message ERROR "El directorio destino para extensiones de Gnome '$TARGET_GNOME_EXT_DIR' no existe. Las extensiones no se instalarán."
    else
        find "${DIR_EXTENSIONS}" -maxdepth 1 -type f -name "*.zip" | while read -r zip_file; do
            log_message INFO "Procesando extensión: $(basename "$zip_file")"
            
            TEMP_DIR=$(mktemp -d)
            if ! unzip -q "$zip_file" -d "$TEMP_DIR"; then
                log_message ERROR "Error al descomprimir: $zip_file. Saltando esta extensión."
                rm -rf "$TEMP_DIR"
                continue
            fi
            
            EXTENSION_DIR_CONTENT=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d)
            
            if [ -z "$EXTENSION_DIR_CONTENT" ]; then
                log_message ERROR "El ZIP no contiene un directorio válido en la raíz: $zip_file. Saltando esta extensión."
                rm -rf "$TEMP_DIR"
                continue
            fi
            
            EXTENSION_UUID=$(basename "$EXTENSION_DIR_CONTENT")
            FINAL_EXT_PATH="$TARGET_GNOME_EXT_DIR/$EXTENSION_UUID"
            
            log_message INFO "Copiando extensión '$EXTENSION_UUID' a '$FINAL_EXT_PATH'..."
            sudo cp -r "$EXTENSION_DIR_CONTENT" "$TARGET_GNOME_EXT_DIR/"
            
            log_message INFO "Aplicando permisos a la extensión instalada."
            sudo chmod -R 755 "$FINAL_EXT_PATH"
            
            log_message INFO "Limpiando directorio temporal: $TEMP_DIR"
            rm -rf "$TEMP_DIR"
            log_message INFO "Extensión '$EXTENSION_UUID' instalada correctamente."
        done
    fi
    log_message INFO "Configuración grafica completada."


# --- User Configuration Copy (via /etc/skel) ---
echo "================================================================"
log_message INFO "APLICANDO DE CONFIGURACIÓN DE USUARIOS"
echo "================================================================"

    SKEL_DIR="/etc/skel"
    log_message INFO "Configurando el directorio nuevos usuarios."

    log_message INFO "Copiando .bashrc para el usuario root."
    
    sudo cp "${DIR_USERCONFIG}/bashfiles/bashrc_root" "/root/.bashrc"

    log_message INFO "Configurando archivos .bashrc."
    # Ensure these files exist in DIR_USERCONFIG/bashfiles
    sudo cp "${DIR_USERCONFIG}/bashfiles/bashrc_visual" "$SKEL_DIR/.bashrc_visual"
    sudo cp "${DIR_USERCONFIG}/bashfiles/bashrc_simple" "$SKEL_DIR/.bashrc_simple"
    sudo cp "${DIR_USERCONFIG}/bashfiles/bashrc_starship" "$SKEL_DIR/.bashrc_starship"
    sudo cp "${DIR_USERCONFIG}/bashfiles/bashrc" "$SKEL_DIR/.bashrc" # Main .bashrc for new users

    echo "visual" | sudo tee "$SKEL_DIR/.bashrc_profile" > /dev/null

    log_message INFO "Estableciendo permisos adecuados para los archivos"
    sudo chmod 644 "$SKEL_DIR"/.bashrc*

    log_message INFO "Copiando ejemplos de contenedores de Docker."
    sudo cp -r "${DIR_USERCONFIG}/docker" "$SKEL_DIR/"

    log_message INFO "Creando directorios de plantillas."
    sudo mkdir -p "$SKEL_DIR/Plantillas"
    sudo cp "${DIR_USERCONFIG}/Plantillas/"* "$SKEL_DIR/Plantillas/"

    sudo chown -R root:root "$SKEL_DIR/Plantillas"
    sudo chmod -R 755 "$SKEL_DIR/Plantillas"

    log_message INFO "Copiando configuración de Flameshot."
    sudo mkdir -p "$SKEL_DIR/.config/flameshot"
    sudo cp "${DIR_USERCONFIG}/config/flameshot/flameshot.ini" "$SKEL_DIR/.config/flameshot/flameshot.ini"

    log_message INFO "Copiando configuración de Fastfetch."
    sudo mkdir -p "$SKEL_DIR/.config/fastfetch/"
    sudo cp "${DIR_USERCONFIG}/config/fastfetch/config.jsonc" "$SKEL_DIR/.config/fastfetch/config.jsonc"

    log_message INFO "Copiando configuración de Alacritty."
    sudo mkdir -p "$SKEL_DIR/.config/alacritty/"
    sudo cp "${DIR_USERCONFIG}/config/alacritty/alacritty.toml" "$SKEL_DIR/.config/alacritty/alacritty.toml"

    log_message INFO "Configuración de usuario para nuevos usuarios completada."


# --- Local Webpage Setup (Browser Homepage) ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN DE PÁGINA WEB LOCAL (PÁGINA DE INICIO DEL NAVEGADOR)"
echo "================================================================"

    log_message INFO "Copiando archivos de la página web local."

    sudo cp -r "${DIR_LWP}/"* "/var/www/html/"

    # URL de la pagina de inicio
    FILE_PATH="http://localhost"

    log_message INFO "Aplicando configuración de página de inicio para Mozilla Firefox."
    # ==================================================
    # 1. Configuración para Mozilla Firefox (Política del sistema)
    # ==================================================
    sudo mkdir -p /etc/firefox/policies
    sudo cat <<EOF > /etc/firefox/policies/policies.json
{
  "policies": {
    "Homepage": {
      "URL": "$FILE_PATH",
      "Locked": true,
      "StartPage": "home-page"
    },
    "ShowHomeButton": true,
    "Preferences": {
      "browser.startup.homepage": {
        "Value": "$FILE_PATH",
        "Status": "locked"
      }
    }
  }
}
EOF

    log_message INFO "Aplicando configuración de página de inicio para Google Chrome."
    # ==================================================
    # 2. Configuración para Google Chrome (Política del sistema)
    # ==================================================
    sudo mkdir -p /etc/opt/chrome/policies/managed
    sudo cat <<EOF > /etc/opt/chrome/policies/managed/policies.json
{
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": ["$FILE_PATH"],
  "HomepageLocation": "$FILE_PATH",
  "HomepageIsNewTabPage": false,
  "ShowHomeButton": true
}
EOF

    log_message INFO "Aplicando configuración de página de inicio para Microsoft Edge."
    # ==================================================
    # 3. Configuración para Microsoft Edge (Linux) (Política del sistema)
    # ==================================================
    # Note: Edge policies are managed in a similar way to Chrome.
    sudo mkdir -p /etc/opt/microsoft/edge/policies/managed # Correct path for Edge policies
    sudo cat <<EOF > /etc/opt/microsoft/edge/policies/managed/policies.json
{
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": ["$FILE_PATH"],
  "HomepageLocation": "$FILE_PATH",
  "HomepageIsNewTabPage": false,
  "ShowHomeButton": true
}
EOF

    # Esta parte se podria quitar
    log_message INFO "Aplicando configuración de página de inicio a perfiles de usuario existentes (Firefox, Chrome, Edge)."
    # ==================================================
    # 4. Configuración para usuarios existentes (Perfiles individuales)
    # ==================================================
    EDGE_PREFS='{
      "browser": {
        "show_home_button": true
      },
      "homepage": "'$FILE_PATH'",
      "session": {
        "restore_on_startup": 4,
        "startup_urls": ["'$FILE_PATH'"]
      },
      "homepage_is_newtabpage": false
    }'
# cambiar la configuracion de usuario que ejecuta el script
    find /home -maxdepth 1 -type d | while read USER_HOME; do
        if [ "$USER_HOME" != "/home" ] && [ -d "$USER_HOME" ] && id "$(basename "$USER_HOME")" &>/dev/null; then
            USER=$(basename "$USER_HOME")
            log_message INFO "  -> Configurando para el usuario: $USER"

            # Firefox - Perfil default
            mkdir -p "$USER_HOME/.mozilla/firefox/default"
            echo 'user_pref("browser.startup.homepage", "'$FILE_PATH'");' > "$USER_HOME/.mozilla/firefox/default/user.js"

            # Chrome
            mkdir -p "$USER_HOME/.config/google-chrome/Default"
            echo '{"startup_urls": ["'$FILE_PATH'"], "homepage_location": "'$FILE_PATH'", "homepage_is_newtabpage": false, "show_home_button": true}' > "$USER_HOME/.config/google-chrome/Default/Preferences"

            # Edge (solución definitiva)
            mkdir -p "$USER_HOME/.config/microsoft-edge/Default"
            echo "$EDGE_PREFS" > "$USER_HOME/.config/microsoft-edge/Default/Preferences"

            # Corregir permisos
            log_message INFO "  -> Corrigiendo permisos para $USER"
            sudo chown -R "$USER:$(id -gn $USER)" "$USER_HOME/.config" "$USER_HOME/.mozilla"
        fi
    done
    ########################

    log_message INFO "Configuración de página web local y de inicio del navegador completada."


# --- User and Group Setup for Services (New Section - Add this BEFORE Webapp Manager and Filebrowser Service definitions) ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN DE USUARIO Y GRUPO PARA SERVICIOS"
echo "================================================================"
    USER_SERVICE="ciervaedu-system"
    # grupo para bloquear apps

       # Verificar si el grupo 'appusers' existe
    if grep -q "^appusers:" /etc/group; then
        log_message INFO "El grupo 'appusers' ya existe. Continuando con el script..."
    else
    # Crear el grupo si no existe
    sudo groupadd appusers
    log_message INFO "El grupo 'appusers' ha sido creado."
    fi


log_message INFO "Asegurando que el usuario '$USER_SERVICE' y el grupo existen para los servicios."
if ! id -u $USER_SERVICE &>/dev/null; then
    sudo useradd -r -s /usr/sbin/nologin -M -G shadow $USER_SERVICE # Create system user, no home directory, no login shell
    
    log_message INFO "Usuario de sistema '$USER_SERVICE' creado."
else
    log_message INFO "Usuario '$USER_SERVICE' ya existe."
    sudo usermod -aG shadow $USER_SERVICE 
fi
if ! getent group $USER_SERVICE &>/dev/null; then # check if group exists
    sudo groupadd $USER_SERVICE # Create group if it doesn't exist
    log_message INFO "Grupo '$USER_SERVICE' creado."
else
    log_message INFO "Grupo '$USER_SERVICE' ya existe."
fi

# --- Webapp Manager Setup (as a Systemd Service) ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN DE GESTOR DE PAQUETES WEB"
echo "================================================================"

  

    PHP_VERSION=$(php -v | grep -oP '^PHP \K[0-9]+\.[0-9]+' | head -1)

    if [ -z "$PHP_VERSION" ]; then
        echo "No se encontró PHP instalado."
        exit 1
    fi

    echo "Versión de PHP detectada: $PHP_VERSION"

    # Crear el archivo de configuración de la extensión pam
    echo "extension=pam.so" | sudo tee "/etc/php/${PHP_VERSION}/mods-available/pam.ini" > /dev/null

    # Habilitar la extensión
    sudo phpenmod pam

    echo "Extensión pam habilitada para PHP $PHP_VERSION"

    # Crear archivo de configuración PAM
    sudo tee /etc/pam.d/php-auth << 'EOF'
auth sufficient pam_unix.so
account sufficient pam_unix.so
session optional pam_unix.so
EOF

    sudo tee /etc/sudoers.d/ciervaedu << EOF
# Permisos para gestión de paquetes
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt-get

# Comando específicos de APT
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt install *
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt remove *
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt update
$USER_SERVICE ALL=(ALL) NOPASSWD: /usr/bin/apt upgrade
EOF

    sudo chmod 0440 /etc/sudoers.d/ciervaedu
    # Verificar sintaxis
    sudo visudo -c

    # Crear grupo si no existe

    # Verificar si el grupo 'profesor' existe
    if grep -q "^profesor:" /etc/group; then
        log_message INFO "El grupo 'profesor' ya existe. Continuando con el script..."
    else
    # Crear el grupo si no existe
    sudo groupadd profesor
    log_message INFO "El grupo 'profesor' ha sido creado."
    fi

    sudo usermod -aG profesor $SUDO_USER 

    WEBAPP_MANAGER_PORT="2006"
    WEBAPP_MANAGER_APP_DIR="/opt/ciervaedu/packagemanager-webapp"

    log_message INFO "Creando directorio."
    sudo mkdir -p "$WEBAPP_MANAGER_APP_DIR/logs"

    log_message INFO "Copiando archivos."
    sudo cp -r "${DIR_WEBAPP_MANAGER}/"* "$WEBAPP_MANAGER_APP_DIR/"
    sudo chown -R $USER_SERVICE:$USER_SERVICE "$WEBAPP_MANAGER_APP_DIR" 
    sudo chmod -R 755 "$WEBAPP_MANAGER_APP_DIR" 
    log_message INFO "Creando archivo de servicio systemd."
    sudo cat > /etc/systemd/system/ciervaedu-packagemanager.service << EOF
[Unit]
Description=Gestor de Archivos WebApp
After=network.target

[Service]
Type=simple
User=$USER_SERVICE
Group=$USER_SERVICE
WorkingDirectory=$WEBAPP_MANAGER_APP_DIR
ExecStart=/usr/bin/php -S 0.0.0.0:$WEBAPP_MANAGER_PORT -t $WEBAPP_MANAGER_APP_DIR
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment=PHP_CLI_SERVER_WORKERS=4

[Install]
WantedBy=multi-user.target
EOF

    # Recargar systemd

    sudo systemctl daemon-reload

    log_message INFO "Habilitando e iniciando el servicio ciervaedu-packagemanager..."
    sudo systemctl enable ciervaedu-packagemanager.service
    sudo systemctl start ciervaedu-packagemanager.service

    log_message INFO "Webapp Manager configurado como servicio Systemd en el puerto $WEBAPP_MANAGER_PORT."
    log_message INFO "Puedes acceder a él en http://<IP_DE_TU_MAQUINA>:$WEBAPP_MANAGER_PORT"


# --- Web Filebrowser Setup (as a Systemd Service) ---
echo "================================================================"
log_message INFO "CONFIGURACIÓN DE NAVEGADOR DE ARCHIVOS WEB"
echo "================================================================="


    FILEBROWSER_PORT="2005"
    FILEBROWSER_APP_DIR="/opt/ciervaedu/filebrowser-webapp"

    log_message INFO "Creando directorio."
    sudo mkdir -p "$FILEBROWSER_APP_DIR"

    log_message INFO "Copiando archivos."
    sudo cp -r "${DIR_WEB_FILEBROWSER}/"* "$FILEBROWSER_APP_DIR/"
    sudo chown -R $USER_SERVICE:$USER_SERVICE "$FILEBROWSER_APP_DIR" # Assign ownership to web server user
    sudo chmod -R 755 "$FILEBROWSER_APP_DIR" # Ensure scripts are executable if needed

    log_message INFO "Creando archivo de servicio systemd."
    sudo cat > /etc/systemd/system/ciervaedu-filebrowser.service << EOF
[Unit]
Description=Gestor de Archivos WebApp
After=network.target

[Service]
Type=simple
User=$USER_SERVICE
Group=$USER_SERVICE
WorkingDirectory=$FILEBROWSER_APP_DIR
ExecStart=/usr/bin/php -S 0.0.0.0:$FILEBROWSER_PORT -t $FILEBROWSER_APP_DIR -c $FILEBROWSER_APP_DIR/php.ini
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

# Variables de entorno
Environment=PHP_CLI_SERVER_WORKERS=4

[Install]
WantedBy=multi-user.target
EOF

    log_message INFO "Recargando demonios de systemd..."
    sudo systemctl daemon-reload

    log_message INFO "Habilitando e iniciando el servicio ciervaedu-filebrowser..."
    sudo systemctl enable ciervaedu-filebrowser.service
    sudo systemctl start ciervaedu-filebrowser.service

    log_message INFO "Navegador de Archivos Web configurado como servicio Systemd en el puerto $FILEBROWSER_PORT."
    log_message INFO "Puedes acceder a él en http://<IP_DE_TU_MAQUINA>:$FILEBROWSER_PORT"

# --- NERDfonts ---
echo "================================================================"
log_message INFO "INSTALACIÓN NERDFONTS"
echo "================================================================"

# Instalar jq para procesar JSON de manera confiable (si no está instalado)
if ! command -v jq &> /dev/null; then
	sudo apt-get update && apt-get install -y jq
fi

# Obtener la URL de la última versión de AdwaitaMono.zip usando jq
LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.assets[] | select(.name=="AdwaitaMono.zip") | .browser_download_url')

if [ -z "$LATEST_RELEASE_URL" ]; then
	log_message ERROR "No se pudo obtener la URL de descarga." >&2
fi

# Directorio de destino para fuentes
FONT_DIR="/usr/share/fonts/truetype/AdwaitaMono-nerd"
mkdir -p "$FONT_DIR"

# Descargar la fuente
log_message INFO "Descargando AdwaitaMono Nerd Font..."
if ! wget -q --show-progress -P "$FONT_DIR" "$LATEST_RELEASE_URL"; then
	log_message ERROR "Error al descargar la fuente." >&2
fi

# Descomprimir y limpiar
cd "$FONT_DIR" || exit 1
unzip -q -o AdwaitaMono.zip
rm -f AdwaitaMono.zip LICENSE.txt README.md 2>/dev/null

# Actualizar caché de fuentes
log_message INFO "Actualizando caché de fuentes..."
fc-cache -fv

log_message INFO "¡Fuente AdwaitaMono Nerd Font instalada correctamente!"


# --- Plymouth Theme Installation ---
echo "================================================================"
log_message INFO "INSTALACIÓN DE TEMA PLYMOUTH"
echo "================================================================"
    
    log_message INFO "Copiando contenido"

    sudo cp ${DIR_PLYMOUTH}/ubuntu-logo.png /usr/share/plymouth/ubuntu-logo.png
    sudo cp ${DIR_PLYMOUTH}/watermark.png /usr/share/plymouth/themes/spinner/watermark.png 
    sudo cp ${DIR_PLYMOUTH}/bgrt-fallback.png /usr/share/plymouth/themes/spinner/bgrt-fallback.png    
    # cambio de nombre
    nuevo_nombre="CiervaEdu 2.0"
    sudo sed -i '/^PRETTY_NAME=/c\PRETTY_NAME="'"$nuevo_nombre"'"' /etc/os-release

    log_message INFO "Tema personalizado configurado."


# --- VMware Workstation Installation --- no funciona
echo "================================================================"
log_message INFO "INSTALACIÓN DE VMWARE WORKSTATION"
log_message WARN "ACTUALMENTE NO FUNCIONA"
log_message WARN "RECOMENDADO SALTAR"
echo "================================================================"
read -p "¿Deseas instalar VMware Workstation? (s/N): " confirm
if [[ "$confirm" =~ ^[sS]$ ]]; then
    log_message INFO "Creando directorio temporal para VMware..."
    mkdir -p /tmp/vmware

    VMWARE_BUNDLE_URL="https://resources.ciervaedu.pablomp.es/software/VMware-Workstation-Full-17.6.2-24409262.x86_64.bundle"
    VMWARE_BUNDLE_PATH=""

    if vmware_path=$(download_or_copy "VMware-Workstation.bundle" "$VMWARE_BUNDLE_URL" "/tmp/vmware" "Introduce la ruta para VMware-Workstation-Full-17.5.1-23298064.x86_64.bundle: "); then
        VMWARE_BUNDLE_PATH="$vmware_path"
        log_message INFO "Cambiando permisos del instalador de VMware..."
        sudo chmod +x "$VMWARE_BUNDLE_PATH"

        log_message INFO "Iniciando instalación de VMware Workstation (esto puede requerir interacción manual)..."
        # The installer is interactive. We run it, and the user will need to follow prompts.
        sudo "$VMWARE_BUNDLE_PATH"
    	log_message INFO "Instalando dependencias para copilar los modulos de kernel de VMware"
	    sudo apt install -y build-essential gcc make linux-headers-$(uname -r)
        
        log_message INFO "Compilando e instalando módulos del kernel de VMware..."
        sudo /usr/lib/vmware/bin/vmware-modconfig --console --install-all

        log_message INFO "Ejecutando asistente de configuración de VMware..."
        sudo /usr/lib/vmware/bin/vmware-setup-helper -e -o -u no -c -c no

        log_message INFO "VMware Workstation instalado."
    else
        log_message ERROR "No se pudo obtener el instalador de VMware. Omitiendo instalación de VMware Workstation."
    fi
else
    log_message INFO "Omitiendo instalación de VMware Workstation."
fi

echo "================================================================"
log_message INFO "CONFIGURANDO PERMISOS DE LA CARPETA CIERVAEDU"
echo "================================================================"

    sudo chmod -R 755 /opt/ciervaedu
    sudo chmod 750 /opt/ciervaedu/packagemanager-webapp/
    sudo chown -R ciervaedu-system:ciervaedu-system /opt/ciervaedu

echo "================================================================"
log_message INFO "CONFIGURANDO CAPA DE SEGURIDAD"
echo "================================================================"

    sudo chattr +i /etc/shadow
    sudo chattr +i /etc/passwd
    sudo chattr +i /etc/group
    sudo chattr +i /etc/sudoers

log_message INFO "Lea la documentacion para mas informacion"

# --- Final Cleanup ---
echo "================================================================"
log_message INFO "LIMPIEZA FINAL"
echo "================================================================"
if confirmar_accion "¿Deseas realizar una limpieza final del sistema?"; then

    log_message INFO "Realizando limpieza de paquetes..."
    sudo apt autoremove -y
    sudo apt autoclean

    log_message INFO "Eliminando archivos temporales de descarga..."
    sudo rm -rf /tmp/fastfetch.deb || true
    sudo rm -rf /tmp/vmware || true # This was /tmp/vmware, not a .deb
    sudo rm -rf /tmp/cisco || true  # This was /tmp/cisco, not a .deb
    log_message INFO "Limpieza completada."
else
    log_message INFO "Omitiendo limpieza final."
fi

log_message INFO "================================================================"
log_message INFO "¡SCRIPT DE INSTALACIÓN COMPLETADO!"
log_message INFO "================================================================"
log_message INFO "Es posible que necesites reiniciar tu sistema para que todos los cambios surtan efecto."
    if confirmar_accion "¿Deseas realizar reinicar ahora?"; then
        sudo reboot
    else
        log_message INFO "Es altamente recomendado reinicar"
    fi


else
    log_message INFO "Cancelando instalacion."
fi