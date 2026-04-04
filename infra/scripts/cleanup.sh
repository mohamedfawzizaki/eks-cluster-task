#!/bin/bash

set -e

echo "======================================"
echo "🚨 Starting EKS Cleanup Before Destroy"
echo "======================================"

# 🔹 Config
CLUSTER_NAME=${CLUSTER_NAME:-"zaki-eks-cluster"}
REGION=${AWS_REGION:-"us-east-2"}
AWS_PROFILE=${AWS_PROFILE:-"AdministratorAccess-727245885999"}

echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Profile: $AWS_PROFILE"

# 🔹 Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME --profile $AWS_PROFILE

# 🔹 Check cluster access
echo "Checking cluster connectivity..."
kubectl get nodes || { echo "❌ Cannot access cluster. It might already be destroyed."; exit 1; }

# 🔥 Delete Ingresses (ALBs)
echo "Deleting Ingress resources (ALBs)..."
kubectl delete ingress --all -A || true

# 🔥 Delete LoadBalancers (NLBs/Classic)
echo "Safely deleting only LoadBalancer services..."
kubectl get svc -A -o go-template='{{range .items}}{{if eq .spec.type "LoadBalancer"}}{{.metadata.namespace}} {{.metadata.name}}{{"\n"}}{{end}}{{end}}' | while read ns svc; do 
  if [ -n "$svc" ]; then
    echo "Deleting LoadBalancer: $svc in namespace $ns"
    kubectl delete svc -n "$ns" "$svc"
  fi
done

# ⏳ Wait for AWS Load Balancers to be physically deleted
echo "Waiting for AWS to physically destroy Load Balancers (this can take ~1 minute)..."
sleep 60

# 🔥 Delete PVCs (EBS volumes)
echo "Deleting persistent volume claims (EBS drives)..."
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
  if [[ "$ns" != "kube-system" && "$ns" != "kube-public" && "$ns" != "kube-node-lease" && "$ns" != "default" && "$ns" != "dev" ]]; then
    echo "Deleting namespace: $ns"
    kubectl delete ns $ns --ignore-not-found
  fi
done


# ⏳ Wait for final resources cleanup
echo "Waiting 30s for resources to fully terminate..."
sleep 30

echo "✅ Cleanup completed successfully. You may now run 'terraform destroy'."
echo "======================================"