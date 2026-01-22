# eks-devops-k8s

GitOps repository để deploy 2 ứng dụng độc lập lên EKS với ArgoCD.

## 📁 Cấu trúc

```
eks-devops-k8s/
├── apps/
│   ├── chatbot/          # Chatbot app (2 replicas)
│   └── multistage/       # Multistage app (2 replicas)
├── argocd/
│   ├── chatbot-app.yaml
│   └── multistage-app.yaml
├── cleanup.sh            # Xóa resources cũ
└── QUICKSTART.md         # Hướng dẫn deploy
```

## 🚀 Quick Deploy

```bash
# 1. Xóa resources cũ (nếu có)
./cleanup.sh  # hoặc cleanup.bat trên Windows

# 2. Deploy với ArgoCD
kubectl apply -f argocd/chatbot-app.yaml
kubectl apply -f argocd/multistage-app.yaml

# 3. Tạo secrets
kubectl create secret docker-registry ecr-secret \
  --docker-server=145023123305.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n dev

kubectl create secret generic chatbot-secret \
  --from-literal=OPENAI_API_KEY=sk-xxx \
  -n dev

# 4. Sync
argocd app sync chatbot-app
argocd app sync multistage-app
```

## 📊 Resources

| App | Replicas | CPU | Memory | Storage |
|-----|----------|-----|--------|---------|
| Chatbot | 2 | 100m-250m | 256Mi-512Mi | 1Gi PVC |
| Multistage | 2 | 50m-100m | 128Mi-256Mi | - |

## 🔄 Update Image

```bash
cd apps/chatbot/overlays/dev
kustomize edit set image fcj-chatbot=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:NEW_TAG
git commit -am "Update chatbot to NEW_TAG"
git push
```

ArgoCD tự động deploy trong 3 phút.

## 🔗 Images

- Chatbot: `145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:0739900c3242d54aaf35e2ba679eb339f6bbcb94`
- Multistage: `145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-multistage:latest`
