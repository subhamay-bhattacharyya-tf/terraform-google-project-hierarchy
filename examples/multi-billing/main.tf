# ============================================================================
# examples/multi-billing - Per-Team Billing Budget Alert Example
# ============================================================================
#
# This example demonstrates per-project billing budget overrides within a
# single hierarchy:
#
#   1. Billing budgets   — Each production project defines its own billing
#                          amount threshold tuned to its expected spend.
#
#   2. Selective alerting — eng-sandbox has enable_alerts=false and therefore
#                           receives no billing budget alert.
#
#   3. Folder organisation — Finance and Engineering projects are grouped into
#                            their own top-level folders under the organisation.
#
# All projects share a single billing account supplied via default_billing_account.
# Per-project billing account overrides can be added directly to hierarchy.json.
#
# Usage:
#   terraform init
#   terraform plan \
#     -var organization_id=<YOUR_ORG_ID> \
#     -var default_billing_account=<BILLING_ID>
#   terraform apply ...
# ============================================================================

locals {
  base_config = jsondecode(file("${path.module}/hierarchy.json"))

  hierarchy_config = merge(local.base_config, {
    folders = {
      for k, v in local.base_config.folders :
      k => var.test_suffix == "" ? v : merge(v, {
        display_name = "${v.display_name}-${var.test_suffix}"
      })
    }
    projects = {
      for k, v in local.base_config.projects :
      k => var.test_suffix == "" ? v : merge(v, {
        project_id = "${v.project_id}-${var.test_suffix}"
      })
    }
  })
}

module "gcp_project_hierarchy" {
  source = "../../"

  organization_id         = var.organization_id
  region                  = "us-central1"
  default_billing_account = var.default_billing_account

  hierarchy_config = local.hierarchy_config
}

# ============================================================================
# Variables
# ============================================================================

variable "organization_id" {
  description = "The GCP organization ID."
  type        = string
}

variable "default_billing_account" {
  description = "Billing account ID applied to all projects in this hierarchy."
  type        = string
  default     = null
}

variable "test_suffix" {
  description = "Optional short suffix appended to project IDs and folder display names during testing to ensure uniqueness across runs. Max 4 characters."
  type        = string
  default     = ""
}

# ============================================================================
# Outputs
# ============================================================================

output "folder_ids" {
  description = "Created folder IDs by key."
  value       = module.gcp_project_hierarchy.folder_ids
}

output "project_ids" {
  description = "Created project IDs by key."
  value       = module.gcp_project_hierarchy.project_ids
}

output "project_numbers" {
  description = "Created project numbers by key."
  value       = module.gcp_project_hierarchy.project_numbers
}

output "enabled_services" {
  description = "Enabled APIs by project key."
  value       = module.gcp_project_hierarchy.enabled_services
}

output "billing_budget_ids" {
  description = "Billing budget resource names by project key."
  value       = module.gcp_project_hierarchy.billing_budget_ids
}

output "notification_channel_ids" {
  description = "Email notification channel resource names by project key."
  value       = module.gcp_project_hierarchy.notification_channel_ids
}

output "service_account_emails" {
  description = "Service account emails by project key."
  value       = module.gcp_project_hierarchy.service_account_emails
}
