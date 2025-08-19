package test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCodeBuildProvider tests the module with CodeBuild as the CI/CD provider
func TestCodeBuildProvider(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("cbld")

	// Create a test configuration that directly uses the module
	terraformOptions := getBaseTerraformOptions("../examples/complete")
	terraformOptions.Vars = map[string]interface{}{
		"name_prefix":      testName,
		"environment_type": "None",
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Create a temporary main.tf to test CodeBuild configuration
	testDir := t.TempDir()
	mainTfContent := `
provider "aws" {}
provider "aws" {
  alias  = "pricing"
  region = "us-east-1"
}

module "main" {
  source = "` + "../../../" + `"
  
  providers = {
    aws         = aws
    aws.pricing = aws.pricing
  }

  enabled          = true
  name_prefix      = var.name_prefix
  cicd_provider    = "codebuild"
  git_provider_org = "test-org"
  environment_type = "None"
}

variable "name_prefix" {
  type = string
}

output "role_arn" {
  value = module.main.role_arn
}
`
	terraform.SaveTerraformOptions(t, testDir, terraformOptions)
	terraform.WriteFile(t, testDir+"/main.tf", mainTfContent)
	
	moduleOptions := getBaseTerraformOptions(testDir)
	moduleOptions.Vars = map[string]interface{}{
		"name_prefix": testName,
	}

	terraform.Init(t, moduleOptions)
	planOutput := terraform.Plan(t, moduleOptions)

	// Verify that CodeBuild service principal is in the plan
	assert.Contains(t, planOutput, "codebuild.amazonaws.com")
	assert.Contains(t, planOutput, "sts:AssumeRole")
	
	// Verify OIDC provider is NOT created for CodeBuild
	assert.NotContains(t, planOutput, "aws_iam_openid_connect_provider")
}

// TestCustomAssumeRolePolicy tests the module with a custom assume role policy
func TestCustomAssumeRolePolicy(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("cust")

	customPolicy := `{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Effect": "Allow",
				"Principal": {
					"Service": "lambda.amazonaws.com"
				},
				"Action": "sts:AssumeRole"
			}
		]
	}`

	terraformOptions := getBaseTerraformOptions("../")
	terraformOptions.Vars = map[string]interface{}{
		"enabled":            true,
		"name_prefix":        testName,
		"cicd_provider":      "jenkins",
		"git_provider_org":   "test-org",
		"assume_role_policy": customPolicy,
		"environment_type":   "None",
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Init and plan only
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify that custom policy principal is in the plan
	assert.Contains(t, planOutput, "lambda.amazonaws.com")
	
	// Verify OIDC provider is NOT created for Jenkins
	assert.NotContains(t, planOutput, "aws_iam_openid_connect_provider")
}