# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  name_prefix            = var.name_prefix
  cicd_provider          = "terraform-cloud"
  cicd_provider_org      = var.terraform_organization
  git_provider_org       = var.git_provider_org
  git_repos              = var.git_repos
  deployment_environment = var.deployment_environment
  s3_backend_config = {
    enabled        = false
    bucket_arn     = ""
    lock_table_arn = ""
  }
  tags = {
    Example = "terraform-cloud"
  }
}