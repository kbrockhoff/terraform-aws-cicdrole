package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const RandomIDLength = 10

func TestTerraformGitHubActionsExample(t *testing.T) {
	t.Parallel()
	expectedName := generateTestNamePrefix("gha")

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/github-actions",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name_prefix": expectedName,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform plan` to validate configuration without creating resources
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify the plan completed without errors and shows expected resource creation
	assert.NotEmpty(t, planOutput)
	
	// Verify core IAM and OIDC resources are planned for creation
	assert.Contains(t, planOutput, "module.main.aws_iam_role.cicd[0]")
	assert.Contains(t, planOutput, "module.main.aws_iam_openid_connect_provider.cicd[0]")
	assert.Contains(t, planOutput, "will be created")
	
	// Verify expected resource count (3 resources: IAM role + IAM policy + OIDC provider)
	assert.Contains(t, planOutput, "3 to add, 0 to change, 0 to destroy")

}
