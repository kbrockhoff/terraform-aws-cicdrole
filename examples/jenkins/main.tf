# Main AWS provider - uses the current region
provider "aws" {
  # This is the default provider used for resources
}

# Custom assume role policy for Jenkins using SAML authentication
data "aws_iam_policy_document" "jenkins_saml_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.saml_provider_arn]
    }

    actions = ["sts:AssumeRoleWithSAML"]

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

module "main" {
  source = "../../"

  name_prefix        = var.name_prefix
  cicd_provider      = "jenkins"
  git_provider_org   = var.git_provider_org
  assume_role_policy = data.aws_iam_policy_document.jenkins_saml_assume_role.json
  s3_backend_config = {
    enabled        = true
    bucket_arn     = ""
    lock_table_arn = ""
  }
  tags = {
    Example = "jenkins"
  }
}