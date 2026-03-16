# ============================================================================
# examples/basic - Basic GCP Project Hierarchy Example
# ============================================================================
#
# This example demonstrates a minimal JSON-driven GCP organizational hierarchy
# with shared and platform folders and a sample project.
#
# Usage:
#   terraform init
#   terraform plan -var organization_id=<YOUR_ORG_ID>
#   terraform apply -var organization_id=<YOUR_ORG_ID>
# ============================================================================

locals {
  base_config = jsondecode(file("${path.module}/hierarchy.json"))

  # When test_suffix is provided, append it to project IDs and folder display
  # names to avoid GCP conflicts across test runs. Project IDs are globally
  # unique and folder display names must be unique within their parent — both
  # may linger if a prior run failed cleanup.
  hierarchy_config = var.test_suffix == "" ? local.base_config : merge(local.base_config, {
    folders = {
      for k, v in local.base_config.folders :
      k => merge(v, { display_name = "${v.display_name}-${var.test_suffix}" })
    }
    projects = {
      for k, v in local.base_config.projects :
      k => merge(v, { project_id = "${v.project_id}-${var.test_suffix}" })
    }
  })
}

module "gcp_project_hierarchy" {
  source = "../../"

  organization_id         = var.organization_id
  region                  = "us-central1"
  default_billing_account = var.billing_account
  notification_email      = var.notification_email

  alert_thresholds = {
    cpu_utilization = 0.8
    error_rate      = 0.05
    service_usage   = 100.0
  }

  hierarchy_config = local.hierarchy_config
}

# ============================================================================
# Variables
# ============================================================================

variable "organization_id" {
  description = "The GCP organization ID."
  type        = string
}

variable "billing_account" {
  description = "Default GCP billing account ID."
  type        = string
  default     = null
}

variable "notification_email" {
  description = "Email address for monitoring alert notifications."
  type        = string
  default     = ""
}

variable "test_suffix" {
  description = "Optional short suffix appended to project IDs during testing to ensure uniqueness across runs. Max 4 characters."
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
  description = "Monitoring alert policy IDs."
  value       = module.gcp_project_hierarchy.alert_policy_ids
}
