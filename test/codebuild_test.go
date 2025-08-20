package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestCodeBuildProvider tests the module with CodeBuild as the CI/CD provider
func TestCodeBuildProvider(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("cbld")

	// Use the codebuild example directly
	terraformOptions := getBaseTerraformOptions("../examples/codebuild")
	terraformOptions.Vars = map[string]interface{}{
		"name_prefix": testName,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Init and plan only
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify that CodeBuild service principal is in the plan
	assert.Contains(t, planOutput, "codebuild.amazonaws.com")
	assert.Contains(t, planOutput, "sts:AssumeRole")

	// Verify OIDC provider is NOT created for CodeBuild
	assert.NotContains(t, planOutput, "aws_iam_openid_connect_provider")
}
