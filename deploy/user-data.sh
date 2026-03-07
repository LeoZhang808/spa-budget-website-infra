#!/bin/bash
set -euo pipefail

exec > /var/log/user-data.log 2>&1

echo "=== user-data bootstrap started at $(date) ==="

dnf update -y
dnf install -y docker git awscli curl

# Docker Compose is not in AL2023 default repos; install as plugin
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

usermod -aG docker ec2-user

systemctl enable docker
systemctl start docker

touch /tmp/user-data-complete

echo "=== user-data bootstrap completed at $(date) ==="
