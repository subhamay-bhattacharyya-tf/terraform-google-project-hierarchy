# ============================================================================
# terraform-google-project-hierarchy - Monitoring and Alerting
# ============================================================================
#
# One notification channel and three alert policies are created per project
# that has enable_alerts = true. Each project manages its own monitoring
# resources independently.
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
    k => coalesce(try(v.notification_email, null), var.notification_email, "")
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

# Alert policy: CPU utilization threshold — one per alert-enabled project
resource "google_monitoring_alert_policy" "cpu_utilization" {
  for_each = local.alert_projects

  project      = google_project.this[each.key].project_id
  display_name = "High CPU Utilization"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization above ${local.alert_project_thresholds[each.key].cpu_utilization * 100}%"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
        "resource.type=\"gce_instance\"",
      ])
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = local.alert_project_thresholds[each.key].cpu_utilization

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = (
    contains(keys(google_monitoring_notification_channel.email), each.key)
    ? [google_monitoring_notification_channel.email[each.key].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}

# Alert policy: error log rate threshold — one per alert-enabled project
resource "google_monitoring_alert_policy" "error_rate" {
  for_each = local.alert_projects

  project      = google_project.this[each.key].project_id
  display_name = "High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "Error log rate above ${local.alert_project_thresholds[each.key].error_rate} per second"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"logging.googleapis.com/log_entry_count\"",
        "resource.type=\"global\"",
        "metric.labels.severity=\"ERROR\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = local.alert_project_thresholds[each.key].error_rate

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = (
    contains(keys(google_monitoring_notification_channel.email), each.key)
    ? [google_monitoring_notification_channel.email[each.key].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}

# Alert policy: API service request rate threshold — one per alert-enabled project
resource "google_monitoring_alert_policy" "service_usage" {
  for_each = local.alert_projects

  project      = google_project.this[each.key].project_id
  display_name = "High Service API Request Rate"
  combiner     = "OR"

  conditions {
    display_name = "API request rate above ${local.alert_project_thresholds[each.key].service_usage} per second"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"serviceruntime.googleapis.com/api/request_count\"",
        "resource.type=\"consumed_api\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = local.alert_project_thresholds[each.key].service_usage

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = (
    contains(keys(google_monitoring_notification_channel.email), each.key)
    ? [google_monitoring_notification_channel.email[each.key].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}
