#!/bin/bash 
set -x

# Deshabilitación de paginación
export AWS_PAGER=""

# Exportación del fichero de variables
source variables.sh

# Obtener el id de la instancia a partir de su nombre
INSTANCE_ID=$(
aws ec2 describe-instances \
--filters "Name=tag:Name,Values=$INSTANCE_NAME_FRONTEND" \
--"Name=instance-state-name,Values=running" \
--query "Reservations[*].Instances[*].InstanceId" \
--output text
)

# Creación de la IP elástica
ELASTIC_IP=$(aws ec2 allocate-address --query PublicIp --output text)

# Asociación de la IP elástica a la instancia de frontend
aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip $ELASTIC_IP