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
	
	// Verify core IAM resources are planned for creation
	assert.Contains(t, planOutput, "module.main.aws_iam_role.cicd[0]")
	assert.Contains(t, planOutput, "module.main.aws_iam_role_policy.terraform_backend[0]")
	assert.Contains(t, planOutput, "will be created")
	
	// Since create_oidc_provider = false in the example, it uses data source instead
	assert.Contains(t, planOutput, "module.main.data.aws_iam_openid_connect_provider.existing[0]")
	
	// Verify expected resource count (2 resources: IAM role + IAM policy)
	// OIDC provider is not created because create_oidc_provider = false
	assert.Contains(t, planOutput, "2 to add, 0 to change, 0 to destroy")

	// Example uses github_subject_format = "both" so legacy and immutable subject claims are trusted
	assert.Contains(t, planOutput, "repo:kbrockhoff/terraform-aws-cicdrole:environment:development")
	assert.Contains(t, planOutput, "repo:kbrockhoff@1822996/terraform-aws-cicdrole@*:environment:development")
}

func TestTerraformGitHubActionsImmutableSubjectOnly(t *testing.T) {
	t.Parallel()
	expectedName := generateTestNamePrefix("ghi")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/github-actions",
		Vars: map[string]interface{}{
			"name_prefix":           expectedName,
			"github_subject_format": "immutable",
			"git_repos":             []string{"terraform-aws-cicdrole@1039095647"},
		},
	}

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Pinned repo ID is used verbatim and legacy (mutable name only) claims are not trusted
	assert.Contains(t, planOutput, "repo:kbrockhoff@1822996/terraform-aws-cicdrole@1039095647:environment:development")
	assert.NotContains(t, planOutput, "repo:kbrockhoff/terraform-aws-cicdrole:")
}

func TestTerraformGitHubActionsImmutableSubjectRequiresOrgID(t *testing.T) {
	t.Parallel()
	expectedName := generateTestNamePrefix("ghx")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/github-actions",
		Vars: map[string]interface{}{
			"name_prefix":           expectedName,
			"github_subject_format": "immutable",
			"git_provider_org_id":   "",
		},
	}

	terraform.Init(t, terraformOptions)
	_, err := terraform.PlanE(t, terraformOptions)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "git_provider_org_id must be set")
}
