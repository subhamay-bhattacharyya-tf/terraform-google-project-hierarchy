# ============================================================================
# terraform-google-project-hierarchy - Local Values
# ============================================================================

locals {
  folders  = try(var.hierarchy_config.folders, {})
  projects = try(var.hierarchy_config.projects, {})

  # Level 0: folders whose parent is the GCP organization root
  folders_l0 = {
    for k, v in local.folders : k => v
    if v.parent_type == "organization"
  }

  # Level 1: folders whose parent is an L0 folder
  folders_l1 = {
    for k, v in local.folders : k => v
    if v.parent_type == "folder" && contains(keys(local.folders_l0), v.parent_key != null ? v.parent_key : "")
  }

  # Level 2: folders whose parent is an L1 folder
  folders_l2 = {
    for k, v in local.folders : k => v
    if v.parent_type == "folder" && contains(keys(local.folders_l1), v.parent_key != null ? v.parent_key : "")
  }

  # Flattened list of project + service combinations using config values
  project_services = flatten([
    for proj_key, proj in local.projects : [
      for svc in try(proj.services, []) : {
        project_key = proj_key
        service     = svc
        project_id  = proj.project_id
      }
    ]
  ])

  # Keyed map for use with for_each: "project_key/service" => item
  project_services_map = {
    for item in local.project_services : "${item.project_key}/${item.service}" => item
  }

  # Projects that have alerting enabled
  alert_projects = {
    for k, v in local.projects : k => v
    if try(v.enable_alerts, false)
  }

  # Per-project resolved alert thresholds.
  # Each field falls back individually: per-project value > module-level default.
  alert_project_thresholds = {
    for k, v in local.alert_projects : k => {
      cpu_utilization = try(v.alert_thresholds.cpu_utilization, null) != null ? v.alert_thresholds.cpu_utilization : var.alert_thresholds.cpu_utilization
      error_rate      = try(v.alert_thresholds.error_rate, null) != null ? v.alert_thresholds.error_rate : var.alert_thresholds.error_rate
      service_usage   = try(v.alert_thresholds.service_usage, null) != null ? v.alert_thresholds.service_usage : var.alert_thresholds.service_usage
    }
  }
}
