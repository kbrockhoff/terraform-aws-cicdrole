package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformCloudExample tests the module with Terraform Cloud as the CI/CD provider
func TestTerraformCloudExample(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("tfc")

	terraformOptions := getBaseTerraformOptions("../examples/terraform-cloud")
	terraformOptions.Vars = map[string]interface{}{
		"name_prefix": testName,
	}
	terraformOptions.RetryableTerraformErrors = map[string]string{
		"Module not installed": "Module initialization error",
	}
	terraformOptions.MaxRetries = 3

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Init and plan only
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify the plan completed without errors
	assert.NotEmpty(t, planOutput)

	// Verify core IAM and OIDC resources are planned for creation
	assert.Contains(t, planOutput, "module.main.aws_iam_role.cicd[0]")
	assert.Contains(t, planOutput, "module.main.aws_iam_openid_connect_provider.cicd[0]")
	assert.Contains(t, planOutput, "will be created")
	
	// Verify OIDC configuration for Terraform Cloud
	assert.Contains(t, planOutput, "app.terraform.io")
	assert.Contains(t, planOutput, "aws.workload.identity")
	assert.Contains(t, planOutput, "sts:AssumeRoleWithWebIdentity")
	
	// Terraform Cloud example has s3_backend_config.enabled = false, so only 2 resources: IAM role + OIDC provider
	assert.Contains(t, planOutput, "2 to add, 0 to change, 0 to destroy")
}

// TestTerraformCloudWithEnvironment tests the module with Terraform Cloud and deployment environment
func TestTerraformCloudWithEnvironment(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("tfc")

	terraformOptions := getBaseTerraformOptions("../examples/terraform-cloud")
	terraformOptions.Vars = map[string]interface{}{
		"name_prefix":            testName,
		"deployment_environment": "production",
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Init and plan only
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify the plan completed without errors
	assert.NotEmpty(t, planOutput)

	// Verify that workspace environment is included in trust policy
	assert.Contains(t, planOutput, "workspace:production:run_phase")
	
	// Should create 2 resources (s3_backend_config.enabled = false in example)
	assert.Contains(t, planOutput, "2 to add, 0 to change, 0 to destroy")
}