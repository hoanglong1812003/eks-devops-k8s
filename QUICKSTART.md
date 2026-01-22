# 🚀 Quick Start Guide

## ⚠️ QUAN TRỌNG: Xóa resources cũ trước

Nếu bạn đã deploy trước đó và gặp lỗi "immutable field", chạy cleanup:

```bash
# Linux/Mac
chmod +x cleanup.sh
./cleanup.sh

# Windows
cleanup.bat
```

Hoặc xóa thủ công:

```bash
kubectl delete namespace dev
kubectl wait --for=delete namespace/dev --timeout=120s
```

---

## Deploy mới hoàn toàn

### 1. Deploy ArgoCD Applications

```bash
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml
```

### 2. Tạo ECR Secret

```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=145023123305.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n dev
```

### 3. Tạo Chatbot Secret

```bash
kubectl create secret generic chatbot-secret \
  --from-literal=OPENAI_API_KEY=sk-your-openai-key-here \
  -n dev
```

### 4. Sync ArgoCD (chọn 1 trong 3 cách)

```bash
# Cách 1: Dùng ArgoCD CLI (nếu đã cài)
argocd app sync chatbot-app
argocd app sync multistage-app

# Cách 2: Dùng kubectl
kubectl patch application chatbot-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
kubectl patch application multistage-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Cách 3: Đợi ArgoCD tự sync (3 phút)
# ArgoCD sẽ tự động detect thay đổi và sync
```

### 5. Verify

```bash
# Check pods (phải có 2 pods: 1 chatbot + 1 multistage)
kubectl get pods -n dev

# Expected output:
# NAME                                  READY   STATUS    RESTARTS   AGE
# dev-chatbot-app-xxx                   1/1     Running   0          2m
# dev-multistage-app-xxx                1/1     Running   0          2m

# Check services
kubectl get svc -n dev

# Port forward để test
kubectl port-forward svc/dev-chatbot-app 8501:80 -n dev
```

---

## Update Image Tag

```bash
# Chatbot
cd apps/chatbot/overlays/dev
kustomize edit set image fcj-chatbot=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:abc123

# Multistage
cd apps/multistage/overlays/dev
kustomize edit set image fcj-multistage=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-multistage:xyz789

# Commit & push
git add .
git commit -m "Update image tags"
git push

# ArgoCD tự động deploy
```

---

## Troubleshooting

### Lỗi "immutable field"

```bash
# Xóa namespace và deploy lại
kubectl delete namespace dev
kubectl wait --for=delete namespace/dev --timeout=120s
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml
```

### Pods không start

```bash
# Check logs
kubectl logs -f deployment/dev-chatbot-app -n dev

# Check events
kubectl get events -n dev --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod -l app=chatbot-app -n dev
```

### ArgoCD không sync

```bash
# Force sync
argocd app sync chatbot-app --force --prune
argocd app sync multistage-app --force --prune
```
