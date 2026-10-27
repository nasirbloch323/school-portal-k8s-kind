#!/usr/bin/env bash
# ============================================================
# deploy.sh - Poora project ek command se deploy karta hai
# ============================================================
# Chalane ka tareeqa:   ./deploy.sh
# Pehle ye chalane ke liye permission dein:   chmod +x deploy.sh

# set -e : koi bhi command fail ho to script wahin ruk jaye
# set -u : undefined variable use ho to error do
# set -o pipefail : pipe (|) mein koi command fail ho to bhi error maano
set -euo pipefail

# ---- Settings (variables) ----
CLUSTER_NAME="school"            # kind cluster ka naam
IMAGE="school-portal:1.0"        # image ka naam:version (Deployment mein bhi yehi hai)
NAMESPACE="school-portal"        # hamara namespace

# ---- Step 0: zaroori tools check karo ----
for tool in docker kind kubectl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' install nahi hai. Pehle isse install karein."
    exit 1
  fi
done

# ---- Step 1: Docker image banao ----
# "docker build" Dockerfile padh kar image banata hai.
# -t = tag (naam:version),  "." = current folder mein Dockerfile dhoondo
echo ">>> Step 1/5: Docker image ban rahi hai: $IMAGE"
docker build -t "$IMAGE" .

# ---- Step 2: Kind cluster banao (agar pehle se nahi hai) ----
echo ">>> Step 2/5: Kind cluster check/create"
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' pehle se maujood hai, dobara nahi banate."
else
  kind create cluster --name "$CLUSTER_NAME" --config k8s/00-kind-cluster.yaml
fi

# ---- Step 3: Image ko kind ke andar load karo ----
# Kind ke nodes alag Docker containers hain, unhe aapke laptop ki images
# nazar nahi ati. Isliye image ko un tak pohanchana parta hai.
# (Real cluster mein hum image ko registry jaise Docker Hub par push karte hain.)
echo ">>> Step 3/5: Image kind cluster mein load ho rahi hai"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

# ---- Step 4: YAML files apply karo ----
# "kubectl apply" ka matlab: "ye jo file mein likha hai, cluster ko waisa bana do".
# Files number order mein apply hongi: namespace pehle, phir configmap, deployment, service.
echo ">>> Step 4/5: Kubernetes resources apply ho rahe hain"
kubectl apply -f k8s/01-namespace.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/03-deployment.yaml
kubectl apply -f k8s/04-service.yaml

# ---- Step 5: Intezar karo jab tak Pods ready na ho jayen ----
echo ">>> Step 5/5: Pods ready hone ka intezar..."
kubectl rollout status deployment/school-portal -n "$NAMESPACE" --timeout=120s

echo ""
echo "=========================================="
echo " Deploy mukammal! Browser mein kholein:"
echo "   http://localhost:8080"
echo "=========================================="
echo ""
echo "Status dekhne ke liye:  kubectl get all -n $NAMESPACE"
