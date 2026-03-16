# ============================================================================
# terraform-google-project-hierarchy - Monitoring and Alerting
# ============================================================================

locals {
  # Resolve the monitoring project ID from the config key, if specified
  monitoring_project_id = (
    local.monitoring_project_key != null
    ? try(google_project.this[local.monitoring_project_key].project_id, null)
    : null
  )

  # Create notification channel only when both email and monitoring project are set
  create_notification_channel = (
    var.notification_email != "" && local.monitoring_project_id != null
  )
}

# Email notification channel for alert delivery
resource "google_monitoring_notification_channel" "email" {
  count = local.create_notification_channel ? 1 : 0

  project      = local.monitoring_project_id
  display_name = "Email Notification Channel"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }

  depends_on = [google_project_service.this]
}

# Alert policy: CPU utilization threshold
resource "google_monitoring_alert_policy" "cpu_utilization" {
  count = local.monitoring_project_id != null ? 1 : 0

  project      = local.monitoring_project_id
  display_name = "High CPU Utilization"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization above ${var.alert_thresholds.cpu_utilization * 100}%"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
        "resource.type=\"gce_instance\"",
      ])
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_thresholds.cpu_utilization

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = (
    local.create_notification_channel
    ? [google_monitoring_notification_channel.email[0].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}

# Alert policy: error log rate threshold
resource "google_monitoring_alert_policy" "error_rate" {
  count = local.monitoring_project_id != null ? 1 : 0

  project      = local.monitoring_project_id
  display_name = "High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "Error log rate above ${var.alert_thresholds.error_rate} per second"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"logging.googleapis.com/log_entry_count\"",
        "resource.type=\"global\"",
        "metric.labels.severity=\"ERROR\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_thresholds.error_rate

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = (
    local.create_notification_channel
    ? [google_monitoring_notification_channel.email[0].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}

# Alert policy: API service request rate threshold
resource "google_monitoring_alert_policy" "service_usage" {
  count = local.monitoring_project_id != null ? 1 : 0

  project      = local.monitoring_project_id
  display_name = "High Service API Request Rate"
  combiner     = "OR"

  conditions {
    display_name = "API request rate above ${var.alert_thresholds.service_usage} per second"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"serviceruntime.googleapis.com/api/request_count\"",
        "resource.type=\"consumed_api\"",
      ])
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.alert_thresholds.service_usage

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = (
    local.create_notification_channel
    ? [google_monitoring_notification_channel.email[0].id]
    : []
  )

  alert_strategy {
    auto_close = "604800s"
  }

  depends_on = [google_monitoring_notification_channel.email]
}
