#!/bin/bash

# Unión de todos los scripts para crear la infraestructura de la práctica 9

set -x

# Deshabilitar paginación
export AWS_PAGER=""

# 1. Crear grupos de seguridad

# Creación del grupo de seguridad de frontend:
aws ec2 create-security-group \
--description "Grupo de seguridad para frontend" \
--group-name frontend-sg

# Adición de reglas al grupo de seguridad de frontend: 
aws ec2 authorize-security-group-ingress \
--group-name frontend-sg \
--protocol tcp \
--port 22 \
--cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
--group-name frontend-sg \
--protocol tcp \
--port 80 \
--cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
--group-name frontend-sg \
--protocol tcp \
--port 443 \
--cidr 0.0.0.0/0

# Creación del grupo de seguridad de backend:
aws ec2 create-security-group \
--description "Grupo de seguridad para backend" \
--group-name backend-sg

# Adición de reglas al grupo de seguridad de backend: 
aws ec2 authorize-security-group-ingress \
--group-name backend-sg \
--protocol tcp \
--port 22 \
--cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
--group-name backend-sg \
--protocol tcp \
--port 3306 \
--cidr 0.0.0.0/0

# 2. Crear instancias

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

# 3. Crear IPs elásticas 

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