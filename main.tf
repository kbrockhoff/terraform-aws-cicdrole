# ----
# OIDC Provider
# ----

data "tls_certificate" "oidc" {
  count = (local.should_create_oidc || local.should_manage_oidc) ? 1 : 0

  url = "https://${local.selected_oidc_provider.oidc_url}"
}

# Create a new OIDC provider
resource "aws_iam_openid_connect_provider" "cicd" {
  count = local.should_create_oidc ? 1 : 0

  url             = "https://${local.selected_oidc_provider.oidc_url}"
  client_id_list  = [local.selected_oidc_provider.aud_value]
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

  url             = "https://${local.selected_oidc_provider.oidc_url}"
  client_id_list  = [local.selected_oidc_provider.aud_value]
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

# OIDC-based assume role policy for providers that support OIDC
data "aws_iam_policy_document" "assume_role_oidc" {
  count = var.enabled && local.selected_oidc_provider.oidc_supported ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "${local.selected_oidc_provider.oidc_url}:aud"
      values   = [local.selected_oidc_provider.aud_value]
    }

    condition {
      test     = "StringLike"
      variable = "${local.selected_oidc_provider.oidc_url}:sub"
      values   = local.selected_oidc_provider.sub_values
    }
  }
}

# CodeBuild service assume role policy
data "aws_iam_policy_document" "assume_role_codebuild" {
  count = var.enabled && var.cicd_provider == "codebuild" ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.${local.dns_suffix}"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cicd" {
  count = var.enabled ? 1 : 0

  name = "${local.name_prefix}-cicd-deployer"
  path = "/"
  assume_role_policy = local.selected_oidc_provider.oidc_supported ? (
    data.aws_iam_policy_document.assume_role_oidc[0].json
    ) : (
    var.cicd_provider == "codebuild" ? (
      data.aws_iam_policy_document.assume_role_codebuild[0].json
    ) : var.assume_role_policy
  )

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
  count = var.enabled && var.s3_backend_config.enabled ? 1 : 0

  statement {
    sid    = "TerraformS3Backend-S3Bucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]

    resources = var.s3_backend_config.bucket_arn != "" ? [
      var.s3_backend_config.bucket_arn
      ] : [
      "arn:${local.partition}:s3:::*-terraform-state"
    ]
  }

  statement {
    sid    = "TerraformS3Backend-S3StateFiles"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = var.s3_backend_config.bucket_arn != "" ? [
      "${var.s3_backend_config.bucket_arn}/*"
      ] : [
      "arn:${local.partition}:s3:::*-terraform-state/*"
    ]
  }

  statement {
    sid    = "TerraformS3Backend-DynamoDBLockTable"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = var.s3_backend_config.lock_table_arn != "" ? [
      var.s3_backend_config.lock_table_arn
      ] : [
      "arn:${local.partition}:dynamodb:*:${local.account_id}:table/*-terraform-locks"
    ]
  }
}

resource "aws_iam_role_policy" "terraform_backend" {
  count = var.enabled && var.s3_backend_config.enabled ? 1 : 0

  name   = "terraform-backend-access"
  role   = aws_iam_role.cicd[0].id
  policy = data.aws_iam_policy_document.terraform_backend[0].json
}