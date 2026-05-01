# EKS CI/CD Setup Checklist

## AWS Side

- [ ] EKS cluster is active
- [ ] Worker nodes are Ready
- [ ] ECR repository is created
- [ ] NAT Gateway or ECR VPC endpoints exist if nodes are private
- [ ] AWS Load Balancer Controller is installed
- [ ] Public/private subnet tags are correct
- [ ] EBS CSI driver is installed if persistent storage is needed
- [ ] GitHub OIDC IAM role exists
- [ ] GitHub IAM role has ECR push permissions
- [ ] GitHub IAM role has EKS deploy access entry

## GitHub Side

- [ ] Repository variables are configured
- [ ] `AWS_ROLE_TO_ASSUME` points to the GitHub OIDC IAM role
- [ ] Workflow has `id-token: write`
- [ ] Branch names match IAM OIDC trust policy

## Kubernetes Side

- [ ] Namespace exists
- [ ] Helm chart renders successfully
- [ ] Deployment has readiness/liveness probes
- [ ] Service points to correct container port
- [ ] Ingress has ALB annotations
- [ ] HPA has metrics-server installed

## Verification Commands

```bash
kubectl get nodes
kubectl get pods -A
kubectl get deploy,svc,ingress -n dev
helm list -n dev
helm history springboot-app -n dev
```
