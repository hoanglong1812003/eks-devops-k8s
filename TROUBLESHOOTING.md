# 🔧 Fix Deployment Errors

## Nguyên nhân lỗi:

1. **PVC đã tồn tại** với storage 1Gi, không thể patch thành 5Gi
2. **Deployment đã tồn tại** với label selector khác, không thể thay đổi

## ✅ Giải pháp: Xóa và deploy lại

### Option 1: Xóa toàn bộ namespace (CẢNH BÁO: Mất data)

```bash
# Xóa namespace dev (bao gồm tất cả resources)
kubectl delete namespace dev

# Đợi namespace bị xóa hoàn toàn
kubectl get namespace dev

# Deploy lại
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml

# ArgoCD sẽ tự tạo namespace và deploy
argocd app sync chatbot-app
argocd app sync multistage-app
```

### Option 2: Xóa từng resource cụ thể (Giữ lại data nếu có)

```bash
# Xóa PVC cũ (CẢNH BÁO: Mất vectorstore data)
kubectl delete pvc dev-chatbot-pvc -n dev

# Xóa Deployment cũ
kubectl delete deployment dev-chatbot-app -n dev

# Sync lại ArgoCD
argocd app sync chatbot-app --force --prune
```

### Option 3: Backup data trước khi xóa

```bash
# 1. Backup vectorstore data (nếu cần)
kubectl exec -n dev deployment/dev-chatbot-app -- tar czf /tmp/vectorstore-backup.tar.gz /app/vectorstore
kubectl cp dev/dev-chatbot-app-xxx:/tmp/vectorstore-backup.tar.gz ./vectorstore-backup.tar.gz

# 2. Xóa resources
kubectl delete pvc dev-chatbot-pvc -n dev
kubectl delete deployment dev-chatbot-app -n dev

# 3. Deploy lại
argocd app sync chatbot-app --force

# 4. Restore data
kubectl cp ./vectorstore-backup.tar.gz dev/dev-chatbot-app-xxx:/tmp/
kubectl exec -n dev deployment/dev-chatbot-app -- tar xzf /tmp/vectorstore-backup.tar.gz -C /
```

### Option 4: Sửa label selector conflict

```bash
# Kiểm tra label hiện tại
kubectl get deployment dev-chatbot-app -n dev -o yaml | grep -A5 selector

# Nếu label không khớp, xóa deployment
kubectl delete deployment dev-chatbot-app -n dev

# Sync lại
argocd app sync chatbot-app
```

## 🚀 Recommended: Clean Deploy

```bash
# 1. Xóa ArgoCD Applications
kubectl delete -f argocd/chatbot-app.yaml
kubectl delete -f argocd/multistage-app.yaml

# 2. Xóa namespace
kubectl delete namespace dev

# 3. Đợi 30 giây
sleep 30

# 4. Deploy lại từ đầu
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml

# 5. Tạo secrets
kubectl create namespace dev
kubectl create secret docker-registry ecr-secret \
  --docker-server=145023123305.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n dev

kubectl create secret generic chatbot-secret \
  --from-literal=OPENAI_API_KEY=sk-your-key-here \
  -n dev

# 6. Sync ArgoCD
argocd app sync chatbot-app
argocd app sync multistage-app
```

## 🔍 Kiểm tra sau khi fix

```bash
# Check PVC
kubectl get pvc -n dev
# Phải thấy: dev-chatbot-pvc với 5Gi

# Check Deployment
kubectl get deployment -n dev
# Phải thấy: dev-chatbot-app với 2/2 READY

# Check pods
kubectl get pods -n dev
# Phải thấy: 2 pods chatbot + 2 pods multistage đang Running
```

## 🛡️ Tránh lỗi này trong tương lai

1. **Không thay đổi PVC size** sau khi đã tạo
2. **Không thay đổi label selector** trong Deployment
3. **Dùng ArgoCD prune** để tự động xóa resources cũ
4. **Test với kustomize build** trước khi apply
