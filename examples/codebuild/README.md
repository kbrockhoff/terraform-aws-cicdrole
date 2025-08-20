# AWS CodeBuild IAM Role Example

This example demonstrates how to create an IAM role for AWS CodeBuild projects using this module.

## Overview

AWS CodeBuild uses IAM service principals instead of OIDC for authentication. This example creates:
- An IAM role that trusts the CodeBuild service
- Permissions for accessing Terraform S3 backend storage

## Key Features

- **Service Principal Authentication**: Uses `codebuild.amazonaws.com` service principal
- **No OIDC Provider**: CodeBuild doesn't require OIDC provider setup
- **S3 Backend Access**: Includes permissions for Terraform state management

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

The example uses the following configuration:
- `cicd_provider = "codebuild"` - Specifies AWS CodeBuild as the CI/CD provider
- `s3_backend_config` - Enables S3 backend permissions with wildcard patterns

## Outputs

- `role_arn` - The ARN of the created IAM role (use this in your CodeBuild project configuration)
- `role_name` - The name of the created IAM role
- `oidc_provider_arn` - Will be empty (CodeBuild doesn't use OIDC)
- `oidc_provider_url` - Will be empty (CodeBuild doesn't use OIDC)

## CodeBuild Project Configuration

After creating the role, configure your CodeBuild project to use it:

```yaml
service_role: <output_role_arn>
```

## Requirements

- AWS credentials with permissions to create IAM roles and policies
- Terraform >= 1.5