// File: test/google_project_hierarchy_test.go
package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestGoogleProjectHierarchy(t *testing.T) {
	t.Parallel()

	organizationID := mustEnv(t, "GCP_ORGANIZATION_ID")
	billingAccount := mustEnvOptional("GCP_BILLING_ACCOUNT_ID")

	// Unique suffix prevents 409 conflicts when a previous run left projects
	// behind (e.g. due to a failed destroy). GCP project IDs are globally unique.
	suffix := randomProjectSuffix()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"organization_id": organizationID,
			"billing_account": billingAccount,
			"test_suffix":     suffix,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate folder IDs are non-empty
	folderIDs := terraform.OutputMap(t, terraformOptions, "folder_ids")
	require.NotEmpty(t, folderIDs, "Expected at least one folder to be created")

	assertOutputKeyPresent(t, folderIDs, "shared", "folder")
	assertOutputKeyPresent(t, folderIDs, "platform", "folder")
	assertOutputKeyPresent(t, folderIDs, "data", "folder")

	// Validate project IDs are non-empty
	projectIDs := terraform.OutputMap(t, terraformOptions, "project_ids")
	require.NotEmpty(t, projectIDs, "Expected at least one project to be created")

	assertOutputKeyPresent(t, projectIDs, "github-cicd", "project")
	assertOutputKeyPresent(t, projectIDs, "data-warehouse", "project")

	// Validate project IDs match expected values (base ID + run-specific suffix)
	assert.Equal(t, fmt.Sprintf("prj-shared-github-cicd-%s", suffix), projectIDs["github-cicd"],
		"github-cicd project ID mismatch")
	assert.Equal(t, fmt.Sprintf("prj-shared-data-warehouse-%s", suffix), projectIDs["data-warehouse"],
		"data-warehouse project ID mismatch")

	// Validate project numbers are populated
	projectNumbers := terraform.OutputMap(t, terraformOptions, "project_numbers")
	assertOutputKeyPresent(t, projectNumbers, "github-cicd", "project number")
	assertOutputKeyPresent(t, projectNumbers, "data-warehouse", "project number")

	// Validate enabled services
	enabledServices := terraform.OutputMap(t, terraformOptions, "enabled_services")
	assertServiceEnabled(t, enabledServices, "github-cicd", "iam.googleapis.com")
	assertServiceEnabled(t, enabledServices, "github-cicd", "cloudresourcemanager.googleapis.com")
	assertServiceEnabled(t, enabledServices, "data-warehouse", "bigquery.googleapis.com")
}
