# Crear un script para eliminar la infraestructura de la práctica 9 

#!/bin/bash 

set -x

# Deshabilitar la paginación
export AWS_PAGER=""

# 1. Eliminar las IP elásticas:

# Obtención de la lista de las id de las direcciones IP elásticas públicas
ELASTIC_IP_IDS=$(
    aws ec2 describe-addresses \
    --query Addresses[*].AllocationId \
    --output text
)

# Recorrer la lista de id de las IP elásticas para eliminarlas
for ID in $ELASTIC_IP_IDS
do 
    echo "Eliminando IP elástica de id $ID"
    aws ec2 release-address --allocation-id $ID
done

# 2. Eliminar los grupos de seguridad:

# Almacenamiento de la lista con los id de las instancias EC2
SG_ID_LIST=$(
    aws ec2 describe-security-groups \
    --query "SecurityGroups[*].GroupId" \
    --output text
)

# Recorrer la lista de id de los grupos de seguridad y eliminar las instancias
for ID in $SG_ID_LIST
do
    echo "Eliminando instancia del grupo de seguridad con id $ID"
    aws ec2 delete-security-group --group-id $ID
done

# 3. Eliminar las instancias

# Obtención de una lista con los id de las instancias en ejecución
EC2_ID_LIST=$(
    aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text
)

# Eliminación de las instancias en ejecución
aws ec2 terminate-instances \
--instance-ids $EC2_ID_LIST