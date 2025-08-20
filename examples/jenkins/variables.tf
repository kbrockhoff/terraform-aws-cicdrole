variable "name_prefix" {
  description = "Organization unique prefix to use for resource names. Recommend including environment and region. e.g. 'prod-usw2'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,22}[a-z0-9]$", var.name_prefix))
    error_message = "The name_prefix value must be between 2 and 24 characters."
  }
}

variable "saml_provider_arn" {
  description = "ARN of the SAML identity provider configured in AWS IAM for Jenkins authentication"
  type        = string
}

variable "git_provider_org" {
  description = "Git provider organization/username (e.g., GitHub org, GitLab group)"
  type        = string
  default     = "example-org"
}