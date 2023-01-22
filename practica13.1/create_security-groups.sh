#!/bin/bash

set -x

# Deshabilitar paginación
export AWS_PAGER=""

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
