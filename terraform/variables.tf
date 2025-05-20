variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "profile" {
  description = "AWS profile"
  type        = string
  default     = "admin"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "elixir_cluster"
}

variable "dns_namespace_name" {
  description = "Service discovery namespace name"
  type        = string
  default     = "elixir_cluster"
}

variable "app_name" {
  description = "Base name for resources"
  type        = string
  default     = "elixir_cluster"
}

variable "container_image" {
  description = "Full ECR image path"
  type        = string
}

variable "container_port" {
  description = "Port exposed by container"
  type        = number
  default     = 4000
}

variable "container_name" {
  default = "elixir_cluster"
}

variable "desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum ECS task count"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum ECS task count"
  type        = number
  default     = 3
}

variable "release_node" {
  description = "Release node"
  type        = string
}

variable "release_cookie" {
  description = "Release cookie"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}