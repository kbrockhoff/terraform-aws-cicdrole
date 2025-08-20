# AWS Role for CI/CD Pipeline Terraform Module

Provisions an IAM Role on AWS for use by CI/CD pipelines. Supports many commonly-used CI/CD platforms 
out-of-the-box as well as custom configurations. Optionally, adds policy to support use of the 
Terraform S3 backend for state management.

All Brockhoff AWS Terraform modules define a bootstrap submodule which creates a policy with all 
permissions needed for terraform apply and destroy to work. This module is intended to be used to 
create a role which is then passed into one or more of these bootstrap submodules.

## Features

- Provisions IAM Role which securely integrates with widely-used CI/CD platforms
- Provisions IAM OIDC provider for the CI/CD plaform being used if not already provisioned
- Provisions policy which enables role to use Terraform S3 backend for those CI/CD pipelines which use it

## Usage

### GitHub Actions with Existing OIDC Provider
```hcl
module "github_actions_role" {
  source = "kbrockhoff/cicdrole/aws"
  
  name_prefix            = "prod-usw2"
  cicd_provider          = "github-actions"
  git_provider_org       = "my-organization"
  git_repos              = ["my-repo", "another-repo"]
  deployment_environment = "production"
  create_oidc_provider   = false  # Use existing provider
  
  s3_backend_config = {
    enabled        = true
    bucket_arn     = "arn:aws:s3:::my-terraform-state"
    lock_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/my-terraform-locks"
  }
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Jenkins with SAML Authentication
```hcl
# Custom assume role policy for Jenkins using SAML authentication
data "aws_iam_policy_document" "jenkins_saml_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::123456789012:saml-provider/JenkinsSAML"]
    }

    actions = [
      "sts:AssumeRoleWithSAML",
      "sts:TagSession",
    ]

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

module "jenkins_role" {
  source = "kbrockhoff/cicdrole/aws"
  
  name_prefix        = "dev-usw2"
  cicd_provider      = "jenkins"
  git_provider_org   = "my-organization"
  assume_role_policy = data.aws_iam_policy_document.jenkins_saml_assume_role.json
  
  s3_backend_config = {
    enabled        = true
    bucket_arn     = ""        # Uses wildcard patterns
    lock_table_arn = ""        # Uses wildcard patterns
  }
  
  tags = {
    Environment = "development"
    Team        = "devops"
  }
}
```

### Terraform Cloud with Environment-Specific Access
```hcl
module "terraform_cloud_role" {
  source = "kbrockhoff/cicdrole/aws"
  
  name_prefix            = "tfc-prod"
  cicd_provider          = "terraform-cloud"
  cicd_provider_org      = "my-tfc-organization"
  git_provider_org       = "my-git-organization"
  git_repos              = ["aws-infrastructure", "networking"]
  deployment_environment = "production"
  
  # Terraform Cloud manages its own backend, so disable S3 backend permissions
  s3_backend_config = {
    enabled        = false
    bucket_arn     = ""
    lock_table_arn = ""
  }
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform-cloud"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.9.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.cicd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_openid_connect_provider.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cicd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.terraform_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_git_provider_org"></a> [git\_provider\_org](#input\_git\_provider\_org) | Git provider organization/username (e.g., GitHub org, GitLab group). Required for most OIDC trust policies | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Organization unique prefix to use for resource names. Recommend including environment and region. e.g. 'prod-usw2' | `string` | n/a | yes |
| <a name="input_assume_role_policy"></a> [assume\_role\_policy](#input\_assume\_role\_policy) | Custom assume role policy JSON. Used for providers that don't support OIDC and aren't AWS CodeBuild. If empty, module will generate appropriate policy | `string` | `""` | no |
| <a name="input_cicd_provider"></a> [cicd\_provider](#input\_cicd\_provider) | CI/CD platform provider for OIDC trust relationship | `string` | `"github-actions"` | no |
| <a name="input_cicd_provider_org"></a> [cicd\_provider\_org](#input\_cicd\_provider\_org) | Organization ID for CI/CD providers that require it (e.g., CircleCI org ID, Azure DevOps tenant ID, Bitbucket workspace). If blank, uses git\_provider\_org | `string` | `""` | no |
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Whether to create the OIDC provider resource. If false, oidc\_provider\_arn must be provided | `bool` | `true` | no |
| <a name="input_deployment_environment"></a> [deployment\_environment](#input\_deployment\_environment) | Deployment environment name for OIDC trust policy (e.g., 'production', 'staging', 'development'). Used in sub claim conditions for providers that support environment-based claims | `string` | `""` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment type for resource configuration defaults. Select 'None' to use individual config values. | `string` | `"Development"` | no |
| <a name="input_git_repos"></a> [git\_repos](#input\_git\_repos) | List of git repository names or patterns for OIDC trust policy. Use ['*'] to allow all repositories in the organization | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_manage_oidc_provider"></a> [manage\_oidc\_provider](#input\_manage\_oidc\_provider) | Whether to manage (import) an existing OIDC provider. Takes precedence over create\_oidc\_provider | `bool` | `false` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of an existing OIDC provider. Required if create\_oidc\_provider is false | `string` | `""` | no |
| <a name="input_s3_backend_config"></a> [s3\_backend\_config](#input\_s3\_backend\_config) | Configuration for Terraform S3 backend access permissions | <pre>object({<br/>    enabled        = bool<br/>    bucket_arn     = string<br/>    lock_table_arn = string<br/>  })</pre> | <pre>{<br/>  "bucket_arn": "",<br/>  "enabled": true,<br/>  "lock_table_arn": ""<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags/labels to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC provider |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | URL of the OIDC provider |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the CI/CD IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the CI/CD IAM role |
<!-- END_TF_DOCS -->    

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.
