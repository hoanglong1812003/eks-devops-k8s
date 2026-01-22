@echo off
REM Cleanup script - Xóa toàn bộ resources cũ trên cluster

echo 🧹 Cleaning up old resources...

REM Xóa ArgoCD Applications
echo Deleting ArgoCD Applications...
kubectl delete application chatbot-app -n argocd --ignore-not-found=true
kubectl delete application multistage-app -n argocd --ignore-not-found=true

REM Xóa namespace dev
echo Deleting namespace dev...
kubectl delete namespace dev --ignore-not-found=true

REM Đợi 30 giây
echo Waiting for cleanup...
timeout /t 30 /nobreak

echo ✅ Cleanup completed!
echo.
echo Next steps:
echo 1. kubectl apply -f argocd/chatbot-app.yaml
echo 2. kubectl apply -f argocd/multistage-app.yaml
echo 3. Create secrets (see QUICKSTART.md)
