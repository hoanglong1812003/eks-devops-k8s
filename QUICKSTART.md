# 🚀 Quick Start Guide

## Deploy cả 2 apps trong 5 phút

### 0. Xóa resources cũ (nếu đã deploy trước đó)

```bash
# Xóa namespace cũ để tránh conflict
kubectl delete namespace dev

# Đợi namespace bị xóa hoàn toàn
kubectl wait --for=delete namespace/dev --timeout=60s
```

### 1. Tạo ECR Secret

```bash
# Tạo namespace
kubectl create namespace dev

# Tạo ECR secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=145023123305.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n dev
```

### 2. Tạo Secret cho Chatbot (nếu cần)

```bash
# Tạo secret với OpenAI API key
kubectl create secret generic chatbot-secret \
  --from-literal=OPENAI_API_KEY=sk-your-key-here \
  -n dev
```

### 3. Deploy với ArgoCD

```bash
# Deploy cả 2 apps
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml

# Kiểm tra
argocd app list
argocd app sync chatbot-app
argocd app sync multistage-app
```

### 4. Verify

```bash
# Check pods (mỗi app có 2 pods)
kubectl get pods -n dev

# Expected:
# NAME                                  READY   STATUS    RESTARTS   AGE
# dev-chatbot-app-xxx                   2/2     Running   0          2m
# dev-multistage-app-xxx                2/2     Running   0          2m

# Check services
kubectl get svc -n dev

# Port forward để test
kubectl port-forward svc/dev-chatbot-app 8501:80 -n dev
kubectl port-forward svc/dev-multistage-app 8080:80 -n dev
```

## Update Image Tag

```bash
# Chatbot
cd apps/chatbot/overlays/dev
kustomize edit set image fcj-chatbot=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:NEW_TAG

# Multistage
cd apps/multistage/overlays/dev
kustomize edit set image fcj-multistage=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-multistage:NEW_TAG

# Commit & push
git add .
git commit -m "Update image tags"
git push

# ArgoCD sẽ tự động deploy trong 3 phút
```

## Troubleshooting

```bash
# Xem logs
kubectl logs -f deployment/dev-chatbot-app -n dev
kubectl logs -f deployment/dev-multistage-app -n dev

# Describe pod
kubectl describe pod -l app=chatbot-app -n dev

# ArgoCD sync status
argocd app get chatbot-app
argocd app sync chatbot-app --force
```
