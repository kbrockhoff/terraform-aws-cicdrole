# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  name_prefix            = var.name_prefix
  cicd_provider          = "github-actions"
  cicd_provider_org      = "kbrockhoff"
  git_provider_org       = "kbrockhoff"
  git_repos              = var.git_repos
  deployment_environment = var.deployment_environment
  create_oidc_provider   = false
  s3_backend_config = {
    enabled        = true
    bucket_arn     = "arn:aws:s3:::bkff-tfstate-123456789012"
    lock_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/bkff-tfstate-123456789012-lock"
  }
  tags = {
    Example = "github-actions"
  }
}
