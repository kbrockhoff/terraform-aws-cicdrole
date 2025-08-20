package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestJenkinsExample tests the module with Jenkins as the CI/CD provider
func TestJenkinsExample(t *testing.T) {
	t.Parallel()

	testName := generateTestNamePrefix("jnks")

	// Jenkins uses SAML, so we need to provide a mock ARN
	mockSamlArn := "arn:aws:iam::123456789012:saml-provider/jenkins-saml"

	terraformOptions := getBaseTerraformOptions("../examples/jenkins")
	terraformOptions.Vars = map[string]interface{}{
		"name_prefix":       testName,
		"saml_provider_arn": mockSamlArn,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Init and plan only
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify the plan completed without errors
	assert.NotEmpty(t, planOutput)

	// Verify that SAML principal is in the plan (Jenkins uses SAML, not OIDC)
	assert.Contains(t, planOutput, "sts:AssumeRoleWithSAML")
	assert.Contains(t, planOutput, mockSamlArn)
	
	// Verify core IAM resources are planned for creation
	assert.Contains(t, planOutput, "module.main.aws_iam_role.cicd[0]")
	assert.Contains(t, planOutput, "module.main.aws_iam_role_policy.terraform_backend[0]")
	
	// Verify OIDC provider is NOT created for Jenkins (uses SAML instead)
	assert.NotContains(t, planOutput, "aws_iam_openid_connect_provider")
	
	// Jenkins creates 2 resources: IAM role + IAM policy (no OIDC provider)
	assert.Contains(t, planOutput, "2 to add, 0 to change, 0 to destroy")
}