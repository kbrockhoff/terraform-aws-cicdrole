variable "name_prefix" {
  description = "Organization unique prefix to use for resource names. Recommend including environment and region. e.g. 'prod-usw2'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,22}[a-z0-9]$", var.name_prefix))
    error_message = "The name_prefix value must be between 2 and 24 characters."
  }
}

variable "git_repos" {
  description = "List of git repository names or patterns for OIDC trust policy. Use ['*'] to allow all repositories in the organization"
  type        = list(string)
  default     = ["*"]
}

variable "deployment_environment" {
  description = "Deployment environment name for OIDC trust policy (e.g., 'production', 'staging', 'development'). Used in sub claim conditions for providers that support environment-based claims"
  type        = string
  default     = ""
}

variable "git_provider_org_id" {
  description = "Immutable numeric ID of the GitHub owner. Required when github_subject_format is 'immutable' or 'both'"
  type        = string
  default     = ""
}

variable "github_subject_format" {
  description = "GitHub Actions OIDC subject claim format to trust: legacy, immutable, or both"
  type        = string
  default     = "legacy"
}
