# **Manual de Instalación de CiervaEdu**

![Logo de CiervaEdu](CiervaEduLogo.png)  
**Sitio web oficial**: [CiervaEdu Web](https://ciervaedu.pablomp.es)

Este manual proporciona instrucciones detalladas para instalar y configurar CiervaEdu en tu sistema.

---

## **Requisitos previos**

- **ISO de Ubuntu 24.04 LTS** (descargar desde [ubuntu.com](https://ubuntu.com/download/desktop))
- Conexión a Internet estable
- Al menos **20 GB de espacio en disco**
- **8 GB de RAM** (recomendado 16 GB para mejor rendimiento)

---

## **Pasos de instalación**

### **1. Instalación básica de Ubuntu**

**Seleccionar "Instalación normal"** e **incluir software de terceros y controladores**.

### **2. Actualizar el sistema**

Tras la instalación, ejecuta:

```bash
sudo apt update && sudo apt upgrade -y
```

### **3. Clonar el repositorio de CiervaEdu**

```bash
git clone https://github.com/pablompea/ciervaedu.git
cd ciervaedu
```

### **4. Ejecutar el script de instalación**

Ir a la carpeta scripts

```bash
chmod +x install.sh
sudo ./install.sh
```

---

## **¡Instalación completada! 🎉**

Ahora tienes CiervaEdu configurado y listo para usar.

**Soporte y ayuda**:

- Consulta el [manual de configuración](INFO.md) para más detalles.

---
