# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

module "main" {
  source = "../../"

  name_prefix      = var.name_prefix
  cicd_provider    = "codebuild"
  git_provider_org = "kbrockhoff"
  s3_backend_config = {
    enabled        = true
    bucket_arn     = ""
    lock_table_arn = ""
  }
  tags = {
    Example = "codebuild"
  }
}