# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  name_prefix      = var.name_prefix
  cicd_provider    = "github-actions"
  git_provider_org = "example-org"
  s3_backend_config = {
    enabled        = true
    bucket_arn     = ""
    lock_table_arn = ""
  }
  tags = {
    Example = "github-actions"
  }
}
