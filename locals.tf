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
    if v.parent_type == "folder" && contains(keys(local.folders_l0), try(v.parent_key, ""))
  }

  # Level 2: folders whose parent is an L1 folder
  folders_l2 = {
    for k, v in local.folders : k => v
    if v.parent_type == "folder" && contains(keys(local.folders_l1), try(v.parent_key, ""))
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

  # Optional key of the project that hosts monitoring resources
  monitoring_project_key = try(var.hierarchy_config.monitoring_project_key, null)
}
