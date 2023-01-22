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
```
[all:vars] 
ansible_user=ubuntu 
ansible_ssh_private_key_file=/ruta/de/la/clave/vockey.pem`
````
 Esto hará que en el comando no se le tenga que pasar usuario y clave, reduciendo el comando a *ansible aws -m ping -i inventario*.

8.	Para que no pregunte por el fingerprint, se puede añadir al fichero de inventario otros parámetros para aceptar cualquier fingerprint que venga (*ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'*) o configurar la variable de entorno ANSIBLE_HOST_KEY_CHECKING a false para que no sea necesario aceptar el fingerprint de instancias remotas. En este caso, se hace lo primero.

9.	Con todo esto, ya tenemos el equipo configurado para conectarse a dos máquinas remotas (basta con añadir IPs en el fichero **inventario**). Un ejemplo de ejecución de comando en cada grupo sería con Shell: *ansible aws -m shell *(permite ejecutar comandos dentro de máquinas remotas)* -a “ls -la” -i inventario*. Así haríamos un *ls -la* en cada máquina remota.

10.	Un playbook es un archivo yaml donde se definen tareas que se quieren ejecutar dentro de cada máquina. Tiene su propia sintaxis:
    - El fichero empieza siempre con tres guiones simples (---).
    - El guión define un array.
    - Hosts define sobre qué máquinas se aplicarán todas las tareas definidas en el .yml. Si hubiera varios grupos se agruparían con comas: host: aws, front, back…
    - Become: yes indica que todas las tareas se ejecutan con sudo (ocmo root). 
    - Tasks son las tareas a lanzar. Cada una tiene un name y un comando, que indica el módulo de ansible que se quiere ejecutar (ping o Shell que hemos hecho antes). Si sólo quisiéramos ejecutar algunas tareas como root habría que poner dentro de tasks, debajo de name, become: yes.
    
11.	Para poder ejecutar el playbook install_lamp.yaml hay que ejecutar el comando *ansible-playbook -i inventario install_lamp.yml*

#
TODO

a.	Tasks tiene el nombre y además tiene dentro de apt (que es un módulo) identificado el nombre de los paquetes que se quiere que estén presentes en las máquinas remotas (se define con el estado state: present). Tener en cuenta que el módulo que engloba los paquetes no siempre será apt, por ejemplo para reestablecer apache se usa el módulo service (línea 31 del install_lamp.yml en ejemplo-03). Ahí se especifica también el estado como reiniciado: state: restarted.
Para tener acceso a los nombres de los paquetes se puede ejecutar el comando apt search *una palabra clave como php, por ejemplo*.
14.	Copiar un archivo en la máquina remota en otro directorio en esa misma máquina remota con el módulo copy: se emplea igual añadiendo remote_src: yes. Si no lleva esto, copia desde la máquina local a la máquina remota. Para que funcione, la carpeta en src tiene que existir en la máquina remota, porque si no estará buscando un directorio en la máquina remota que no existe.
pip: gestor de paquete de Python. Se ha usado en el ejemplo 07 para instalar el módulo de pymysql.
15.	Conectar con MySQL desde playbook: en la tarea con el módulo mysql_db hay que especificar login_unix_socket: /var/run/mysqld/mysqld.sock tal cual para que no se conecte por red (porque falla). Esta línea indica que la conexión va a ser a través de localhost. Es imprescindible para conectar con MySQL.
Si se especifica became:yes en sólo una tarea, el resto se ejecutan como el usuario que se ha conectado por SSH (en este caso, como usuario ubuntu).
Para CLI: Shell con chdir:
Shell: 
cmd: comando
chdir: dirección/de/index_cli o como se llame
IaC
https://josejuansanchez.org/iaw/practica-aws-cli/index.html
Permite replicar el mismo entorno siempre. Igual que se tienen scripts para el software, se tienen scripts para la infraestructura. Es el IaC, Infraestructure as Code. Amazon tiene AWS CLI, AWS cloudformation (yaml), específicas de él. Ansible y Terraform se pueden emplear en cualquier plataforma. En el curso se verán las de Amazon.
1.	Insalar el CLI de amazon
a.	Entramos en AWS details y pulsamos show en aws cli.
b.	Instalamos cli en nuestra máquina local. 
i.	Buscar aws cli en Google.
ii.	Entramos en instalar o actualizar en el primer resultado.
iii.	Coger el de Linux y copiarlo en consola donde está la práctica (no importa dónde se lanza el instalador, porque se instala en otro directorio. El código fuente se queda en la practica 9, se puede borrar).
iv.	Configurar usuario y contraseña: aws configure para que salga el asistente de configuración. Rellenar todo con bla o con lo que sea y creará dos archivos: uno llamado credentials que cambiaremos más adelante y otro llamado config, que permite configurar región y formato de salida.
v.	Para que esto sea seguro, se usan tokens en lugar de poner usuario y contraseña. Para conseguirlas, las buscamos en aws cli: ahí obtendremos la aws_secret_key_id, aws_secret_access_key y aws_session_token. Estas claves tendremos que cambiarlas cada vez que levantemos el servidor. Para cambiarlas en el directorio se emplea el comando code /home/usuario/.aws/credentials y allí se copian. En este fichero suele haber diferentes tokens para diferentes clientes, [default] es el que se crea pero se podría añadir debajo [proyectoA], [proyectoB], etc.
vi.	Lo mismo para el archivo config:  code /home/usuario/-aws/config y se cambia el contenido: región = us-east-1 y output = json.
vii.	Para comprobar si ha funcionado, ejecutar el comando aws ec2 (ec2 es el servicio) describe-instances y tiene que devolver un json con las instancias creadas.
2.	Creación de un grupo de seguridad: ejecutar el comando aws ec2 create-security-group --description <value> --group-name <value>. Los grupos de seguridad se empleaban para establecer las reglas de entrada (el tráfico al que se permite la entrada) estableciendo los puertos. Para comprobar si se ha creado, se ejecuta aws ec2 describe-security-groups y debe devolver un json con la información de todos los grupos de seguridad creados en amazon. Si sólo queremos la información de un grupo, se ejecuta aws ec2 describe-security-groups --group-name frontend-sg
3.	Añadir reglas de entrada al grupo de seguridad: igual que en la interfaz de AWS pero con comando, ejecutando este: aws ec2 authorize-security-group-ingress[--group-id <value>][--group-name <value>][--ip-permissions <value>][--dry-run | --no-dry-run][--tag-specifications <value>][--protocol <value>][--port <value>][--cidr <value>][--source-group <value>][--group-owner <value>][--cli-input-json | --cli-input-yaml][--generate-cli-skeleton <value>]. Hay que ejecutar este comando por cada puerto que se abra (por cada regla de seguridad añadida).
4.	Eliminar un grupo de seguridad: aws ec2 delete-security-group[--group-id <value>][--group-name <value>][--dry-run | --no-dry-run][--cli-input-json | --cli-input-yaml][--generate-cli-skeleton <value>]. No hay un comando que borre todos los comandos, así que se obtiene m ediante in comando un listado con todos los id de todos los grupos y esa información se manda a otro comando. El parámetro query permite obtener ciertos datos dentro de un json: en el ejemplo de los apuntes, cuando pone –query “SecurityGroups[*].GroupId” de todos los elementos de segurityGroups se quiere recoger el id como GroupId. Con –output text se obtiene el resultado del comando. La respuesta se puede obtener de diferentes formas, aunque se haya puesto json por defecto.
5.	Crear una instancia en EC2: se emplea el comando aws ec2 run-instances. Los parámetros se sacan de la interfaz de amazon: el ID de AMI se obtiene al crear una instancia (el de Ubuntu será ami-06878d265978313ca), al elegir un sistema operativo u otro. Count indica la cantidad de instancias que se están creando, el tipo de insancia será t2.micro (ambos valores van por defecto). En la práctica se ha copiado directamente el comando de los apuntes. 
6.	Durante la creación de la instancia, el parámetro user-data permite pasarle un comando o una lista de comandos o con file un script (como los de bash). Por tanto, permite crear la instancia y preparar LAMP y todo lo que se tenga en estos scripts.
7.	Creamos un fichero install_nginx.sh con los comandos sudo apt update y sudo apt install -y nginx y, tras esto y en el mismo directorio donde se encuentra este fichero, se lanza el comando aws ec2 run-instances   --image-id ami-050406429a71aaa64 --count 1 --instance-type t2.micro --key-name vockey --security-groups frontend-sg --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=frontend-01}]" --user-data file://install_nginx.sh. Así, se crea una instancia con nginx instalado.
VARIABLE = $(comando) en bash ejecuta el comando que haya dentro de los paréntesis y los almacena en la variable
AWS CloudFormation
CF es un servicio que permite automatizar la creación y gestión de recursos en AWS a partir de una plantilla. Es exclusivo de Amazon y en él no están disponibles todos los servicios de Amazon. 
La plantilla se hará en YAML.
Stacks: una pila o caja con los recursos, similar a Docker.
1.	Clonar el repo de JJ en el punto 1.9 
2.	En el ejemplo 1 se define lo que es cada cosa
3.	En AWS, buscar cloudformation.
a.	Crear plantilla con recursos
b.	Las plantillas puede estar lista, usar una de ejemplo o crearla. Se elige la primera opción, la plantilla está lista.
c.	En especificar plantilla sale que la URL está en S3, que es un bucket con diferentes cosas (¿) para crear el stack.
d.	Se selecciona cargar archvo de plantilla y se selecciona el ejemplo 1 del repo clonado.
e.	Se da a siguiente, se selecciona nombre (ejemplo-01) y ya todo siguiente.
f.	Una vez creada se ve en instancias de ec2 y se elimina.

