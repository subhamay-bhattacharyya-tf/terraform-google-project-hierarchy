# ============================================================================
# terraform-google-project-hierarchy - Variables
# ============================================================================

variable "organization_id" {
  description = "The GCP organization ID under which all folders and projects will be created."
  type        = string
}

variable "region" {
  description = "Default GCP region for provider configuration."
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "The name of this Terraform project configuration."
  type        = string
  default     = "terraform-google-project-hierarchy"
}

variable "default_billing_account" {
  description = "Default billing account ID to associate with projects. Can be overridden per project in hierarchy_config."
  type        = string
  default     = null
}

variable "notification_email" {
  description = "Email address for monitoring alert notifications. Leave empty to skip notification channel creation."
  type        = string
  default     = ""
}

variable "alert_thresholds" {
  description = "Default thresholds for billing budget alert policies. Per-project values in hierarchy_config take precedence."
  type = object({
    billing_amount = optional(number, 1)
    threshold_rules = optional(list(object({
      threshold_percent = number
      spend_basis       = optional(string, "CURRENT_SPEND")
    })), [
      { threshold_percent = 0.25, spend_basis = "CURRENT_SPEND" },
      { threshold_percent = 0.5, spend_basis = "CURRENT_SPEND" },
      { threshold_percent = 1.0, spend_basis = "CURRENT_SPEND" },
      { threshold_percent = 1.0, spend_basis = "FORECASTED_SPEND" },
    ])
  })
  default = {}
}

variable "hierarchy_config" {
  description = <<-EOT
    JSON-driven configuration object defining the full GCP organizational hierarchy.
    Supports folders (up to 3 nesting levels), projects, billing configuration,
    API enablement, labels, and alert settings.

    Example:
    {
      "folders": {
        "shared": {
          "display_name": "Shared",
          "parent_type": "organization"
        },
        "platform": {
          "display_name": "Platform",
          "parent_type": "folder",
          "parent_key": "shared"
        }
      },
      "projects": {
        "github-cicd": {
          "name": "GitHub CICD",
          "project_id": "prj-shared-github-cicd",
          "folder_key": "platform",
          "billing_account": null,
          "services": ["iam.googleapis.com", "cloudresourcemanager.googleapis.com"],
          "labels": { "env": "shared" },
          "enable_alerts": true
        }
      },
    }
  EOT
  type = object({
    folders = optional(map(object({
      display_name = string
      parent_type  = string
      parent_key   = optional(string)
    })), {})
    projects = optional(map(object({
      name               = string
      project_id         = string
      folder_key         = string
      billing_account    = optional(string)
      notification_email = optional(string)
      alert_thresholds = optional(object({
        billing_amount = optional(number)
        threshold_rules = optional(list(object({
          threshold_percent = number
          spend_basis       = optional(string, "CURRENT_SPEND")
        })))
      }))
      services                = optional(list(string), [])
      labels                  = optional(map(string), {})
      enable_alerts           = optional(bool, false)
      enable_service_account  = optional(bool, false)
      deletion_policy         = optional(string, "PREVENT")
    })), {})
  })
}
