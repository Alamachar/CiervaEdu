Manual de Instalación de CiervaEdu
======================================

Este manual te guiará a través del proceso de instalación del sistema operativo CiervaEdu. Sigue los pasos detallados a continuación para completar la instalación correctamente.

Añadir Repositorios
-------------------

    add-apt-repository --yes main
    add-apt-repository --yes restricted
    add-apt-repository --yes universe
    add-apt-repository --yes multiverse
    apt update
    apt upgrade -y
    

Instalar Software
-----------------
    apt purge snapd
    apt install -y figlet transmission remmina arduino virtualbox rpi-imager flatpak virt-manager openshot-qt inkscape gimp blender nmap curl libreoffice tree neofetch screen software-properties-common apt-transport-https wget htop bpytop cbonsai net-tools ubuntu-restricted-extras unzip lolcat git whois ssh sshpass gnome-software-plugin-flatpak
    

Instalar Flatpak
----------------

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    apt update
    flatpak install -y flathub gitlab.YaLTeR.VideoTrimmer flathub app.drey.Warp flathub com.github.finefindus.eyedropper flathub org.gaphor.Gaphor flathub gitlab.somas.Apostrophe flathub io.gitlab.adhami3310.Converter flathub io.gitlab.adhami3310.Impression com.github.maoschanz.drawing flathub com.mattjakeman.ExtensionManager flathub org.gnome.gitlab.somas.Apostrophe.Plugin.TexLive flathub io.dbeaver.DBeaverCommunity flathub org.chromium.Chromium flathub org.mozilla.firefox
    

Instalar Software dpkg
----------------------

INSTALAR VMWARE

    wget -O /tmp/vmware.bundle https://download3.vmware.com/software/WKST-PLAYER-1750/VMware-Player-Full-17.5.0-22583795.x86_64.bundle
    chmod +x /tmp/vmware.bundle
    sh /tmp/vmware.bundle
    apt update
    apt install -y build-essential gcc make linux-headers-$(uname -r)
    rm /tmp/*
INSTALAR GOOGLE CHROME

    wget -P /tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb
    rm /tmp/*
INSTALAR MICROSOFT EDGE

    wget -P /tmp https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_121.0.2277.113-1_amd64.deb
    dpkg -i /tmp/microsoft-edge-stable_121.0.2277.113-1_amd64.deb
    rm /tmp/*
INSTALAR ONLYOFFICE

    wget -P /tmp https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
    dpkg -i /tmp/onlyoffice-desktopeditors_amd64.deb
    rm /tmp/*
INSTALAR VISUAL ESTUDIO CODE
    
    wget -P /tmp https://vscode.download.prss.microsoft.com/dbazure/download/stable/31c37ee8f63491495ac49e43b8544550fbae4533/code_1.86.1-1707298119_amd64.deb
    dpkg -i /tmp/code_1.86.1-1707298119_amd64.deb
    rm /tmp/*
INSTALAR CISCO PACKET TRACER

    wget -P /tmp <enlace de descarga>
    dpkg -i /tmp/CPT.deb
    apt install -f -y
    rm /tmp/*

    

Establecer Chrome como Navegador Predeterminado
-----------------------------------------------

    update-alternatives --set x-www-browser /usr/bin/google-chrome-stable
    update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable
    

Configurar Fondos
-----------------

    mkdir /usr/share/backgrounds/ciervaedu

    

Configurar Entorno Gráfico
--------------------------

    mkdir /etc/dconf/db/ciervaedu.d
    touch /etc/dconf/db/ciervaedu.d/ciervaedu-settings

Configurar bashrc
-----------------

    # Añadir "figlet CiervaEdu | lolcat" en /etc/skel/.bashrc
    

Descargar Extensiones
---------------------

    # Descargar y configurar varias extensiones de GNOME Shell
    

Configurar Imagen Splash
------------------------

    rm /usr/share/plymouth/ubuntu-logo.png
    wget -P /usr/share/plymouth/ https://ciervaedu.duckdns.org/resources/plymouth/ubuntu-logo.png
    

Info Release
------------

    # Mostrar información de release
    

Slider del Instalador
---------------------

    # Mover la carpeta ubiquity a /usr/share/ubiquity-slideshow/sliides
    

Comandos Personalizados
-----------------------

    # Mover archivos a /usr/bin y /usr/sbin para los de administración
    # Dar permisos 755
    

¡Felicidades! Has completado la instalación de CiervaEdu. Ahora puedes disfrutar de tu nuevo sistema operativo.