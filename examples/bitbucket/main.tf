# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  enabled                = var.enabled
  name_prefix            = var.name_prefix
  cicd_provider          = "bitbucket-pipelines"
  create_oidc_provider   = var.create_oidc_provider
  manage_oidc_provider   = var.manage_oidc_provider
  oidc_provider_arn      = var.oidc_provider_arn
  cicd_provider_org      = var.cicd_provider_org
  git_provider_org       = var.git_provider_org
  git_repos              = var.git_repos
  deployment_environment = var.deployment_environment
  s3_backend_config      = var.s3_backend_config
  tags                   = var.tags
  environment_type       = var.environment_type
}
