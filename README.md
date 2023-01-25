# practica-09
Introducción a Ansible

Ansible es una herramienta que permite controlar muchas máquinas (servidores) desde una sola sin necesidad de un agente software externo o bash (que se conectaba a cada máquina, una a una). Se conecta con SSH a cada una de ellas y requiere una clave privada y otra pública. Guarda los archivos como .yaml o .yml.

1.	Instalar Ansible:
    - Usar la consola de Ubuntu (WSL). Al iniciarse, ejecutar los comandos *sudo apt update* y *sudo apt install ansible*.
  
2.	En el directorio de WSL se instala ansible y ansible-playbook.

3.	Se crean dos instancias en Amazon (Ubuntu, small, sin grupo de seguridad pero seleccionando acceso a HTTP y HTPPS). Para la práctica interesa almacenar las IP públicas de ambas (hay que tener en cuenta que cada vez que se levante el servidor estas IP cambiarán, por lo que hay que actualizarlas). Se guarda también la clave.

4.	Crear un repositorio y clonarlo.
*Nota: en VSC hay que emplear la consola de WSL.*

5.	Configurar archivo de inventario de Ansible: este fichero permite organizar por grupos las máquinas, para agrupar, por ejemplo, front y back. Se almacenan en [bloque 1] IP, IP… [bloque 2] IP, IP… etc. Se crea un fichero de texto llamado inventario y en él se crea el grupo que llamaremos [aws] con las dos IP públicas que se guardaron en el punto 3.

6.	Configurar el acceso por SSH: Amazon ya da el vockey para eso (ya genera la clave pública y privada). En el directorio de trabajo es necesario ejecutar el comando *ansible aws -m* (módulo de ansible que se empleará, en este caso ping) *ping -i* (para darle el archivo de inventario) *inventario* (el nombre del fichero donde están los grupos de Ansible) *--user* (indica con qué usuario remoto nos conectaremos) *ubuntu --private-key ruta\de\la\clave\vockey.pem*. El comando completo, sin comentarios, es entonces: *ansible aws -m ping -i inventario.txt --user ubuntu --private-key ruta/de/la/clave/vockey.pem*.

7.	Desde el archivo del inventario podemos especificar unas variables que se apliquen a todos los grupos, justo debajo de [aws]: 

````
[all:vars] 
ansible_user=ubuntu 
ansible_ssh_private_key_file=/ruta/de/la/clave/vockey.pem`
````
- Esto hará que en el comando no se le tenga que pasar usuario y clave, reduciendo el comando a *ansible aws -m ping -i inventario*.

8.	Para que no pregunte por el fingerprint, se puede añadir al fichero de inventario otros parámetros para aceptar cualquier fingerprint que venga (*ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'*) o configurar la variable de entorno ANSIBLE_HOST_KEY_CHECKING a false para que no sea necesario aceptar el fingerprint de instancias remotas. En este caso, se hace lo primero.

9.	Con todo esto, ya tenemos el equipo configurado para conectarse a dos máquinas remotas (basta con añadir IPs en el fichero **inventario**). Un ejemplo de ejecución de comando en cada grupo sería con Shell: *ansible aws -m shell *(permite ejecutar comandos dentro de máquinas remotas)* -a “ls -la” -i inventario*. Así haríamos un *ls -la* en cada máquina remota.

10.	Un playbook es un archivo yaml donde se definen tareas que se quieren ejecutar dentro de cada máquina. Tiene su propia sintaxis:
    - El fichero empieza siempre con tres guiones simples (---).
    - El guión define un array.
    - *Hosts* define sobre qué máquinas se aplicarán todas las tareas definidas en el .yml. Si hubiera varios grupos se agruparían con comas: host: aws, front, back…
    - *Become*: yes indica que todas las tareas se ejecutan con sudo (ocmo root). 
    - *Tasks* son las tareas a lanzar, que estarán dentro de paquetes o módulos. Cada uno tiene un *name* (descripción o título) y un comando, que indica lo que se quiere ejecutar. *Nota: si sólo quisiéramos ejecutar algunas tareas como root habría que poner dentro de tasks y debajo de name **become: yes** en lugar de especificarlo al inicio del fichero.*
    - Dentro de tasks se definen los módulos que se quiere que estén presentes en las máquinas remotas (por ejemplo, con el módulo *apt*, el *name* del paquete que interesa y *state*: present), si se quiere reiniciar el sistema (dentro del módulo *service* indicando el *name* del servicio a reiniciar y como *state*: restarted), o si se quieren mover ficheros, renombrarlos, crearlos, etc. Cada una de estas acciones tienen un módulo correspondiente. *Nota: para tener acceso a los nombres de los paquetes se puede ejecutar el comando apt search *una palabra clave como php, por ejemplo*.
    - Para copiar un archivo que esté presente en la máquina remota en otro directorio de esa misma máquina con el módulo *copy* será necesario añadir *remote_src:yes*. En caso contrario, intentará copiar desde la máquina local a la máquina remota un directorio que en el mejor de los casos no existe.
    
11.	Para poder ejecutar el playbook install_lamp.yml hay que ejecutar el comando *ansible-playbook -i inventario install_lamp.yml*
12. No es recomendable utilizar los módulos *shell* ni *command* si existe un módulo específico para la tarea que se quiere realizar.

#
## Práctica: crear la infraestructura necesaria para instalar PrestaShop y WordPress, uno con una arquitectura de un nivel y otro con una arquitectura en dos niveles.

Para crear la infraestructura se crearán diferentes directorios: 
- **/inventory** contendrá el fichero **inventario**, que contiene las IP elásticas de las instancias de front y back agrupadas como [aws] y un grupo llamado [aws:vars] que define el user, la clave privada y un parámetro para que no pregunte por el fingerprint.
- **/playbooks** contendrá todos los ficheros yaml en los cuales se definirán las tareas que se quieren ejecutar dentro de cada máquina.
- **/vars** contendrá un fichero con las variables que se emplearán en los playbooks.
- Habrá un fichero llamado **main.yml** que importará todos los playbooks para ejecutarlos desde consola llamando únicamente un fichero.

Dentro de **/playbooks** se crean tres ficheros:
- **install_lamp.yml**: contiene las instrucciones necesarias para instalar la pila LAMP. 
  - *hosts* será aws, el grupo definido en **inventario**.
  - *become*: **yes** para ejecutar como root.
  - Dentro de *tasks* se realizarán las siguientes tareas:
    - Actualiazr los repositorios utilizando el módulo *apt* y *update_cache:yes*. Esto es equivalente a ejecutar el comando *apt update* en bash.
    - Actualizar paquetes instalados utilizando el mismo módulo *apt* y *upgrade: dist*. Equivalente al comando *apt upgrade -y* en bash.
    - Instalación del servidor web Apache con el módulo *apt*, *name* apache2 y *state* present. Equivalenta al comando *apt install apache2 -y* en bash.
    - Instalación del gestor de la base de datos con el módulo *apt*, *name*: mysql-server y *state*: present. Equivalente al comando *apt install mysql-server -y*.
    - Instalación de PHP y los módulos necesarios con el módulo *apt*, listando debajo de *name* qué módulos son requeridos y definiendo como *state*: present. Esto es equivalente al comando *apt install php libapache2-mod-php php-mysql -y* de bash.
    
- **config_https.yml**: contiene las instrucciones para obtener el certificado HTTPS. Se definen los *hosts* y *become* al igual que **install_lamp**. Además, se indica que las variables se deben sacar del fichero de variables que se creó en **/vars** con *vars_files* y la ruta a dicho fichero. Dentro de las tareas:
  - Instalación del core de snapd con el módulo *shell* y el comando *snap install core*. 
  - Actualización de snapd con el módulo *shell* y el comando *snap refresh core*.
  - Borrado de instalaciones previas de CertBot con el mismo módulo y el comando *apt-get remove certbot -y*.
  - Instalación de CertBot con snapd con el mismo módulo y el comando *snap install --classic certbot*
  - Solicitud del certificado y configuración del servidor con el mismo módulo y un comando que requiere las variables, que se introducen con comillas dobles y doble llave: *certbot --apache -m "{{ https_variables.email }}" --agree-tos --no-eff-email -d "{{ https_variables.domain }}" --non-interactive*.

- **install_ps-main.yml**: este es el playbook más extenso, ya que contiene la instalación de paquetes de Python requeridos para que funcione MySQL, la instalación de este SGBD, la creación de la base de datos y el usuario, instalación de herramientas de desempaquetado como unzip y configuraciones propias del entorno que PrestaShop requiere para poder instalarlo

# 
*pendiente de completar*
