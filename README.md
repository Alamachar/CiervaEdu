
# Repositorio oficial
![alt text](CiervaEduLogo.png)
Visita la pagina en [CiervaEdu Web](https://ciervaedu.duckdns.org)
# Manual de Instalación de CiervaEdu

Este manual te guiará a través del proceso de configuracion de CiervaEdu. Sigue los pasos detallados a continuación para completar la instalación correctamente.

Para poder seguir este manual es necerario disponer de un sistema linux que permita usar el software [Cubic](https://github.com/PJ-Singh-001/Cubic)

Para añadir archivos locales presionar el icono ![copyfile.png](copyfile.png)

Añadir Repositorios
-------------------

    add-apt-repository --yes main
    add-apt-repository --yes restricted
    add-apt-repository --yes universe
    add-apt-repository --yes multiverse
    apt update
    apt upgrade -y
    

Software general
-----------------
    apt purge snapd
    apt install -y figlet transmission remmina arduino virtualbox rpi-imager flatpak virt-manager openshot-qt inkscape gimp blender nmap curl libreoffice tree neofetch screen software-properties-common apt-transport-https wget htop bpytop cbonsai net-tools ubuntu-restricted-extras unzip lolcat git whois ssh sshpass gnome-software-plugin-flatpak
    

Flatpak
----------------

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    apt update
    flatpak install -y flathub gitlab.YaLTeR.VideoTrimmer flathub app.drey.Warp flathub com.github.finefindus.eyedropper flathub org.gaphor.Gaphor flathub gitlab.somas.Apostrophe flathub io.gitlab.adhami3310.Converter flathub io.gitlab.adhami3310.Impression com.github.maoschanz.drawing flathub com.mattjakeman.ExtensionManager flathub org.gnome.gitlab.somas.Apostrophe.Plugin.TexLive flathub io.dbeaver.DBeaverCommunity flathub org.chromium.Chromium flathub org.mozilla.firefox
    

Software dpkg
----------------------

Instalar VMware

    wget -O /tmp/vmware.bundle https://download3.vmware.com/software/WKST-PLAYER-1750/VMware-Player-Full-17.5.0-22583795.x86_64.bundle
    chmod +x /tmp/vmware.bundle
    sh /tmp/vmware.bundle
    apt update
    apt install -y build-essential gcc make linux-headers-$(uname -r)
    rm /tmp/*
Instalar Google Chrome

    wget -P /tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg -i /tmp/google-chrome-stable_current_amd64.deb
    rm /tmp/*
Instalar Microsoft Edge

    wget -P /tmp https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_121.0.2277.113-1_amd64.deb
    dpkg -i /tmp/microsoft-edge-stable_121.0.2277.113-1_amd64.deb
    rm /tmp/*
Instalar ONLYOFFICE

    wget -P /tmp https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
    dpkg -i /tmp/onlyoffice-desktopeditors_amd64.deb
    rm /tmp/*
Instalar Visual Studio Code
    
    wget -P /tmp https://vscode.download.prss.microsoft.com/dbazure/download/stable/31c37ee8f63491495ac49e43b8544550fbae4533/code_1.86.1-1707298119_amd64.deb
    dpkg -i /tmp/code_1.86.1-1707298119_amd64.deb
    rm /tmp/*
Instalar Cisco Packet Tracer

    wget -P /tmp <enlace de descarga>
    dpkg -i /tmp/CPT.deb
    apt install -f -y
    apt update
    apt upgrade -y
    rm /tmp/*

    

Establecer Chrome como Navegador Predeterminado
-----------------------------------------------

    update-alternatives --set x-www-browser /usr/bin/google-chrome-stable
    update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable
    

Configurar Fondos
-----------------
Crear la carpeta ``/usr/share/backgrounds/ciervaedu``

Mover los archivos [Wallpapers](Wallpapers) a la carpeta

Para que los fondos se muestren desde la aplicacion de configuracion crear ``/usr/share/gnome-background-properties/ciervaedu-wallpapers.xml``

Contenido de [ciervaedu-wallpapers.xml](ciervaedu-wallpapers.xml)

Configurar Entorno Gráfico
--------------------------
Crear la carpeta para almecenar la configuracion

    mkdir /etc/dconf/db/ciervaedu.d
    touch /etc/dconf/db/ciervaedu.d/ciervaedu-settings
Contenido de [ciervaedu-settings](ciervaedu-settings)

    echo "user-db:user 
    system-db:ciervaedu" /etc/dconf/profile/user
    dconf update

Configuracion del usuario
------------------------------------
Añadir en **/etc/skel/.bashrc**  ``figlet CiervaEdu | lolcat``

Crear la carpeta **.config/neofetch** y añadir [config.conf](config/neofetch/config.conf)

Extensiones
---------------------

Ir a la carpeta /usr/share/gnome-shell/extensions/ una vez ahi añadir las [Extensiones](Extensiones) descomprimidas y dar permisos 755 de manera recursiva ``chmod -R 755``


Configurar Imagen Splash
------------------------
Sustituir por las imagenes que se encuentran el el repositorio

    /usr/share/plymouth/ubuntu-logo.png

[ubuntu-logo.png](ubuntu-logo.png)

    /usr/share/plymouth/themes/spinner watermark.png bgrt-fallback.png   

[bgrt-fallback.png](bgrt-fallback.png)

[watermark.png](watermark.png)


Slider del Instalador
---------------------
Eliminar el contenido de ``/usr/share/ubiquity-slideshow/slides``  

Comandos Personalizados
-----------------------
[/usr/bin](bin) [/usr/sbin](sbin)

Mover archivos a ``/usr/bin`` y ``/usr/sbin``. Dar permisos 755 a los archivos

Crear el grupo para la restriccion de aplicaciones ``addgroup appusers``

**¡Felicidades!🎉** Has completado la instalación de CiervaEdu. Ahora puedes disfrutar de tu nuevo sistema operativo.