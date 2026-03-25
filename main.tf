# ============================================================================
# terraform-google-project-hierarchy - Module Entrypoint
# ============================================================================
#
# This module provisions a JSON-driven GCP organizational hierarchy including:
#   - Multi-level folder structure under an organization (up to 3 levels)
#   - GCP projects placed within folders
#   - Billing account association per project
#   - API/service enablement per project
#   - Monitoring notification channels and alert policies
#
# Resources are defined across focused companion files:
#   - folders.tf   : google_folder (L0 / L1 / L2)
#   - projects.tf  : google_project
#   - billing.tf   : google_project_billing_info
#   - services.tf  : google_project_service
#   - alerts.tf    : google_monitoring_notification_channel
#                    google_monitoring_alert_policy
#
# Configuration is driven by the hierarchy_config input variable.
# See variables.tf for the full schema and examples.
# ============================================================================
