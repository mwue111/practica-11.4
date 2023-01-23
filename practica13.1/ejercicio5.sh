#!/bin/bash

# Script que muestra el nombre de todas las instancias EC2 en ejecución junto a su IP pública

EC2_ID_LIST=$(aws ec2 describe-instances \
                --filters "Name=instance-state-name,Values=running" \
                --query 'Reservations[].Instances[].[Tags[?Key==`Name`] | [0].Value, PublicIpAddress]' \
                --output text)
