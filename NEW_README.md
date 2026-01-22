# eks-devops-k8s

GitOps repository để deploy nhiều ứng dụng độc lập lên EKS cluster với ArgoCD.

## 📁 Cấu trúc Multi-App

```
eks-devops-k8s/
├── apps/
│   ├── chatbot/                    # Chatbot application
│   │   ├── base/
│   │   │   ├── deployment.yaml     # 2 replicas + health checks
│   │   │   ├── service.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── pvc.yaml
│   │   │   ├── secret.yaml.example
│   │   │   └── kustomization.yaml
│   │   └── overlays/
│   │       └── dev/
│   │           ├── kustomization.yaml
│   │           └── patch.yaml
│   │
│   └── multistage/                 # Multistage application
│       ├── base/
│       │   ├── deployment.yaml     # 2 replicas + health checks
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── kustomization.yaml
│       └── overlays/
│           └── dev/
│               ├── kustomization.yaml
│               └── patch.yaml
│
├── argocd/
│   ├── chatbot-app.yaml           # ArgoCD Application cho chatbot
│   └── multistage-app.yaml        # ArgoCD Application cho multistage
│
└── README.md
```

## 🎯 Kiến trúc & Thiết kế

### ✅ Tại sao cấu trúc này dễ scale?

1. **Tách biệt hoàn toàn**: Mỗi app có thư mục riêng → thêm app mới chỉ cần copy structure
2. **Base + Overlays**: Dùng lại base cho nhiều môi trường (dev/staging/prod)
3. **Kustomize native**: Không phụ thuộc Helm, dễ customize từng layer
4. **ArgoCD per-app**: Mỗi app deploy độc lập, rollback độc lập

### ✅ Tại sao phù hợp GitOps?

1. **Git = Single Source of Truth**: Mọi thay đổi qua Git commit
2. **Automated Sync**: ArgoCD tự động detect & deploy khi có thay đổi
3. **Self-Heal**: Tự động fix nếu ai đó kubectl apply thủ công
4. **Audit Trail**: Git history = deployment history

### ✅ Tại sao deploy nhiều app không xung đột?

1. **Namespace isolation**: Cả 2 app đều trong namespace `dev`
2. **Name prefix**: Kustomize tự động thêm `dev-` prefix
3. **Label selector**: Mỗi app có labels riêng
4. **ArgoCD Application**: Mỗi app = 1 Application resource riêng

## 🚀 Deployment

### Prerequisites

- EKS cluster đã được tạo
- ArgoCD đã được cài đặt
- ECR registry có images:
  - `145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot`
  - `145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-multistage`
- ECR secret đã được tạo: `kubectl create secret docker-registry ecr-secret`

### Bước 1: Tạo Secret cho Chatbot

```bash
# Copy và chỉnh sửa secret
cp apps/chatbot/base/secret.yaml.example apps/chatbot/base/secret.yaml

# Encode API key
echo -n "sk-your-openai-key" | base64

# Apply secret
kubectl create namespace dev
kubectl apply -f apps/chatbot/base/secret.yaml -n dev
```

### Bước 2: Deploy với ArgoCD

```bash
# Deploy chatbot
kubectl apply -f argocd/chatbot-app.yaml

# Deploy multistage
kubectl apply -f argocd/multistage-app.yaml

# Kiểm tra sync status
argocd app list
argocd app get chatbot-app
argocd app get multistage-app
```

### Bước 3: Kiểm tra Deployment

```bash
# Check pods
kubectl get pods -n dev

# Expected output:
# dev-chatbot-app-xxx     2/2  Running
# dev-multistage-app-xxx  2/2  Running

# Check services
kubectl get svc -n dev

# Check ArgoCD sync status
argocd app sync chatbot-app
argocd app sync multistage-app
```

## 🔄 CI/CD Workflow

### Khi có code mới:

```bash
# 1. CI build & push image với tag = git commit SHA
docker build -t 145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:abc123 .
docker push 145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:abc123

# 2. Update image tag trong GitOps repo
cd eks-devops-k8s/apps/chatbot/overlays/dev
kustomize edit set image fcj-chatbot=145023123305.dkr.ecr.us-east-1.amazonaws.com/fcj-chatbot:abc123

# 3. Commit & push
git add .
git commit -m "Update chatbot to abc123"
git push

# 4. ArgoCD tự động detect & deploy (trong 3 phút)
```

### GitHub Actions Example:

```yaml
- name: Update K8s manifest
  run: |
    cd eks-devops-k8s/apps/chatbot/overlays/dev
    kustomize edit set image \
      fcj-chatbot=${{ env.ECR_REGISTRY }}/fcj-chatbot:${{ github.sha }}
    git config user.name "GitHub Actions"
    git config user.email "actions@github.com"
    git add kustomization.yaml
    git commit -m "Update chatbot image to ${{ github.sha }}"
    git push
```

## 📊 Monitoring & Operations

### Xem logs:

```bash
# Chatbot logs
kubectl logs -f deployment/dev-chatbot-app -n dev

# Multistage logs
kubectl logs -f deployment/dev-multistage-app -n dev
```

### Scale replicas:

```bash
# Chỉnh sửa patch.yaml
# apps/chatbot/overlays/dev/patch.yaml
spec:
  replicas: 3  # Tăng từ 2 lên 3

# Commit & push → ArgoCD tự động scale
```

### Rollback:

```bash
# Rollback qua ArgoCD
argocd app rollback chatbot-app

# Hoặc rollback qua Git
git revert HEAD
git push
```

### Health Check:

```bash
# Kiểm tra pod health
kubectl describe pod -l app=chatbot-app -n dev

# Xem events
kubectl get events -n dev --sort-by='.lastTimestamp'
```

## 🔧 Kustomize Commands

```bash
# Preview manifests trước khi apply
kustomize build apps/chatbot/overlays/dev
kustomize build apps/multistage/overlays/dev

# Apply trực tiếp (không qua ArgoCD)
kubectl apply -k apps/chatbot/overlays/dev
kubectl apply -k apps/multistage/overlays/dev

# Diff changes
kubectl diff -k apps/chatbot/overlays/dev
```

## 🌍 Thêm Environment Mới (Staging/Prod)

```bash
# Tạo overlay mới
mkdir -p apps/chatbot/overlays/staging
cp apps/chatbot/overlays/dev/kustomization.yaml apps/chatbot/overlays/staging/
cp apps/chatbot/overlays/dev/patch.yaml apps/chatbot/overlays/staging/

# Chỉnh sửa cho staging
# - Tăng replicas
# - Tăng resources
# - Đổi namespace thành "staging"

# Tạo ArgoCD Application cho staging
cp argocd/chatbot-app.yaml argocd/chatbot-app-staging.yaml
# Sửa path: apps/chatbot/overlays/staging
# Sửa namespace: staging
```

## ➕ Thêm App Mới

```bash
# 1. Copy structure từ app hiện có
cp -r apps/multistage apps/new-app

# 2. Chỉnh sửa:
# - deployment.yaml: đổi tên, port, health check path
# - service.yaml: đổi port
# - configmap.yaml: đổi env vars
# - kustomization.yaml: đổi image name

# 3. Tạo ArgoCD Application
cp argocd/multistage-app.yaml argocd/new-app.yaml
# Sửa name, path

# 4. Apply
kubectl apply -f argocd/new-app.yaml
```

## 🔐 Security Best Practices

- ✅ Không commit secret.yaml vào Git
- ✅ Dùng imagePullSecrets cho ECR
- ✅ Image tag = git commit SHA (không dùng latest)
- ✅ Resource limits để tránh resource exhaustion
- ✅ Health checks để tự động restart pod lỗi
- ✅ RollingUpdate để zero-downtime deployment

## 🎓 Production Checklist

- [ ] Tạo namespace riêng cho mỗi môi trường
- [ ] Setup AWS Secrets Manager + External Secrets Operator
- [ ] Configure HPA (Horizontal Pod Autoscaler)
- [ ] Setup monitoring (Prometheus + Grafana)
- [ ] Configure Ingress với SSL/TLS
- [ ] Setup backup cho PVC
- [ ] Configure resource quotas
- [ ] Setup alerting (Slack/PagerDuty)

## 🔗 Related Repositories

- **eks-devops-app**: Source code chatbot
- **eks-devops-infra**: Terraform EKS cluster

## 📚 Resources

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kubernetes Production Best Practices](https://learnk8s.io/production-best-practices)
