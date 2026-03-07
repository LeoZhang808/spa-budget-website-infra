#!/bin/bash
set -euo pipefail

exec > /var/log/user-data.log 2>&1

echo "=== user-data bootstrap started at $(date) ==="

apt-get update
apt-get install -y docker.io docker-compose-plugin git awscli

usermod -aG docker ubuntu

systemctl enable docker
systemctl start docker

touch /tmp/user-data-complete

echo "=== user-data bootstrap completed at $(date) ==="
