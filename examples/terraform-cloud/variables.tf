variable "name_prefix" {
  description = "Organization unique prefix to use for resource names. Recommend including environment and region. e.g. 'prod-usw2'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,22}[a-z0-9]$", var.name_prefix))
    error_message = "The name_prefix value must be between 2 and 24 characters."
  }
}

variable "terraform_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "example-org"
}

variable "git_provider_org" {
  description = "Git provider organization/username (e.g., GitHub org, GitLab group)"
  type        = string
  default     = "example-org"
}

variable "git_repos" {
  description = "List of git repository names that will use this role"
  type        = list(string)
  default     = ["*"]
}

variable "deployment_environment" {
  description = "Deployment environment name for OIDC trust policy (e.g., 'production', 'staging', 'development'). Leave empty for all workspaces"
  type        = string
  default     = ""
}