#!/usr/bin/env bash
# ============================================================
# cleanup.sh - Sab kuch delete karke system saaf karta hai
# ============================================================
set -euo pipefail

CLUSTER_NAME="school"

echo ">>> Kind cluster '$CLUSTER_NAME' delete ho raha hai..."
kind delete cluster --name "$CLUSTER_NAME"

# Docker image bhi hata do (agar ho). "|| true" = na ho to error na do.
docker rmi school-portal:1.0 2>/dev/null || true

echo "Safai mukammal."
