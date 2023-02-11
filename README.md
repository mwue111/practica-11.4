# Ansible

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

Para crear la infraestructura se crearán diferentes directorios, comunes a ambas infraestructuras (salvo un directorio propio de **WordPress**): 
- **/inventory** contendrá el fichero **inventario**, que contiene un grupo llamado [aws:vars] que define el user, la clave privada y un parámetro para que no pregunte por el fingerprint y, además:
  - En **PrestaShop**: las IP elásticas de las instancias de front y back agrupadas como [aws]
  - En **WordPress**: las IP elásticas de las  instancias de front y back separadas en dos grupos: [frontend] y [backend]. 
  
- **/playbooks** contendrá todos los ficheros yaml en los cuales se definirán las tareas que se quieren ejecutar dentro de cada máquina.
- **/vars** contendrá un fichero con las variables que se emplearán en los playbooks.
- Habrá un fichero llamado **main.yml** que importará todos los playbooks para ejecutarlos desde consola llamando únicamente un fichero.
- En el caso de **WordPress**, además, habrá un dirctorio **/conf** en el cual se guardará el fichero **000-default.conf** necesario para permitir la sobrescritura en /var/www/html.
  
### PrestaShop

Dentro de **/playbooks** se crean tres ficheros:
- **install_lamp.yml**: contiene las instrucciones necesarias para instalar la pila LAMP. 
  - *hosts* será aws, el grupo definido en **inventario**.
  - *become*: **yes** para ejecutar como root.
  - Dentro de *tasks* se realizarán las siguientes tareas:
    - Actualizar los repositorios utilizando el módulo *apt* y *update_cache:yes*. Esto es equivalente a ejecutar el comando *apt update* en bash.
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

- **install_ps-main.yml**: este es el playbook más extenso, ya que contiene la instalación de paquetes de Python requeridos para que funcione MySQL, la instalación de este SGBD, la creación de la base de datos y el usuario, instalación de herramientas de desempaquetado como unzip y configuraciones propias del entorno que PrestaShop requiere para poder instalarlo.

### WordPress
Dentro de **/playbooks** se crean cuatro ficheros:
- **install_front.yml**: contiene las instrucciones necesarias para instalar el frontend de WordPress.
  - *hosts* será frontend esta vez, el grupo definido en **inventario** para el front.
  - *become*: **yes** para ejecutar como root.
  - Dentro de *tasks* se realizarán las siguientes tareas:
    - Actualizar los repositorios utilizando el módulo *apt* y *update_cache:yes*. Esto es equivalente a ejecutar el comando *apt update* en bash.
    - Actualizar paquetes instalados utilizando el mismo módulo *apt* y *upgrade: dist*. Equivalente al comando *apt upgrade -y* en bash.
    - Instalación del servidor web Apache con el módulo *apt*, *name* apache2 y *state* present. Equivalenta al comando *apt install apache2 -y* en bash.
    - Instalación de PHP y los módulos necesarios con el módulo *apt*, listando debajo de *name* qué módulos son requeridos y definiendo como *state*: present. Esto es equivalente al comando *apt install php libapache2-mod-php php-mysql -y* de bash.
    - Copia del archivo de configuración de Apache con el módulo *copy*, indicando como *src* o fuente la ruta donde almacenamos el fichero **000-default.conf** (dentro del dorectorio **/conf**) y como destino (*dest*) la ruta a la cual se debe copiar este archivo de configuración. Esta tarea sería equivalente al comando *cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf* de bash.
    - Reinicio del servicio Apache con el módulo *service*, indicando como *name* apache2 y como *state*: restarted. Equivalente al comando *systemctl restart apache2* en bash.

- **install_back.yml**: contiene las instrucciones necesarias para instalar el backend de WordPress.
  - *hosts* será backend esta vez, el grupo definido en **inventario** para el back.
  - *become*: **yes** para ejecutar como root.
  - Dentro de *tasks* se realizarán las siguientes tareas:
    - Actualizar los repositorios utilizando el módulo *apt* y *update_cache:yes*. Esto es equivalente a ejecutar el comando *apt update* en bash.
    - Actualizar paquetes instalados utilizando el mismo módulo *apt* y *upgrade: dist*. Equivalente al comando *apt upgrade -y* en bash.
    - Instalación del gestor de paquetes Python pip3, imprescindible para que MySQL funcione. Esto se hace con el módulo *apt*, indicando como *name* python-pip y como *state*:present.
    - Instalación del módulo de pymysql con *pip*, indicando el *name*: pymysql y *state*:present.
    - Instalación del gestor de la base de datos con el módulo *apt*, *name*: mysql-server y *state*: present. Equivalente al comando *apt install mysql-server -y*.
    - Configuración de MySQL para poder conectar con el frontend con el módulo *replace*. Con esto se consigue que el backend se pueda conectar con el frontend desde cualquier IP. Se establece como ruta (*path*) **/etc/mysql/mysql.conf.d/mysqld.cnf** y se define *regexp* como 127.0.0.0 y *replace* como 0.0.0.0. Esto sería equivalente al comando *sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf* en bash.
    - Se reinicia el MySQL con el módulo *service* indicando *name*:mysql y *state*:restarted. Sería equivalente al comando *systemctl restart apache2*.
    - Se crea la base de datos con el módulo *mysql_db*. Se especifica el *name* como la variable almacenada en el fichero **/vars**, *state*:present y se indica como *login_unix_socket: /var/run/mysqld/mysqld.sock* para que se conecte desde localhost (si no se indica, falla). El equivalente en bash serían los comandos *mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"* y *mysql -u root <<< "CREATE DATABASE IF NOT EXISTS $DB_NAME;"*.
    - Se crea el usuario especificando *no_log*:true y con el módulo *mysql_user* se especifican los datos relacionados con el usuario, como el nombre (*name*) y la contraseña (*password*) haciendo uso de las variables en **/vars**. Se conceden priviledios con *priv* interpolando el nombre de la base de datos y especificando que se darán todos los privilegios en todas las tablas de esa base de datos *"{{ wp_variables.name }}.\*:ALL"*. Como habrá una máquina para front y otra para back, se define *host*:"%" para que los usuarios puedan conectarse desde cualquier servidor. Se indica que el estado debe ser presente con *state*:present y, otra vez, hay que especificar *login_unix_socket: /var/run/mysqld/mysqld.sock*. Esto sería equivalente a los comandos:
      - *mysql -u root <<< "DROP USER IF EXISTS $DB_USER@'%';"*, 
      - *mysql -u root <<< "CREATE USER \$DB_USER@'%' IDENTIFIED BY '$DB_PASS';"*, 
      - *mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.\* TO $DB_USER@'%';"*
      - *mysql -u root <<< "FLUSH PRIVILEGES;"*

Se ejecutan los playbooks con los comandos *ansible-playbook -i inventario nombre_del_playbook.yml*.

#

# AWS CLI 

AWS CLI es una herramienta que permite gestionar servicios de Amazon Web Services accediendo a la API de AWS desde la línea de comandos. Permite replicar el mismo entorno siempre: igual que se tienen scripts para el software, se tienen scripts para la infraestructura. 

1. Insalar el CLI de amazon:
   1. En el servidor de AWS, en la pantalla de inicio, se pueden localizar las credenciales en **AWS Details**. Se copian.
   
   2. Amazon tiene documentación relacionada con la instalación o actualización de la versión más reciente de AWS CLI. En ella, se selecciona el SO que se va a utilizar (Linux) y muestra un comando *curl* que es necesario copiar en la consola: *curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" unzip awscliv2.zip sudo ./aws/install*. No es necesario que se esté situada en el directorio de trabajo, ya que el instalador, al lanzarse, se guarda en un directorio prestablecido. Una vez instalado, el código fuente se puede borrar.

   3. Configurar usuario y contraseña: en consola, se da a la opción AWS configure para que salga el asistente de configuración. Los datos que se escriban son irrelevantes. Tras esto, se habrán creado dos archivos: **credentials**, que se cambiará más adelante, y **config**, que permite configurar la región y el formato de salida.
   
   4. Para que esto sea seguro, se usan tokens en lugar de poner usuario y contraseña. Se han conseguido en el primer paso, en **AWS Details**. Se trata del token *aws_secret_key_id*, *aws_secret_access_key* y *aws_session_token*. Estas claves tendrán que cambiarse cada vez que se levante el servidor. Para cambiarlas por consola se ejecuta el comando *code /home/usuario/.aws/credentials* y se copian en ese fichero. En el fichero de **credentials** suele haber diferentes tokens para diferentes clientes, [default] es el que se crea pero se podría añadir debajo [proyectoA], [proyectoB], etc.
   
   5. Se ejecuta el mismo comando para el archivo config:  *code /home/usuario/.aws/config* y se cambia el contenido: región = us-east-1 y output = json para que los datos los devuelva en formato JSON.
   
   6. Para comprobar si ha funcionado, se ejecuta el comando *aws ec2* (ec2 es el servicio) *describe-instances*, en consola tiene que devolver un JSON con las instancias creadas.

2.	Creación de un grupo de seguridad: ejecutar el comando *aws ec2 create-security-group --description <value\> --group-name <value\>*. Para comprobar si se ha creado, se lanza el comando *aws ec2 describe-security-groups*, debe devolver un JSON con la información de todos los grupos de seguridad creados en Amazon. Si sólo queremos la información de un grupo, se ejecuta *aws ec2 describe-security-groups --group-name nombre-del-grupo-de-seguridad*.

3.	Añadir reglas de entrada al grupo de seguridad por consola: para ello, se emplea el comando *aws ec2 authorize-security-group-ingress* con una serie de parámetros opcionales, listados abajo. Hay que ejecutar este comando por cada puerto que se abra (por cada regla de seguridad añadida).
  - *[--group-id id-del-grupo-de-seguridad]*
  - *[--group-name nombre-del-grupo-de-seguridad]*
  - *[--ip-permissions \<value>]*
  - *[--dry-run | --no-dry-run]*
  - *[--tag-specifications \<value>]*
  - *[--protocol \<value>]*
  - *[--port \<value>]*
  - *[--cidr \<value>]*
  - *[--source-group \<value>]*
  - *[--group-owner \<value>]*
  - *[--cli-input-json | --cli-input-yaml]*
  - *[--generate-cli-skeleton \<value>]*
  
4.	Eliminar un grupo de seguridad: se emplea el comando *aws ec2 delete-security-group[--group-id \<value>][--group-name \<value>][--dry-run | --no-dry-run][--cli-input-json | --cli-input-yaml][--generate-cli-skeleton \<value>]*. No hay un comando que borre todos los grupos de seguridad, así que si se necesita borrar más de uno a la vez se puede hacer ejecutando un comando que recupere todos los ID de los grupos de seguridad y envíe esa información a otro comanado. El parámetro *query* permite obtener ciertos datos dentro de un JSON: por ejemplo, *--query “SecurityGroups[\*].GroupId”* permite obtener el ID como GroupID de todos los elementos de segurityGroups. Se puede especificar cómo se quiere que devuelva los resultados con el parámetro *--output formato-devuelto*, por ejemplo *--output text*.

5.	Crear una instancia en EC2: se emplea el comando *aws ec2 run-instances*. Los parámetros se sacan de la interfaz de amazon: el ID de AMI se obtiene al crear una instancia (el de Ubuntu será ami-06878d265978313ca), al elegir un sistema operativo u otro. *Count* indica la cantidad de instancias que se están creando y el tipo de insancia será t2.micro (ambos valores van por defecto).

6.	Durante la creación de la instancia, el parámetro *user-data* permite pasarle un comando o una lista de comandos o con *file* un script (como los de bash). Por tanto, permite crear la instancia y preparar LAMP y todo lo que se tenga en estos scripts.

7.	Por ejemplo, para ejecutar un script que instale nginx en la instancia creada, se crea un fichero *install_nginx.sh* con los comandos *sudo apt update* y *sudo apt install -y nginx* y, tras esto y en el mismo directorio donde se encuentra este fichero, se lanza el comando *aws ec2 run-instances --image-id ami-050406429a71aaa64 --count 1 --instance-type t2.micro --key-name vockey --security-groups frontend-sg --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=frontend-01}]" **--user-data file://install_nginx.sh***. Así, se crea una instancia con nginx instalado.

## Ejercicios
La resolución de los ejercicios se encuentra en el directorio [/practica13.1](https://github.com/mwue111/practica-11.4/tree/main/practica13.1).

**Crear un grupo de seguridad para las máquinas del Backend con el nombre backend-sg. Añada las siguientes reglas al grupo de seguridad:**
  - **Acceso SSH (puerto 22/TCP) desde cualquier dirección IP.**
  - **Acceso al puerto 3306/TCP desde cualquier dirección IP.**

Para realizar este ejercicio se ejecutó el comando:

*aws ec2 create-security-group \
    --group-name backend-sg \
    --description "Reglas para el backend"*

Para agregar las reglas de seguridad:

*aws ec2 authorize-security-group-ingress \
    --group-name backend-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0*

*aws ec2 authorize-security-group-ingress \
    --group-name backend-sg \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0*

**Crea una instancia EC2 para la máquina del Backend con las siguientes características:**
  - **Identificador de la AMI: ami-08e637cea2f053dfa.**
  - **Número de instancias: 1**
  - **Tipo de instancia: t2.micro**
  - **Clave privada: vockey**
  - **Grupo de seguridad: backend-sg**
  - **Nombre de la instancia: backend**
Para resolver este ejercicio, se ejecutó el comando 
*aws ec2 run-instances \
    --image-id ami-08e637cea2f053dfa \
    --count 1 \
    --instance-type t2.micro \
    --key-name vockey \
    --security-groups backend-sg \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_BACKEND}]"*

En el fichero del ejercicio 4, todas las características que podían almacenarse en un [fichero de variables externo](https://github.com/mwue111/practica-11.4/blob/main/practica13.1/variables.sh) se han almacenado de esa manera, que es más segura. 

**Crear un script para crear la infraestructura de la práctica 9.**

[Script para crear la infraestructura de la práctica 9.](https://github.com/mwue111/practica-11.4/blob/main/practica13.1/create_all.sh)

**Crear un script para eliminar la infraestructura de la práctica 9.**

[Script para eliminar la infraestructura de la práctica 9.](https://github.com/mwue111/practica-11.4/blob/main/practica13.1/delete_all.sh)

**Modifique los scripts del repositorio de ejemplo para que utilicen la siguiente AMI:**
- **Nombre de la AMI: Ubuntu Server 22.04 LTS (HVM).**
- **Identificador de la AMI: ami-06878d265978313ca.**
**También tendrá que modificar los scripts para que se ejecute el siguiente comando en las instancias durante el inicio:**
*$ sudo apt update && sudo apt upgrade -y*

[Fichero modificado.](https://github.com/mwue111/practica-11.4/blob/main/practica13.1/ejercicio4/04-create_instances.sh)

**Escriba un script de bash que muestre el nombre de todas instancias EC2 que tiene en ejecución junto a su dirección IP pública.**

[Script que muestra el nombre de las instancias junto a su dirección IP pública.](https://github.com/mwue111/practica-11.4/blob/main/practica13.1/ejercicio5.sh)