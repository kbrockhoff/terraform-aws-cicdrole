# Jenkins SAML Authentication Example

This example demonstrates how to create an IAM role for Jenkins using SAML-based authentication.

## Overview

Jenkins can be configured to use SAML authentication to assume AWS IAM roles. This example creates:
- An IAM role that trusts a SAML identity provider
- A custom assume role policy using `sts:AssumeRoleWithSAML`
- Permissions for accessing Terraform S3 backend storage

## Key Features

- **SAML Authentication**: Uses `sts:AssumeRoleWithSAML` action
- **SAML Provider**: Trusts a federated SAML identity provider
- **AWS SAML Endpoint**: Validates `SAML:aud` against `https://signin.aws.amazon.com/saml`
- **S3 Backend Access**: Includes permissions for Terraform state management

## Prerequisites

Before using this example, you need to:

1. **Set up a SAML Identity Provider in AWS IAM**:
   ```bash
   aws iam create-saml-provider \
     --name JenkinsSAML \
     --saml-metadata-document file://jenkins-saml-metadata.xml
   ```

2. **Configure Jenkins SAML Plugin**:
   - Install the SAML plugin in Jenkins
   - Configure it to use your SAML identity provider (e.g., Active Directory, Okta, etc.)
   - Set the AWS SAML endpoint as the target

3. **Configure Jenkins AWS CLI Plugin**:
   - Install the AWS CLI plugin
   - Configure it to use SAML role assumption

## Configuration

The example includes:
- `cicd_provider = "jenkins"` - Specifies Jenkins as the CI/CD provider
- Custom `assume_role_policy` - SAML-based trust policy
- `s3_backend_config` - S3 backend permissions enabled

## Variables

- `saml_provider_arn` - **Required**: ARN of your SAML identity provider in AWS IAM
- `name_prefix` - Prefix for resource names
- `git_provider_org` - Your Git provider organization

## Usage

1. Create a SAML identity provider in AWS IAM and note its ARN

2. Update `terraform.auto.tfvars` with your details:
   ```hcl
   name_prefix       = "jenkins"
   saml_provider_arn = "arn:aws:iam::123456789012:saml-provider/JenkinsSAML"
   git_provider_org  = "my-github-org"
   ```

3. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Configure Jenkins pipeline to use the role:
   ```groovy
   pipeline {
     agent any
     stages {
       stage('Deploy') {
         steps {
           script {
             // The Jenkins SAML plugin will automatically assume the role
             // when properly configured
             sh 'aws sts get-caller-identity'
             sh 'terraform apply'
           }
         }
       }
     }
   }
   ```

## SAML Trust Policy

The created role trusts SAML assertions with:
- **Principal**: Your SAML identity provider ARN
- **Action**: `sts:AssumeRoleWithSAML`
- **Condition**: `SAML:aud` equals `https://signin.aws.amazon.com/saml`

## Outputs

- `role_arn` - The ARN of the created IAM role
- `role_name` - The name of the created IAM role
- `assume_role_policy` - The SAML assume role policy JSON
- `oidc_provider_arn` - Will be empty (Jenkins uses SAML, not OIDC)
- `oidc_provider_url` - Will be empty (Jenkins uses SAML, not OIDC)

## Requirements

- AWS SAML identity provider already configured
- Jenkins with SAML plugin installed and configured
- AWS credentials with permissions to create IAM roles and policies
- Terraform >= 1.5

## References

- [AWS IAM SAML Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html)
- [Jenkins SAML Plugin](https://plugins.jenkins.io/saml/)
- [AWS STS AssumeRoleWithSAML](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithSAML.html)