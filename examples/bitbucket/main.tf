# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  enabled          = var.enabled
  name_prefix      = var.name_prefix
  cicd_provider    = "bitbucket-pipelines"
  git_provider_org = "example-org"
  s3_backend_config = {
    enabled        = true
    bucket_arn     = ""
    lock_table_arn = ""
  }
  tags             = var.tags
  environment_type = var.environment_type
}
