#!/bin/bash
set -euo pipefail

# Runs on RC EC2 via SSH. Expects env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
# AWS_SESSION_TOKEN, AWS_REGION, AWS_ACCOUNT_ID, IMAGE_TAG
# IMAGE_TAG is the RC label (e.g. 1.0.0-rc1), not a UUID.

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY required}"
: "${AWS_SESSION_TOKEN:?AWS_SESSION_TOKEN required}"
: "${AWS_REGION:?AWS_REGION required}"
: "${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID required}"
: "${IMAGE_TAG:?IMAGE_TAG required}"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "=== ECR login ==="
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "=== Pulling images (tag: $IMAGE_TAG) ==="
docker pull "$ECR_REGISTRY/budget-app-frontend:$IMAGE_TAG"
docker pull "$ECR_REGISTRY/budget-app-backend:$IMAGE_TAG"

echo "=== Starting app ==="
export ECR_REGISTRY IMAGE_TAG
docker compose -f docker-compose.rc.yml up -d --force-recreate

echo "=== Pruning dangling images ==="
docker image prune -f

echo "=== RC deploy complete ==="
