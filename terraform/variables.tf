variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "springboot-app"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "eks_cluster_name" {
  description = "Existing EKS cluster name"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for deployment access"
  type        = string
  default     = "dev"
}
