// File: test/google_project_hierarchy_test.go
package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGoogleProjectHierarchyMultiBilling verifies that projects with per-project
// alert thresholds, selective alerting, and folder organisation can be
// provisioned within a single hierarchy. Billing accounts and notification
// emails are read directly from hierarchy.json; only the organisation ID and
// a default billing account are supplied at runtime.
//
// Environment variables:
//
//	GCP_ORGANIZATION_ID   (required)
//	GCP_BILLING_ACCOUNT_ID (optional) — default billing account for all projects
func TestGoogleProjectHierarchyMultiBilling(t *testing.T) {
	t.Parallel()

	organizationID := mustEnv(t, "GCP_ORGANIZATION_ID")
	defaultBilling := mustEnvOptional("GCP_BILLING_ACCOUNT_ID")

	suffix := randomProjectSuffix()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/multi-billing",
		Vars: map[string]interface{}{
			"organization_id":        organizationID,
			"default_billing_account": defaultBilling,
			"test_suffix":            suffix,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// --- Folders ---
	folderIDs := terraform.OutputMap(t, terraformOptions, "folder_ids")
	require.NotEmpty(t, folderIDs, "Expected at least one folder to be created")
	assertOutputKeyPresent(t, folderIDs, "finance", "folder")
	assertOutputKeyPresent(t, folderIDs, "engineering", "folder")

	// --- Projects ---
	projectIDs := terraform.OutputMap(t, terraformOptions, "project_ids")
	require.NotEmpty(t, projectIDs, "Expected at least one project to be created")
	assertOutputKeyPresent(t, projectIDs, "finance-reporting", "project")
	assertOutputKeyPresent(t, projectIDs, "finance-analytics", "project")
	assertOutputKeyPresent(t, projectIDs, "eng-platform", "project")
	assertOutputKeyPresent(t, projectIDs, "eng-sandbox", "project")

	// Validate suffixed project IDs match expected values.
	assert.Equal(t, fmt.Sprintf("prj-finance-reporting-%s", suffix), projectIDs["finance-reporting"],
		"finance-reporting project ID mismatch")
	assert.Equal(t, fmt.Sprintf("prj-finance-analytics-%s", suffix), projectIDs["finance-analytics"],
		"finance-analytics project ID mismatch")
	assert.Equal(t, fmt.Sprintf("prj-eng-platform-%s", suffix), projectIDs["eng-platform"],
		"eng-platform project ID mismatch")
	assert.Equal(t, fmt.Sprintf("prj-eng-sandbox-%s", suffix), projectIDs["eng-sandbox"],
		"eng-sandbox project ID mismatch")

	// --- Project numbers ---
	projectNumbers := terraform.OutputMap(t, terraformOptions, "project_numbers")
	assertOutputKeyPresent(t, projectNumbers, "finance-reporting", "project number")
	assertOutputKeyPresent(t, projectNumbers, "finance-analytics", "project number")
	assertOutputKeyPresent(t, projectNumbers, "eng-platform", "project number")
	assertOutputKeyPresent(t, projectNumbers, "eng-sandbox", "project number")

	// --- Services ---
	enabledServices := terraform.OutputMap(t, terraformOptions, "enabled_services")
	assertServiceEnabled(t, enabledServices, "finance-reporting", "bigquery.googleapis.com")
	assertServiceEnabled(t, enabledServices, "finance-reporting", "monitoring.googleapis.com")
	assertServiceEnabled(t, enabledServices, "finance-analytics", "storage.googleapis.com")
	assertServiceEnabled(t, enabledServices, "finance-analytics", "monitoring.googleapis.com")
	assertServiceEnabled(t, enabledServices, "eng-platform", "serviceusage.googleapis.com")
	assertServiceEnabled(t, enabledServices, "eng-platform", "monitoring.googleapis.com")
	assertServiceEnabled(t, enabledServices, "eng-sandbox", "iam.googleapis.com")

	// --- Alert policies: present for alert-enabled projects, absent for eng-sandbox ---
	alertPolicyIDs := terraform.OutputJson(t, terraformOptions, "alert_policy_ids")
	require.Contains(t, alertPolicyIDs, "finance-reporting",
		"Expected alert policies for finance-reporting")
	require.Contains(t, alertPolicyIDs, "finance-analytics",
		"Expected alert policies for finance-analytics")
	require.Contains(t, alertPolicyIDs, "eng-platform",
		"Expected alert policies for eng-platform")
	require.NotContains(t, alertPolicyIDs, "eng-sandbox",
		"eng-sandbox has enable_alerts=false and should have no alert policies")

}

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
