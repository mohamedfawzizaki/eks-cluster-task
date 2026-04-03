#!/bin/bash

set -e

echo "======================================"
echo "🚨 Starting EKS Cleanup Before Destroy"
echo "======================================"

# 🔹 Config
CLUSTER_NAME=${CLUSTER_NAME:-"zaki-eks-task"}
REGION=${AWS_REGION:-"us-east-2"}

echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# 🔹 Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# 🔹 Check cluster access
echo "Checking cluster connectivity..."
kubectl get nodes || { echo "❌ Cannot access cluster"; exit 1; }

# 🔥 Delete LoadBalancers (services)
echo "Deleting LoadBalancer services..."
kubectl delete svc --all -A || true

# 🔥 Delete Ingresses
echo "Deleting ingresses..."
kubectl delete ingress --all -A || true

# 🔥 Delete PVCs (EBS volumes)
echo "Deleting persistent volume claims..."
kubectl delete pvc --all -A || true

# 🔥 Delete Helm releases (if Helm used)
if command -v helm &> /dev/null; then
  echo "Deleting Helm releases..."
  helm ls -A -q | while read release; do
    NAMESPACE=$(helm ls -A | grep $release | awk '{print $2}')
    echo "Deleting Helm release $release in namespace $NAMESPACE"
    helm uninstall $release -n $NAMESPACE || true
  done
fi

# 🔥 Delete all non-system namespaces
echo "Deleting custom namespaces..."
kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | while read ns; do
  if [[ "$ns" != "kube-system" && "$ns" != "kube-public" && "$ns" != "default" ]]; then
    echo "Deleting namespace: $ns"
    kubectl delete ns $ns --ignore-not-found
  fi
done

# ⏳ Wait for resources cleanup
echo "Waiting for resources to terminate..."
sleep 30

# 🔍 Final check
echo "Remaining services:"
kubectl get svc -A || true

echo "Remaining PVCs:"
kubectl get pvc -A || true

echo "======================================"
echo "✅ Cleanup completed successfully"
echo "======================================"