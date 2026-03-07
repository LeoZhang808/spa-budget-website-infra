#!/bin/bash
set -euo pipefail

exec > /var/log/user-data.log 2>&1

echo "=== user-data bootstrap started at $(date) ==="

# Skip dnf update - slow and can cause timeout; base AL2023 AMI is fresh enough
dnf install -y docker git curl

# aws-cli is optional; install if available (package name varies)
dnf install -y aws-cli 2>/dev/null || dnf install -y awscli 2>/dev/null || true

# Docker Compose is not in AL2023 default repos; install as plugin
mkdir -p /usr/libexec/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

usermod -aG docker ec2-user

systemctl enable docker
systemctl start docker

touch /tmp/user-data-complete

echo "=== user-data bootstrap completed at $(date) ==="
