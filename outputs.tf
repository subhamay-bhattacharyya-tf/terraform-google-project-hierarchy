# ============================================================================
# terraform-google-project-hierarchy - Outputs
# ============================================================================

output "folder_ids" {
  description = "Map of folder keys to their numeric GCP folder IDs."
  value = merge(
    { for k, v in google_folder.l0 : k => v.folder_id },
    { for k, v in google_folder.l1 : k => v.folder_id },
    { for k, v in google_folder.l2 : k => v.folder_id },
  )
}

output "folder_names" {
  description = "Map of folder keys to their full GCP resource names (folders/<id> format)."
  value = merge(
    { for k, v in google_folder.l0 : k => v.name },
    { for k, v in google_folder.l1 : k => v.name },
    { for k, v in google_folder.l2 : k => v.name },
  )
}

output "project_ids" {
  description = "Map of project keys to their GCP project IDs."
  value       = { for k, v in google_project.this : k => v.project_id }
}

output "project_numbers" {
  description = "Map of project keys to their GCP project numbers."
  value       = { for k, v in google_project.this : k => v.number }
}

output "enabled_services" {
  description = "Map of 'project_key/service' to the enabled service name."
  value       = { for k, v in google_project_service.this : k => v.service }
}

output "alert_policy_ids" {
  description = "Map of project key to list of monitoring alert policy resource names for that project."
  value = {
    for k in keys(local.alert_projects) : k => compact([
      try(google_monitoring_alert_policy.cpu_utilization[k].name, ""),
      try(google_monitoring_alert_policy.error_rate[k].name, ""),
      try(google_monitoring_alert_policy.service_usage[k].name, ""),
    ])
  }
}

output "notification_channel_ids" {
  description = "Map of project key to email notification channel resource name, for projects that have one configured."
  value       = { for k, v in google_monitoring_notification_channel.email : k => v.name }
}
