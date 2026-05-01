#!/usr/bin/env bash
set -euo pipefail

: "${NAMESPACE:=dev}"
: "${HELM_RELEASE_NAME:=springboot-app}"
: "${REVISION:=}"

if [[ -z "$REVISION" ]]; then
  echo "Helm history:"
  helm history "$HELM_RELEASE_NAME" -n "$NAMESPACE"
  echo "Set REVISION=<number> and run again. Example: REVISION=1 ./scripts/rollback.sh"
  exit 1
fi

helm rollback "$HELM_RELEASE_NAME" "$REVISION" -n "$NAMESPACE"
kubectl rollout status deployment/"$HELM_RELEASE_NAME" -n "$NAMESPACE"
