# ----
# OIDC Provider
# ----

data "tls_certificate" "oidc" {
  count = (local.should_create_oidc || local.should_manage_oidc) ? 1 : 0

  url = "https://${local.selected_oidc_provider}"
}

# Create a new OIDC provider
resource "aws_iam_openid_connect_provider" "cicd" {
  count = local.should_create_oidc ? 1 : 0

  url             = "https://${local.selected_oidc_provider}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.oidc[0].certificates[*].sha1_fingerprint

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${var.cicd_provider}-oidc"
    }
  )
}

# Import and manage an existing OIDC provider
# To import: terraform import 'module.main.aws_iam_openid_connect_provider.managed[0]' arn:aws:iam::ACCOUNT:oidc-provider/PROVIDER_URL
resource "aws_iam_openid_connect_provider" "managed" {
  count = local.should_manage_oidc ? 1 : 0

  url             = "https://${local.selected_oidc_provider}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.oidc[0].certificates[*].sha1_fingerprint

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${var.cicd_provider}-oidc"
    }
  )

  lifecycle {
    # Prevent accidental deletion of imported provider
    prevent_destroy = true
  }
}

# ----
# IAM Role for CI/CD
# ----

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "${local.selected_oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cicd" {
  count = var.enabled ? 1 : 0

  name               = "${local.name_prefix}-cicd-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cicd-role"
    }
  )
}

# ----
# IAM Policy for Terraform Backend Access
# ----

data "aws_iam_policy_document" "terraform_backend" {
  count = var.enabled ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]

    resources = ["arn:${local.partition}:s3:::*-terraform-state"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["arn:${local.partition}:s3:::*-terraform-state/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = ["arn:${local.partition}:dynamodb:*:${local.account_id}:table/*-terraform-locks"]
  }
}

resource "aws_iam_role_policy" "terraform_backend" {
  count = var.enabled ? 1 : 0

  name   = "terraform-backend-access"
  role   = aws_iam_role.cicd[0].id
  policy = data.aws_iam_policy_document.terraform_backend[0].json
}