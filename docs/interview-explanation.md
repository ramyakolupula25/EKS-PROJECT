# Interview Explanation: End-to-End EKS Pipeline

I created an end-to-end CI/CD pipeline for deploying applications to Amazon EKS.

The flow starts when a developer pushes code to GitHub. GitHub Actions triggers the workflow, checks out the source code, builds and tests the application using Maven, creates a Docker image, scans the image using Trivy, and pushes the approved image to Amazon ECR.

After the image is pushed, the pipeline updates kubeconfig for the EKS cluster and deploys the application using Helm. Helm manages Kubernetes resources like Deployment, Service, Ingress, HPA, readiness probes, and liveness probes.

For external access, the application is exposed through Kubernetes Ingress. The AWS Load Balancer Controller watches the Ingress object and provisions an Application Load Balancer automatically.

For safer deployments, I use rolling updates with `maxUnavailable: 0`, readiness probes to avoid sending traffic to unhealthy pods, and `helm upgrade --atomic` so a failed deployment can roll back automatically.

For rollback, I use:

```bash
helm history springboot-app -n dev
helm rollback springboot-app <revision> -n dev
```

This setup improves deployment reliability, security, and repeatability across environments.
