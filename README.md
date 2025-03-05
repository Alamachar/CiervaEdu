
# Repositorio oficial
![alt text](CiervaEduLogo.png)

Visita la pagina en [CiervaEdu Web](https://ciervaedu.pablomp.es)
# Manual de Instalación de CiervaEdu

Este manual te guiará a través del proceso de configuracion de CiervaEdu. Sigue los pasos detallados a continuación para completar la instalación correctamente.

Se recomienda realizar las acciones como usuario root

Actualicacion inicial
-------------------

    apt update
    apt upgrade -y
    

Desinstalar snap
-----------------

Quitar todos los paquetes snap

    snap remove --purge paquete-snap
    apt purge snapd

Software general
-----------------

    apt install -y figlet transmission remmina arduino virtualbox rpi-imager flatpak virt-manager openshot-qt inkscape gimp blender nmap curl libreoffice tree neofetch screen software-properties-common apt-transport-https wget htop bpytop cbonsai net-tools ubuntu-restricted-extras unzip lolcat git whois ssh sshpass gnome-software-plugin-flatpak
    

Flatpak
----------------

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    apt update
    flatpak install -y flathub gitlab.YaLTeR.VideoTrimmer flathub app.drey.Warp flathub com.github.finefindus.eyedropper flathub org.gaphor.Gaphor flathub gitlab.somas.Apostrophe flathub io.gitlab.adhami3310.Converter flathub io.gitlab.adhami3310.Impression com.github.maoschanz.drawing flathub com.mattjakeman.ExtensionManager flathub org.gnome.gitlab.somas.Apostrophe.Plugin.TexLive flathub io.dbeaver.DBeaverCommunity flathub org.chromium.Chromium flathub org.mozilla.firefox
    

# Software dpkg

## Instalar VMware

Descargar e instalar manualmente el paquete de Vmware

    
    #Instalar dependencias
    apt update
    apt install -y build-essential gcc make linux-headers-$(uname -r)
    
## Instalar Google Chrome

Descargar desde la pagina oficial


    dpkg -i paquete.deb

## Instalar Microsoft Edge

Descargar desde la pagina oficial


    dpkg -i paquete.deb
    
## Instalar ONLYOFFICE

Descargar desde la pagina oficial

    dpkg -i paquete.deb

## Instalar Visual Studio Code
    
Descargar desde la pagina oficial

    dpkg -i paquete.deb

## Instalar Cisco Packet Tracer

Descargar desde la pagina oficial

    dpkg -i paquete.deb
    apt install -f -y
    apt update
    apt upgrade -y

    

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
    touch /etc/dconf/profile/user
Contenido de [ciervaedu-settings](ciervaedu-settings)

Contenido de [dconf-profile](dconf-profile)

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
