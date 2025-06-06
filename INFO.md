# **Manual de Acceso y Configuración de CiervaEdu**

Este documento describe el uso y configuración de las siguientes herramientas en CiervaEdu:

1. **Acceso a Filebrowser (puerto 2005)**
2. **Acceso a AdminWeb (puerto 2006)**
3. **Acceso a ConvertX (puerto 3000)**
4. **Configuración de Flameshot para cada usuario**
5. **Incorporar usuarios al grupo `vboxusers` para VirtualBox**
6. **Explicación detallada del script `ciervaedu-appermisos`**

---

Todos los servicos tienen el prefijo ciervaedu-

## 1. Acceso a Filebrowser

Filebrowser es una interfaz web para gestionar archivos (navegar, subir y compartir).

**Cómo acceder**:

1. Ingresar en el navegador:
   ```
   http://<IP_DEL_EQUIPO>:2005
   ```
   Ejemplo: `http://192.168.1.100:2005`.

---

## 2. Acceso a AdminWeb

AdminWeb permite ejecutar comandos de sistema (como `apt install`, `apt update`, etc.) desde un navegador, sin necesidad de SSH.

**Cómo acceder**:

1. Abrir el navegador y dirigirse a:
   ```
   http://<IP_DEL_SERVIDOR>:2006
   ```
   Ejemplo: `http://192.168.1.100:2006`.
2. Iniciar sesión con las credenciales de un usuario perteneciente al grupo `profesores`.

**Funciones principales**:

- **Página principal**:
  - Botones para ejecutar `apt update` y `apt upgrade`.
  - Formulario para instalar, desinstalar o actualizar paquetes.
  - Sección para ejecutar comandos personalizados.

---

## 3. Acceso a ConvertX

ConvertX permite convertir formatos de archivos mediante una interfaz web.

**Cómo acceder**:

1. Ingresar en el navegador:
   ```
   http://<IP_DEL_SERVIDOR>:3000
   ```
   Ejemplo: `http://192.168.1.100:3000`.

---

## 4. Configuración de Flameshot para cada usuario

**Procedimiento**:

1. Abrir un terminal.
2. Ejecutar:

   ```bash
   flameshot gui
   ```

   - El sistema solicitará autorización para que Flameshot capture pantallas. Aceptar el permiso.

---

## 5. Añadir usuarios al grupo `vboxusers` (para VirtualBox)

**Contexto**:  
Los usuarios deben pertenecer al grupo `vboxusers` para:

- Acceder a dispositivos USB.
- Montar carpetas compartidas en VirtualBox.

**Cómo agregar un usuario**:

1. Ejecutar como _root_ o con `sudo`:
   ```bash
   sudo usermod -aG vboxusers <nombre_usuario>
   ```
   Ejemplo:
   ```bash
   sudo usermod -aG vboxusers juan
   ```

---

## 6. Explicación de `ciervaedu-appermisos`

**Funcionalidades por argumento**:

### **Opción 1**: Restringir ejecución de un comando

- Solicita:
  1. El comando a bloquear.
  2. El usuario a agregar al grupo `appusers`.
- **Efecto**: Solo usuarios en `appusers` podrán ejecutar el comando especificado.

### **Opción 2**: Agregar usuario al grupo `appusers`

- Permite añadir nuevos usuarios al grupo.

### **Opción 3**: Eliminar usuario del grupo `appusers`

- Muestra la lista de usuarios del grupo y permite removerlos.

---

## 7. Docker Aislado

**Descripción**:  
Instancia de Docker aislada diseñada para que los administradores puedan gestionar contenedores sin que los usuarios estándar tengan capacidad de modificarlos.

**Uso**:

- Ejecutar cualquier comando de Docker utilizando el prefijo `ciervaedu-docker`.

**Sintaxis**:

```bash
ciervaedu-docker [comando_de_docker] [opciones]
```

**Ejemplos**:

1. Listar contenedores en ejecución:
   ```bash
   ciervaedu-docker ps
   ```

**Características clave**:

- **Acceso restringido**: Solo usuarios con privilegios de administrador pueden utilizar `ciervaedu-docker`.
- **Aislamiento**: Los contenedores gestionados bajo esta instancia no son visibles/modificables por usuarios normales.

---

## 8. Gestión de Perfiles de Terminal

**Descripción**:  
Sistema que permite alternar entre diferentes configuraciones de terminal predefinidas, adaptándose a diversas necesidades de uso.

### **Perfiles Disponibles**

| Nombre     | Características                         |
| ---------- | --------------------------------------- |
| `simple`   | Configuración minimalista por defecto   |
| `visual`   | Interfaz mejorada con colores y aliases |
| `starship` | Prompt moderno con Starship             |

### **Uso Básico**

```bash
change_profile [nombre_perfil]  # Cambiar configuración
source ~/.bashrc               # Aplicar cambios
```

**Ejemplos**:

```bash
change_profile visual      # Activar perfil con herramientas gráficas
change_profile starship    # Usar prompt avanzado
change_profile simple      # Volver a configuración básica
```

> ℹ Para personalizar perfiles, edite los archivos correspondientes en su directorio home.

## **9. Gestión de Archivos Inmutables**

### **Descripción**
CiervaEdu protege automáticamente archivos críticos del sistema mediante el atributo de inmutabilidad, previniendo modificaciones no autorizadas.

### **Archivos Protegidos por Defecto**
- `/etc/shadow`
- `/etc/passwd`
- `/etc/group`
- `/etc/sudoers`

### **Herramientas de Gestión**
```bash
# Proteger archivos del sistema
sudo ciervaedu-seguro proteger

# Desproteger archivos temporalmente
sudo ciervaedu-seguro desproteger
```

### **Comandos Avanzados**
```bash
# Proteger/desproteger archivos específicos
sudo chattr +i /ruta/archivo  # Hacer inmutable
sudo chattr -i /ruta/archivo  # Quitar inmutabilidad

# Proteger carpetas recursivamente
sudo chattr -R +i /ruta/carpeta

# Verificar estado
lsattr /ruta/archivo
```

> **Importante**: La inmutabilidad es una medida de seguridad. Solo desproteja los archivos cuando sea estrictamente necesario y vuelva a protegerlos inmediatamente después de realizar los cambios.