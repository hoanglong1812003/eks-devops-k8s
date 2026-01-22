# eks-devops-k8s

GitOps repository để deploy chatbot từ eks-devops-app lên EKS cluster.

## 📁 Cấu trúccc

```
eks-devops-k8s/
├── base/                    # Base Kubernetes manifests
│   ├── deployment.yaml      # Chatbot deployment
│   ├── service.yaml         # ClusterIP service
│   ├── ingress.yaml         # ALB Ingress
│   ├── configmap.yaml       # Environment variables
│   ├── pvc.yaml            # PersistentVolumeClaim cho vectorstore
│   ├── secret.yaml.example  # Secret template
│   └── kustomization.yaml
├── overlays/
│   └── dev/                # Dev environment overlay
│       ├── kustomization.yaml
│       └── patch.yaml
├── argocd/
│   └── application.yaml    # ArgoCD Application
└── README.md
```

## 🚀 Deployment

### Prerequisites

1. EKS cluster đã được tạo từ `eks-devops-infra`
2. ECR repository `chatbot-app` đã có image
3. ArgoCD đã được cài đặt trên cluster
4. AWS Load Balancer Controller đã được cài đặt

### Bước 1: Tạo Secret

```bash
# Copy và chỉnh sửa secret
cp base/secret.yaml.example base/secret.yaml

# Encode base64 nếu cần
echo -n "your-api-key" | base64

# Apply secret
kubectl apply -f base/secret.yaml -n dev
```

### Bước 2: Cập nhật Image URL

Chỉnh sửa `overlays/dev/kustomization.yaml`:

```yaml
images:
- name: <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/chatbot-app
  newTag: latest  # hoặc tag cụ thể từ CI/CD
```

### Bước 3: Deploy với ArgoCD

```bash
# Cập nhật repoURL trong argocd/application.yaml
# Thay <YOUR_ORG> bằng GitHub org/username của bạn

# Apply ArgoCD Application
kubectl apply -f argocd/application.yaml

# Kiểm tra sync status
argocd app get chatbot-app
argocd app sync chatbot-app
```

### Bước 4: Kiểm tra Deployment

```bash
# Check pods
kubectl get pods -n dev

# Check service
kubectl get svc -n dev

# Check ingress và lấy ALB URL
kubectl get ingress -n dev
```

## 🔄 CI/CD Integration

Để tự động update image tag từ CI/CD pipeline:

```bash
# Trong GitHub Actions của eks-devops-app
- name: Update K8s manifest
  run: |
    cd eks-devops-k8s
    kustomize edit set image \
      $ECR_REGISTRY/chatbot-app:$IMAGE_TAG
    git commit -am "Update image to $IMAGE_TAG"
    git push
```

## 📝 Customization

### Dev Environment

Chỉnh sửa `overlays/dev/patch.yaml` để override:
- Resource limits
- Environment variables
- Replicas

### Production Environment

Tạo `overlays/prod/`:

```bash
mkdir -p overlays/prod
cp overlays/dev/kustomization.yaml overlays/prod/
# Chỉnh sửa cho production
```

## 🔧 Kustomize Commands

```bash
# Preview manifests
kustomize build overlays/dev

# Apply directly
kubectl apply -k overlays/dev

# Diff changes
kubectl diff -k overlays/dev
```

## 📊 Monitoring

```bash
# Logs
kubectl logs -f deployment/dev-chatbot-app -n dev

# Describe pod
kubectl describe pod -l app=chatbot-app -n dev

# Port forward để test local
kubectl port-forward svc/dev-chatbot-app 8501:80 -n dev
```

## 🔐 Security Notes

- **KHÔNG commit** `base/secret.yaml` vào Git
- Sử dụng AWS Secrets Manager hoặc External Secrets Operator cho production
- Secret example chỉ dùng cho demo/lab

## 🌐 Access Application

Sau khi deploy thành công:

```bash
# Lấy ALB URL
kubectl get ingress dev-chatbot-app -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Truy cập: `http://<ALB-URL>`

## 🔗 Related Repositories

- **eks-devops-app**: Source code và Dockerfile của chatbot
- **eks-devops-infra**: Terraform để tạo EKS cluster và ECR

## 📚 Resources

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
