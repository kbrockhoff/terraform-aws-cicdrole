# ----
# Common
# ----

variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Organization unique prefix to use for resource names. Recommend including environment and region. e.g. 'prod-usw2'"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,22}[a-z0-9]$", var.name_prefix))
    error_message = "The name_prefix value must start with a lowercase letter, followed by 0 to 22 alphanumeric or hyphen characters, ending with alphanumeric, for a total length of 2 to 24 characters."
  }
}

variable "tags" {
  description = "Tags/labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "environment_type" {
  description = "Environment type for resource configuration defaults. Select 'None' to use individual config values."
  type        = string
  default     = "Development"

  validation {
    condition = contains([
      "None", "Ephemeral", "Development", "Testing", "UAT", "Production", "MissionCritical"
    ], var.environment_type)
    error_message = "Environment type must be one of: None, Ephemeral, Development, Testing, UAT, Production, MissionCritical."
  }
}

# ----
# CI/CD Provider Configuration
# ----

variable "cicd_provider" {
  description = "CI/CD platform provider for OIDC trust relationship"
  type        = string
  default     = "github-actions"

  validation {
    condition = contains([
      "github-actions",
      "gitlab-ci",
      "bitbucket-pipelines",
      "circleci",
      "azure-devops",
      "jenkins",
      "travis-ci",
      "buildkite",
      "codebuild",
      "harness",
      "teamcity",
      "drone-ci",
      "terraform-cloud",
      "terraform-enterprise",
      "scalr",
      "spacelift"
    ], var.cicd_provider)
    error_message = "CI/CD provider must be one of: github-actions, gitlab-ci, bitbucket-pipelines, circleci, azure-devops, jenkins, travis-ci, buildkite, codebuild, harness, teamcity, drone-ci, terraform-cloud, terraform-enterprise, scalr, spacelift."
  }
}

variable "create_oidc_provider" {
  description = "Whether to create the OIDC provider resource. If false, oidc_provider_arn must be provided"
  type        = bool
  default     = true
}

variable "manage_oidc_provider" {
  description = "Whether to manage (import) an existing OIDC provider. Takes precedence over create_oidc_provider"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of an existing OIDC provider. Required if create_oidc_provider is false"
  type        = string
  default     = ""

  validation {
    condition     = var.oidc_provider_arn == "" || can(regex("^arn:[^:]+:iam::[0-9]+:oidc-provider/.+", var.oidc_provider_arn))
    error_message = "OIDC provider ARN must be a valid IAM OIDC provider ARN or empty string."
  }
}

variable "cicd_provider_org" {
  description = "Organization ID or hostname for CI/CD providers that require it (e.g., CircleCI org ID, Azure DevOps tenant ID, Bitbucket workspace, TFE/Scalr hostname). If blank, uses git_provider_org."
  type        = string
  default     = ""
}

variable "git_provider_org" {
  description = "Git provider organization/username (e.g., GitHub org, GitLab group). Required for most OIDC trust policies"
  type        = string
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

variable "assume_role_policy" {
  description = "Custom assume role policy JSON. Used for providers that don't support OIDC and aren't AWS CodeBuild. If empty, module will generate appropriate policy"
  type        = string
  default     = ""
}

# ----
# Terraform Backend Configuration
# ----

variable "s3_backend_config" {
  description = "Configuration for Terraform S3 backend access permissions"
  type = object({
    enabled        = bool
    bucket_arn     = string
    lock_table_arn = string
  })
  default = {
    enabled        = true
    bucket_arn     = ""
    lock_table_arn = ""
  }
}
