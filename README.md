# AWS Role for CI/CD Pipeline Terraform Module

Terraform module which an IAM Role on AWS which trusts CI/CD system OIDC provider.

## Features

- Provisions role which trusts CI/CD system OIDC provider
- Provisions policy which enables role to use Terraform S3 backend

## Usage

### Basic Example

```hcl
module "example" {
  source = "kbrockhoff/cicdrole/aws"

  # ... other required arguments ...
}
```

### Complete Example

```hcl
module "example" {
  source = "kbrockhoff/cicdrole/aws"

  # ... all available arguments ...
}
```

## Environment Type Configuration

The `environment_type` variable provides a standardized way to configure resource defaults based on environment 
characteristics. This follows cloud well-architected framework recommendations for different deployment stages. 
Resiliency settings comply with the recovery point objective (RPO) and recovery time objective (RTO) values in
the table below. Cost optimization settings focus on shutting down resources during off-hours.

### Available Environment Types

| Type | Use Case | Configuration Focus | RPO | RTO |
|------|----------|---------------------|-----|-----|
| `None` | Custom configuration | No defaults applied, use individual config values | N/A | N/A |
| `Ephemeral` | Temporary environments | Cost-optimized, minimal durability requirements | N/A | 48h |
| `Development` | Developer workspaces | Balanced cost and functionality for active development | 24h | 48h |
| `Testing` | Automated testing | Consistent, repeatable configurations | 24h | 48h |
| `UAT` | User acceptance testing | Production-like settings with some cost optimization | 12h | 24h |
| `Production` | Live systems | High availability, durability, and performance | 1h  | 4h  |
| `MissionCritical` | Critical production | Maximum reliability, redundancy, and monitoring | 5m  | 1h  |

### Usage Examples

#### Development Environment
```hcl
module "dev_resources" {
  source = "path/to/terraform-module"
  
  name_prefix      = "dev-usw2"
  environment_type = "Development"
  
  tags = {
    Environment = "development"
    Team        = "platform"
  }
}
```

#### Production Environment
```hcl
module "prod_resources" {
  source = "path/to/terraform-module"
  
  name_prefix      = "prod-usw2"
  environment_type = "Production"
  
  tags = {
    Environment = "production"
    Team        = "platform"
    Backup      = "required"
  }
}
```

#### Custom Configuration (None)
```hcl
module "custom_resources" {
  source = "path/to/terraform-module"
  
  name_prefix      = "custom-usw2"
  environment_type = "None"
  
  # Specify all individual configuration values
  # when environment_type is "None"
}
```
## Network Tags Configuration

Resources deployed to subnets use lookup by `NetworkTags` values to determine which subnets to deploy to. 
This eliminates the need to manage different subnet IDs variable values for each environment.

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
