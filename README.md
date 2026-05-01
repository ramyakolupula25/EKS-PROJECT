# End-to-End EKS CI/CD Pipeline Repo

This repo contains a complete sample setup for deploying a Spring Boot application to Amazon EKS using:

- GitHub Actions CI/CD
- Docker multi-stage build
- Amazon ECR image registry
- Amazon EKS deployment
- Helm chart deployment
- AWS Load Balancer Controller ingress
- Optional Terraform templates for ECR, GitHub OIDC IAM role, and EKS access entry
- Trivy image scanning
- Rolling update + rollback support

---

## Architecture

```text
Developer Push
   ↓
GitHub Actions
   ↓
Maven Build + Test
   ↓
Docker Build
   ↓
Trivy Security Scan
   ↓
Push Image to Amazon ECR
   ↓
Helm Upgrade/Install
   ↓
Amazon EKS Deployment
   ↓
Service + ALB Ingress
   ↓
Users
```

---

## Repo Structure

```text
eks-end-to-end-pipeline/
├── .github/workflows/eks-deploy.yml
├── src/main/java/com/example/demo/DemoApplication.java
├── src/main/resources/application.properties
├── helm/springboot-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── hpa.yaml
├── k8s/
│   ├── namespace.yaml
│   └── storageclass-gp3.yaml
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── ecr.tf
│   ├── github-oidc.tf
│   ├── eks-access.tf
│   └── outputs.tf
├── scripts/
│   ├── deploy-local.sh
│   └── rollback.sh
├── Dockerfile
├── pom.xml
└── README.md
```

---

## Required GitHub Repository Variables

Create these under:

`GitHub Repo → Settings → Secrets and variables → Actions → Variables`

| Variable | Example |
|---|---|
| `AWS_REGION` | `ap-south-1` |
| `AWS_ACCOUNT_ID` | `123456789012` |
| `EKS_CLUSTER_NAME` | `my-eks-cluster` |
| `ECR_REPOSITORY` | `springboot-app` |
| `NAMESPACE` | `dev` |
| `HELM_RELEASE_NAME` | `springboot-app` |
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::123456789012:role/github-actions-eks-deploy-role` |

No AWS access keys are required when using GitHub OIDC.

---

## Manual Local Deployment

Update kubeconfig:

```bash
aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster
```

Create namespace:

```bash
kubectl apply -f k8s/namespace.yaml
```

Deploy through Helm:

```bash
helm upgrade --install springboot-app ./helm/springboot-app \
  --namespace dev \
  --create-namespace \
  --set image.repository=123456789012.dkr.ecr.ap-south-1.amazonaws.com/springboot-app \
  --set image.tag=latest \
  --atomic \
  --timeout 5m
```

Verify:

```bash
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev
kubectl rollout status deployment/springboot-app -n dev
```

---

## Build and Push Manually to ECR

```bash
AWS_REGION=ap-south-1
AWS_ACCOUNT_ID=123456789012
ECR_REPOSITORY=springboot-app
IMAGE_TAG=latest

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
```

---

## Rollback

Using Helm:

```bash
helm history springboot-app -n dev
helm rollback springboot-app 1 -n dev
```

Using Kubernetes:

```bash
kubectl rollout history deployment/springboot-app -n dev
kubectl rollout undo deployment/springboot-app -n dev
```

---

## Common Troubleshooting

### 1. `ImagePullBackOff`

Check:

```bash
kubectl describe pod <pod-name> -n dev
```

Common reasons:

- Wrong ECR image URI
- Wrong image tag
- Node cannot reach ECR
- Private node subnet has no NAT Gateway or ECR VPC endpoints
- IAM permission issue

### 2. ALB not created

Check:

```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress springboot-app -n dev
```

Required subnet tags:

```text
Public subnet:  kubernetes.io/role/elb = 1
Private subnet: kubernetes.io/role/internal-elb = 1
Cluster tag:    kubernetes.io/cluster/<cluster-name> = shared
```

### 3. Pipeline cannot access EKS

Check:

```bash
aws sts get-caller-identity
aws eks list-access-entries --cluster-name my-eks-cluster
```

Make sure the GitHub Actions IAM role has an EKS access entry and enough namespace permissions.

---

## Interview Explanation

“I created an end-to-end CI/CD pipeline for EKS. When code is pushed to GitHub, GitHub Actions builds and tests the Spring Boot application, creates a Docker image, scans it with Trivy, pushes the image to Amazon ECR, and deploys it to EKS using Helm. The application runs behind a Kubernetes Service and ALB Ingress. We use rolling updates, readiness/liveness probes, and Helm atomic deployments for safer releases. For rollback, we use Helm history and rollback or Kubernetes rollout undo.”
