#!/bin/bash

# Script que muestra el nombre de todas las instancias EC2 en ejecución junto a su IP pública

# Obtener todos los nombres de las instancias
INSTANCES_NAME=$(
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=" \
    --output text
)

# Obtener la IP pública de una instancia con un nombre concreto:
INSTANCES_PUBLIC_IP=$(
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text
)

# Mostrar ambos datos con un bucle
