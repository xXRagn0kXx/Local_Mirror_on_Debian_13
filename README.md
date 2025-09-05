# :globe_with_meridians: Local Repository (DebMirror + Nginx) on Debian 13

Este repositorio proporciona una guía paso a paso y los archivos de configuración necesarios para crear y gestionar un mirror local con los paquetes oficiales de Debian 13 (Trixie). 

Esta solución garantiza una actualizacion controlada y evita trafico de la red asegurandose de que el sofware sea confiable utilizando la herramienta debmirror para la sincronización y Nginx para servir los paquetes a través de tu red local.

---
![Portada de DebMirror](DebMirror_Portada.png)
---

## :book: Contenido

* :cop: [Terminos de uso](./LICENSE)
* :atom: [Características](#atom-características)
* :white_check_mark: [Requisitos](#white_check_mark-requisitos)
* :gear: [1 Instalar el software necesario](#gear-1-instalar-el-software-necesario)
* :file_folder: [2 Crear el Directorio del repositorio](#file_folder-2-crear-el-directorio-del-repositorio)
    * [2.1 Identificar disco](#21-identificar-disco)
    * [2.2 Limpiar disco](#22-limpiar-disco)
    * [2.3 Crear una particion](#23-crear-una-particion)
    * [2.4 Dar formato a la particion del disco](#24-dar-formato-a-la-particion-del-disco)
    * [2.5 Localizar la UUID](#25-localizar-la-uuid)
    * [2.6 Confgurar montaje automatico](#26-confgurar-montaje-automatico)
    * [2.7 Recargar fstab](#27-recargar-fstab)
    * [2.8 Montar disco](#28-montar-disco)
    * [2.9 Otorgar permisos a Nginx](#29-otorgar-permisos-a-nginx)
* :abc: [3 Crear los script para debmirror](#abc-3-crear-los-script-para-debmirror)
    * [3.1 Crear el script main Debian 13](#31-crear-el-script-main-debian-13)
    * [3.2 Crear el script security Debian 13](#32-crear-el-script-security-debian-13)
* :pencil: [4 Configurar Nginx](#pencil-4-configurar-nginx)
    * [4.1 Crear fichero del sitio](#41-crear-fichero-del-sitio)
    * [4.2 Activamos el sitio web](#42-activamos-el-sitio-web)
    * [4.3 Prueba y recarga](#43-prueba-y-recarga)
    * [4.4 Actualizar el repositorio](#44-actualizar-el-repositorio)
        * [4.4.1 Metodo manual:](#441-metodo-manual)
        * [4.4.2 Metodo automatico:](#442-metodo-automatico)
* :boy: [5 Configurar cliente:](#boy-5-configurar-cliente)
    * [5.1 Añadir repositorio al cliente](#51-añadir-repositorio-al-cliente)
    * [5.2 Actualizar equipo o instalar](#52-actualizar-equipo-o-instalar)
* :grey_question: [6 Verificación y solución de problemas](#grey_question-6-verificación-y-solución-de-problemas)
* :ballot_box_with_check: [7 Para agregar un repositorio sin firmar](#ballot_box_with_check-7-para-agregar-un-repositorio-sin-firmar)
  
---

## :atom: Características

* **Ahorro de ancho de banda:** Evita descargas repetidas de internet en varias máquinas.
* **Actualizaciones más rápidas:** Todas las instalaciones y actualizaciones se realizan a la velocidad de la red local.
* **Acceso sin conexión:** Proporciona una solución robusta para entornos con conectividad a internet limitada o nula.
* **Personalizable:** Puedes elegir qué arquitecturas y secciones reflejar para ahorrar espacio en disco.

---

## :white_check_mark: Requisitos

* Conocimientos medios de informatica o entender el uso de la guia
* Un servidor o maquina con **Debian 13 (Trixie)**
* Usuario con permisos sudo o tener permisos root
* Conexion a internet permanenete o puntual para sincronizar el repositorio
* Una maquina virtual o fisica que tendra un disco para el sistema Debian y otro para el repositorio (200Gb ideal)
* Se aconseja crear un usuario para el repositorio durante la instalacion de Debian13, nosotros hemos creado "debmirror"
---

# :gear: 1 Instalar el software necesario
Los paquetes son necesarios para:
* debmirror: Esta herramienta conectara y sincronizara el repositorio de Debian
* rsync: Es utilizado por debmirror para calculas las diferencias a descargar
* nginx: Servidor proxy web que proveera mediante http o https los paquetes a descargar
* gnupg: Herramienta para manejar las claves de los repositorios
* debian-archive-keyring: Anillo con las claves del repositorio oficial de debian

```bash
sudo apt install -y debmirror rsync nginx gnupg debian-archive-keyring
```
# :file_folder: 2 Crear el Directorio del repositorio

   Crearemos el directorio donde se guardará el repositorio, para ello montaremos un segundo volumen en nuestra maquina Debian13 en la ruta /mnt/Almacen/
```bash
sudo mkdir -p /mnt/Almacen
```

### 2.1 Identificar disco
Si no hemos introducido el segundo disco en la maquina, lo introducimos y nos hacemos root con "su -" o "sudo su" e identificamos el disco.
```bash
lsblk
```
### 2.2  Limpiar disco
Una vez indentificado el disco a tratar, si tiene alguna configuracion previa la limpiaremos (si esta en blanco saltar este paso):
```bash
* sudo fdisk /dev/sdX (reemplaza /dev/sdX con el nombre de tu disco).	
* Presiona d para eliminar una partición. Repite esto para eliminar todas las particiones.
* Presiona w para escribir los cambios en el disco.
* Presiona q para salir de fdisk
```
### 2.3 Crear una particion
Usamos el formato GPT, ya que es el moderno.
```bash
* sudo fdisk /dev/sdX (reemplaza /dev/sdX con el nombre de tu disco)
* Presiona m para ver el menu
* Presiona g para crear la tabla de particiones en formato GPT 
* Presiona n para crear una nueva particion (le vamos a intro en los valores por defecto hasta crear la particion)
* Presiona w para escribir los cambios en el disco
* Presiona q para salir de fdisk
```
Comprobamos que se a creado una particion dentro del disco con formato /dev/sdX1 usando lsblk.
```bash
lsblk
```
### 2.4 Dar formato a la particion del disco
Usaremos ext4 por su rendimiento, estabilidad y sencillez en linux: 
```bash
sudo  mkfs.ext4 /dev/sdX1
```
### 2.5 Localizar la UUID 
Esta se a generado en la particion al darle formato al disco.
```bash
sudo blkid
```				
Nos mostrara un listado de todos los discos disponibles, apuntamos solo la UUID del que nos interesa /dev/sdX1

### 2.6 Confgurar montaje automatico
```bash
sudo nano /etc/fstab 
```
Crearemos una nueva linea debajo del todo (por orden, recomendamos una linea comentada del uso del disco justo encima de este).
```bash
# Disco2 Almacen del repositorio
UUID=08e21b2a-3eeb-4a60-8bbb-56a2c17b4d72	/mnt/Almacen ext4 defaults,auto		0 	0
```
:warning: **Importante** quitar las "" del campo UUID y asegurarnos que la ruta referenciada existe previamente.

Guardamos y salimos

### 2.7 Recargar fstab
Recargamos la confoguracion del fichero 
```bash
sudo systemctl daemon-reload
```
### 2.8 Montar disco
Montamos el disco y si no da ningun error comprobamos que la ruta creada tiene el tamaño del disco.
```bash
mount -a
```
Comprobamos la unidad montada:
```bash
df -h
```
Esta es una linea de ejemplo si estubiera montado en /dev/sdb1.
```bash
					/dev/sb1	916G	276GB	595G	1%	/mnt/Almacen
```
			
### 2.9 Otorgar permisos a Nginx 
Otorgamos permisos y propietario al usuario que de Nginx que servira los ficheros del disco.
```bash
sudo mkdir -p /mnt/Almacen/Repositorio
sudo chown -R www-data:www-data /mnt/Almacen/Repositorio
sudo chmod -R 755 /mnt/Almacen/Repositorio
```
Con esto ya tenemos configurado el almacenamiento fisico del repositorio. 
			
# :abc: 3 Crear los script para debmirror
Crear los scripts de sincronización para que utilice el nuevo directorio en "/mnt/Almacen/Repositorio/", esta configuracion se divide en 2 repositorios principales, el main para los paquetes principales y el security para las actualizaciones de seguridad. **Nosotros los alojaremos en /usr/local/bin/ para que puedan ser tabulados y llamados desde cualquier ruta**. 		

### 3.1 Crear el script main Debian 13

```bash
sudo nano /usr/local/bin/deb13_main_repo.sh
```
```bash
#!/bin/bash

# Script para actualizar el repositorio local de Debian 13 (Trixie)
# La idea es dejarlo en un crontab para que actualice el mirror periodicamente solo.

# Directorio donde se guardara el mirror
MIRROR_DIR="/mnt/Almacen/Repositorio/Debian13/main/"

# Directorio donde se Almacenara el log.
LOG_FILE="/mnt/Almacen/Repositorio/Deb13_Main_Repo.log"

#A partir de aqui empezara la grabacion del log.
exec >> "$LOG_FILE" 2>&1
echo ""
echo "=== Iniciando sincronización: $(date) ==="
echo ""

# Parametros de debmirror:
#   --arch: arquitectura (amd64)
#   --nosource: omite los paquetes fuente (si no los necesitas)
#       --root: Raiz del repositorio
#   --host: el mirror de origen. Puedes usar un servidor HTTP o RSYNC.
#       En esta guia se usa el servidor HTTP de deb.debian.org. Si prefieres rsync,
#       cambia --method y --host según corresponda.
#   --method: método de transferencia (http o rsync)
#   --dist: distribuciones a sincronizar.
#       Para Debian 13 (Trixie) y sus actualizaciones, usamos:
#       trixie, trixie-updates, trixie-security
#	--section: secciones a incluir (main, contrib, non-free).
# 	--progress: muestra progreso (opcional).
#       --verbose: Depura todo lo posible la salida de debmirror.
#       --keyring: Ruta donde esta alojado el anillo de claves del repositorio oficial.
#       --dry-run: Recorre el repostorio oficial y analiza todo lo que necesita descargar pero sin llegar hacerlo.
#	--ignore-release-gpg: omite la verificación de firmas (opcional; úsalo si tienes problemas con GPG,(no recomendado)).
#	--rsync-extra=none: omite el uso de Rync para que no se quede esperando al repositorio de Debian (usa HTTP).
#	--no-remove: No elimina paquetes antiguos.

debmirror \
  --arch=amd64 "$MIRROR_DIR" \
  --nosource \
  --root=debian \
  --host=deb.debian.org \
  --method=https \
  --dist=trixie,trixie-updates \
  --verbose \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  --progress \
  --section=main,contrib,non-free,non-free-firmware \
  --rsync-extra=none \
# --no-remove \
# --dry-run \
# --ignore-release-gpg \

# NOTA: Comentar o descomentar los parametros "--dry-run" y "--ignore-release-gpg", segun sea necesario su uso.

# Finalizar grabacion del log.
echo ""
echo "=== Sincronización finalizada: $(date) ==="
echo ""
```
---
### 3.2 Crear el script security Debian 13

```bash
sudo nano /usr/local/bin/deb13_security_repo.sh
```

```bash
#!/bin/bash
# Sincronizar repositorio de seguridad (trixie-security) desde security.debian.org
# Se ejecuta como usuario debmirror

# Directorio donde se guardara el mirror
MIRROR_DIR="/mnt/Almacen/Repositorio/Debian13/security/"

# Directorio donde se Almacenara el log.
LOG_FILE="/mnt/Almacen/Repositorio/Deb13_Security_Repo.log"

#A partir de aqui empezara la grabacion del log.
exec >> "$LOG_FILE" 2>&1
echo ""
echo "=== Iniciando sincronización: $(date) ==="
echo ""


# Parametros de debmirror:
#   --arch: arquitectura (amd64).
#   --nosource: omite los paquetes fuente (si no los necesitas).
#       --root: Raiz del repositorio.
#   	--host: el mirror de origen. Puedes usar un servidor HTTP o RSYNC.
#       En esta guia se usa el servidor HTTP de deb.debian.org. Si prefieres rsync,
#       cambia --method y --host según corresponda.
#   	--method: método de transferencia (http o rsync).
#   	--dist: distribuciones a sincronizar.
#       Para Debian 13 (Trixie) y sus actualizaciones, usamos:
#       trixie, trixie-updates, trixie-security
#	--section: secciones a incluir (main, contrib, non-free).
#	--progress: muestra progreso (opcional).
#       --verbose: Depura todo lo posible la salida de debmirror.
#       --keyring: Ruta donde esta alojado el anillo de claves del repositorio oficial.
#       --dry-run: Recorre el repostorio oficial y analiza todo lo que necesita descargar pero sin llegar hacerlo.
#	--ignore-release-gpg: omite la verificación de firmas (opcional; úsalo si tienes problemas con GPG,(no recomendado)).
#	--rsync-extra=none: omite el uso de Rync para que no se quede esperando al repositorio de Debian (usa HTTP).
#	--no-remove: No elimina paquetes antiguos

debmirror \
  --arch=amd64 "$MIRROR_DIR" \
  --nosource \
  --root=debian-security \
  --host=security.debian.org \
  --method=http \
  --dist=trixie-security \
  --verbose \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  --progress \
  --section=main,contrib,non-free,non-free-firmware \
  --rsync-extra=none \
# --no-remove \
# --dry-run \
#  --ignore-release-gpg \
# NOTA: Comentar o descomentar los parametros "--dry-run" y  "--ignore-release-gpg", segun sea necesario su uso.

# Finalizar grabacion del log.
echo ""
echo "=== Sincronización finalizada: $(date) ==="
echo ""
```

Una vez creados los script le damos permisos y propietario al usuario que lo vaya a ejecutar.

```bash
chown debmirror:debmirror /usr/local/bin/deb13_main_repo.sh
chown debmirror:debmirror /usr/local/bin/deb13_security_repo.sh
chmod 750 /usr/local/bin/deb13_main_repo.sh
chmod 750 /usr/local/bin/deb13_security_repo.sh
```
---

# :pencil: 4 Configurar Nginx
Su objetivo será servir el Repositorio desde /mnt/Almacen/Repositorio

Creamos la configuración de nginx para servir la nueva ubicación del repositorio.

###	4.1	Crear fichero del sitio
Este fichero es necesario para Nginx ofrezca nuestro repositorio:
```bash
sudo nano /etc/nginx/sites-available/Repositorio
```
Modifica **server_name** con el nombre DNS o la IP del servidor y el bloque **location** para que apunte al nuevo directorio.
* listen: El puerto
* server_name: nombre DNS o IP local
* location: lo que escribiremos despues de la IP desde el cliente http://tu_servidor_o_ip/Repositorio/
* alias: ruta a la redirige Nginx
* autoindex on; para listar ficheros si no existe pagina web.
**Nota: importante las "/" al final ya que esto indica a Nginx que esto es un directorio no un fichero.**
```bash
server {
    listen 80;
    server_name 192.168.10.112;

    location /Repositorio/ {
        alias /mnt/Almacen/Repositorio/;
        autoindex on;
    }
}
```
---
### 4.2 Activamos el sitio web
Funciona mediante un enlace simbolco a la ruta sites-enabled.
```bash
sudo ln -s /etc/nginx/sites-available/Repositorio /etc/nginx/sites-enabled/
```	
###	4.3	Prueba y recarga 
Recargamos la configuración de nginx para aplicar los cambios.
```bash
sudo nginx -t
```
Si nos devuelve **successful** recargaremos el servicio para aplicarlo
```bash
sudo systemctl reload nginx
```
## 4.4 Actualizar el repositorio
Puede ser manual o periódicamente.
		
### 4.4.1 Metodo manual:
```bash
sudo /usr/local/bin/deb13_main_repo.sh
sudo /usr/local/bin/deb13_security_repo.sh
```
Nota: Al estar los script en  /usr/local/bin/ podemos llamarlos directamente tabulandolos por su nombre.

### 4.4.2 Metodo automatico:				
Para mantener el repositorio actualizado la mejor opcion configurar un cron que ejecute el script de actualización cada cierto tiempo.

Edita el archivo de cron:
```bash
crontab -e
```
Agrega el siguiente codigo final del archivo para ejecutar el script de actualización cada 6 horas, debmirror analizara las diferencias y solo descargara lo que cambie o aparezca nuevo:
```bash
# Tarea programada para actualizar el repositorio principal
0 */6 * * * /usr/local/bin/deb13_main_repo.sh
# Tarea programada para actualizar el repositorio de seguridad
0 */6 * * * /usr/local/bin/deb13_security_repo.sh
```
:warning: Para asegurarse, compobar que las tareas se ejecutan correctamente revisando los log en /mnt/Almacen/Repositorio/*.log

---
# :boy:	5 Configurar cliente:
Deberemos configurar los clientes para que intenten actualizar o instalar desde nuestro nuevo repositorio.

### 5.1 Añadir repositorio al cliente
Añadiremos el nuevo repositorio y descomentamos el de debian:
Creamos un nuevo fichero repositorio.sources en la ruta /etc/apt/sources.list.d/ .
```bash
sudo nano /etc/apt/sources.list.d/repositorio.sources
```

```bash
# Repositorio principal
Enabled: yes
Types: deb
URIs: http://YOUR_IP_OR_DNS_NAME/Repositorio/Debian13/main
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Repositorio de seguridad
Enabled: yes
Types: deb
URIs: http://YOUR_IP_OR_DNS_NAME/Repositorio/Debian13/security 
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```
Guardamos el fichero

:warning: Para asegurarnos de que el cliente usa nuestro repositorio y no el externo comentaremos el fichero original de Debian /etc/apt/sources.list.d/debian.sources por si algun dia queremos volver a el.

```bash
sudo nano /etc/apt/sources.list.d/debian.sources
```
```bash
#Types: deb
#URIs: http://deb.debian.org/debian/
#Suites: trixie trixie-updates
#Components: main contrib non-free-firmware
#Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

#Types: deb
#URIs: http://security.debian.org/debian-security/
#Suites: trixie-security
#Components: main contrib non-free-firmware
#Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```
---

### 5.2 Actualizar equipo o instalar
En el cliente una vez guardado el fichero ejecutamos:
```bash
sudo apt update
```

Si todo sale bien nos mostrara los paquetes nuevos pendientes de descargar o comenzara la instalacion, si no tendremos que consultar los log de /var/log/apt.

---
# :grey_question: 6 Verificación y solución de problemas
* Verificar logs: Compobar como se ejecutan las tareas en /mnt/Almacen/Repositorio/*.log
* Probar acceso: En las máquinas clientes, ejecuta sudo apt update para asegurarte de que puedan conectarse y actualizarse desde el repositorio local


# :ballot_box_with_check: 7 Para agregar un repositorio sin firmar
```bash
deb [trusted=yes] http://tu_servidor_o_ip/debian trixie main contrib non-free
deb [trusted=yes] http://tu_servidor_o_ip/debian trixie-updates main contrib non-free

```


