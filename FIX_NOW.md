# 🔥 FIX LỖI NGAY

## Chạy các lệnh này theo thứ tự:

### 1. Xóa toàn bộ resources cũ trên cluster

```bash
# Xóa ArgoCD Applications
kubectl delete application chatbot-app -n argocd --ignore-not-found=true
kubectl delete application multistage-app -n argocd --ignore-not-found=true

# Xóa namespace dev (bao gồm PVC, Deployment, Service...)
kubectl delete namespace dev --ignore-not-found=true

# Đợi namespace bị xóa hoàn toàn (QUAN TRỌNG!)
kubectl wait --for=delete namespace/dev --timeout=120s
```

### 2. Deploy lại từ đầu

```bash
# Deploy ArgoCD Applications
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml

# Tạo ECR secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=145023123305.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n dev

# Tạo chatbot secret
kubectl create secret generic chatbot-secret \
  --from-literal=OPENAI_API_KEY=sk-your-key \
  -n dev

# Sync ArgoCD
argocd app sync chatbot-app
argocd app sync multistage-app
```

### 3. Verify

```bash
# Check pods (phải có 4 pods running)
kubectl get pods -n dev

# Expected:
# dev-chatbot-app-xxx      2/2  Running
# dev-multistage-app-xxx   2/2  Running
```

---

## Tại sao phải xóa namespace?

- **PVC**: Không thể thay đổi storage size sau khi tạo
- **Deployment**: Label selector không thể thay đổi
- **Giải pháp**: Xóa toàn bộ và tạo mới với config đúng

---

## Đã tối ưu:

✅ PVC: 5Gi → 1Gi (match với cluster hiện tại)
✅ Chatbot resources: 512Mi/250m → 256Mi/100m
✅ Multistage resources: 256Mi/100m → 128Mi/50m
✅ Xóa commonLabels gây conflict
✅ Xóa file thừa (base/, overlays/ cũ)
