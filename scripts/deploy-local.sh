#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:=ap-south-1}"
: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
: "${ECR_REPOSITORY:=springboot-app}"
: "${EKS_CLUSTER_NAME:?Set EKS_CLUSTER_NAME}"
: "${NAMESPACE:=dev}"
: "${HELM_RELEASE_NAME:=springboot-app}"
: "${IMAGE_TAG:=latest}"

IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

docker build -t "$ECR_REPOSITORY:$IMAGE_TAG" .
docker tag "$ECR_REPOSITORY:$IMAGE_TAG" "$IMAGE_URI"
docker push "$IMAGE_URI"

helm upgrade --install "$HELM_RELEASE_NAME" ./helm/springboot-app \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY" \
  --set image.tag="$IMAGE_TAG" \
  --atomic \
  --timeout 5m

kubectl rollout status deployment/"$HELM_RELEASE_NAME" -n "$NAMESPACE"
kubectl get pods -n "$NAMESPACE" -o wide
kubectl get ingress -n "$NAMESPACE"
