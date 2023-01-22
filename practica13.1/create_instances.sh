#!/bin/bash 

# Crear un script para crear la infraestructura de la práctica 9
set -x

# Deshabilitación de la paginación 
export AWS_PAGER=""

# Exportación del fichero de variables
source variables.sh

# Crear una instancia para el frontend
aws ec2 run-instances \
--image-id $AMI_ID \
--count $COUNT \
--instance-type $INSTANCE_TYPE \
--security-groups $SECURITY_GROUP_FRONTEND \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_FRONTEND}]"

# Crear una instancia para el backend
aws ec2 run-instances \
--image-id $AMI_ID \
--count $COUNT \
--instance-type $INSTANCE_TYPE \
--security-groups $SECURITY_GROUP_BACKEND \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_BACKEND}]"