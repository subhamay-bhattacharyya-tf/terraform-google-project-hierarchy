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
  description = "Resource names of all created monitoring alert policies."
  value = compact([
    try(google_monitoring_alert_policy.cpu_utilization[0].name, ""),
    try(google_monitoring_alert_policy.error_rate[0].name, ""),
    try(google_monitoring_alert_policy.service_usage[0].name, ""),
  ])
}

output "notification_channel_id" {
  description = "Resource name of the monitoring email notification channel, if created."
  value       = try(google_monitoring_notification_channel.email[0].name, null)
}
