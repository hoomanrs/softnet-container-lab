#!/bin/bash
set -euo pipefail
# Build Docker image script for basic-lab

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
CONTAINERLAB_DIR="${PROJECT_ROOT}/containerlab"

echo "=== Build Docker Image for basic-lab =="

# Navigate to containerlab directory
cd "${CONTAINERLAB_DIR}"

# Build the image
echo ""
echo "== Building clab-ubuntu-softnet:latest =="
docker build -t clab-ubuntu-softnet:latest .

# Verify build
echo ""
echo "== Verification =="
docker images clab-ubuntu-softnet:latest

echo ""
echo "=== Build Complete =="
echo ""
echo "Image: clab-ubuntu-softnet:latest"
echo ""
echo "Next steps:"
echo "  1. Deploy topology: cd ${CONTAINERLAB_DIR} && ./deploy.sh"
echo "  2. Or run: containerlab deploy -t basic-lab.clab.yml"
echo ""
