# ============================================================================
# examples/multi-billing - Multi-Billing, Multi-Threshold, Multi-Notification
#                          GCP Project Hierarchy Example
# ============================================================================
#
# This example demonstrates three per-project overrides within a single
# hierarchy:
#
#   1. Billing accounts  — Finance and Engineering projects use separate
#                          billing accounts; eng-sandbox falls back to the
#                          module-level default.
#
#   2. Notification emails — Finance projects alert to a Finance ops mailbox;
#                            Engineering projects alert to an Engineering ops
#                            mailbox. eng-sandbox has no alerts.
#
#   3. Alert thresholds  — Each production project defines its own CPU,
#                          error-rate, and service-usage thresholds tuned to
#                          its workload characteristics.
#
# Billing account IDs and alert email addresses are kept out of hierarchy.json
# using placeholder strings that are substituted at plan time via a locals
# merge. This prevents secrets from being committed to source control.
#
# Usage:
#   terraform init
#   terraform plan \
#     -var organization_id=<YOUR_ORG_ID> \
#     -var finance_billing_account=<FINANCE_BILLING_ID> \
#     -var engineering_billing_account=<ENGINEERING_BILLING_ID> \
#     -var finance_notification_email=<FINANCE_OPS_EMAIL> \
#     -var engineering_notification_email=<ENGINEERING_OPS_EMAIL>
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
      k => merge(
        v,
        # Suffix project IDs for uniqueness across test runs.
        var.test_suffix == "" ? {} : { project_id = "${v.project_id}-${var.test_suffix}" },
        # Replace billing account placeholders with runtime variable values.
        try(v.billing_account, "") == "FINANCE-BILLING-ACCT" ? {
          billing_account = var.finance_billing_account
        } : {},
        try(v.billing_account, "") == "ENGINEERING-BILLING-ACCT" ? {
          billing_account = var.engineering_billing_account
        } : {},
        # Replace notification email placeholders with runtime variable values.
        try(v.notification_email, "") == "FINANCE-ALERT-EMAIL" ? {
          notification_email = var.finance_notification_email
        } : {},
        try(v.notification_email, "") == "ENGINEERING-ALERT-EMAIL" ? {
          notification_email = var.engineering_notification_email
        } : {},
      )
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

variable "finance_billing_account" {
  description = "Billing account ID assigned to Finance projects."
  type        = string
  default     = null
}

variable "engineering_billing_account" {
  description = "Billing account ID assigned to Engineering projects."
  type        = string
  default     = null
}

variable "default_billing_account" {
  description = "Fallback billing account ID for projects with no explicit billing_account set."
  type        = string
  default     = null
}

variable "finance_notification_email" {
  description = "Alert notification email address for Finance projects."
  type        = string
  default     = ""
}

variable "engineering_notification_email" {
  description = "Alert notification email address for Engineering projects."
  type        = string
  default     = ""
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

output "alert_policy_ids" {
  description = "Monitoring alert policy IDs by project key."
  value       = module.gcp_project_hierarchy.alert_policy_ids
}

output "notification_channel_ids" {
  description = "Email notification channel resource names by project key."
  value       = module.gcp_project_hierarchy.notification_channel_ids
}
