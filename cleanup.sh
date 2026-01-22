#!/bin/bash
# Cleanup script - Xóa toàn bộ resources cũ trên cluster

echo "🧹 Cleaning up old resources..."

# Xóa ArgoCD Applications
echo "Deleting ArgoCD Applications..."
kubectl delete application chatbot-app -n argocd --ignore-not-found=true
kubectl delete application multistage-app -n argocd --ignore-not-found=true

# Xóa namespace dev (bao gồm tất cả resources)
echo "Deleting namespace dev..."
kubectl delete namespace dev --ignore-not-found=true

# Đợi namespace bị xóa hoàn toàn
echo "Waiting for namespace to be deleted..."
kubectl wait --for=delete namespace/dev --timeout=120s 2>/dev/null || true

echo "✅ Cleanup completed!"
echo ""
echo "Next steps:"
echo "1. kubectl apply -f argocd/chatbot-app.yaml"
echo "2. kubectl apply -f argocd/multistage-app.yaml"
echo "3. Create secrets (see QUICKSTART.md)"
