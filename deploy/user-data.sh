#!/bin/bash
set -euo pipefail

echo "=== user-data bootstrap started at $(date) ==="

# Trap to log failure point (helps debug when cloud-init reports scripts-user failed)
trap 'echo "FAILED at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

# Install dependencies (AL2023 minimal already has curl-minimal; curl and curl-minimal conflict)
# This also validates network - dnf will fail clearly if no internet
echo "Installing docker, git, nginx..."
dnf install -y docker git nginx

# Verify GitHub reachability (needed for git clone in deploy workflow)
echo "Checking GitHub reachability..."
if ! curl -sf --connect-timeout 10 -o /dev/null https://github.com; then
  echo "ERROR: Cannot reach GitHub. Check security group allows outbound HTTPS."
  exit 1
fi

# aws-cli is optional; install if available (package name varies)
dnf install -y aws-cli 2>/dev/null || dnf install -y awscli 2>/dev/null || true

# Docker Compose is not in AL2023 default repos; install as plugin
mkdir -p /usr/libexec/docker/cli-plugins
ARCH=$(uname -m)
curl -fsSL "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-${ARCH}" \
  -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# ec2-user exists on AL2023 AMI; add to docker group
if id ec2-user &>/dev/null; then
  usermod -aG docker ec2-user
fi

systemctl enable docker
systemctl start docker

systemctl enable nginx
systemctl start nginx

touch /tmp/user-data-complete

echo "=== user-data bootstrap completed at $(date) ==="
