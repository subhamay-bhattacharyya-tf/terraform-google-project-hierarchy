# ============================================================================
# terraform-google-project-hierarchy - Billing Budget Alerts
# ============================================================================
#
# One notification channel and one billing budget are created per project
# that has enable_alerts = true and a billing account assigned.
#
# Budget display name: "<project name> - Billing Alert"
#
# Notification email priority (per project):
#   1. projects[key].notification_email  (per-project override in hierarchy_config)
#   2. var.notification_email            (module-level default)
#   3. No channel created               (if both are unset or empty)
# ============================================================================

locals {
  # Resolved notification email per alert-enabled project.
  # Per-project override takes precedence over the module-level default.
  alert_project_emails = {
    for k, v in local.alert_projects :
    k => try(coalesce(try(v.notification_email, null), var.notification_email), "")
  }

  # Alert-enabled projects that also have a billing account (required for budgets).
  alert_projects_with_billing = {
    for k, v in local.alert_projects : k => v
    if(v.billing_account != null ? v.billing_account : var.default_billing_account) != null
  }
}

# One email notification channel per alert-enabled project that has an email configured
resource "google_monitoring_notification_channel" "email" {
  for_each = {
    for k, v in local.alert_projects :
    k => v
    if local.alert_project_emails[k] != ""
  }

  project      = google_project.this[each.key].project_id
  display_name = "Email Notification Channel"
  type         = "email"

  labels = {
    email_address = local.alert_project_emails[each.key]
  }

  depends_on = [google_project_service.this]
}

# Billing budget alert — one per alert-enabled project with a billing account
resource "google_billing_budget" "this" {
  for_each = local.alert_projects_with_billing

  billing_account = each.value.billing_account != null ? each.value.billing_account : var.default_billing_account
  display_name    = "${each.value.name} - Billing Alert"

  budget_filter {
    projects = ["projects/${google_project.this[each.key].number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(local.alert_project_thresholds[each.key].billing_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = local.alert_project_thresholds[each.key].threshold_rules
    content {
      threshold_percent = threshold_rules.value.threshold_percent
      spend_basis       = threshold_rules.value.spend_basis
    }
  }

  all_updates_rule {
    monitoring_notification_channels = (
      contains(keys(google_monitoring_notification_channel.email), each.key)
      ? [google_monitoring_notification_channel.email[each.key].id]
      : []
    )
    disable_default_iam_recipients = false
  }

  depends_on = [
    google_billing_project_info.this,
    google_monitoring_notification_channel.email,
  ]
}
