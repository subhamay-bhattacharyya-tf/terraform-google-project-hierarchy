# ============================================================================
# terraform-google-project-hierarchy - Service Accounts
# ============================================================================
#
# One service account is created per project that has service_account.enabled = true.
#
# Fields sourced from service_account object:
#   account_id   : service_account.account_id (falls back to sa-<project-key>)
#   display_name : service_account.display_name (falls back to SA-<project name>)
#   project_roles: list of IAM roles to bind to the service account on the project
#
# ============================================================================

locals {
  sa_projects = {
    for k, v in local.projects : k => v
    if try(v.service_account.enabled, false)
  }

  # Flatten project+role combinations for IAM bindings
  sa_project_roles = flatten([
    for proj_key, proj in local.sa_projects : [
      for role in try(proj.service_account.project_roles, []) : {
        proj_key = proj_key
        role     = role
      }
    ]
  ])

  sa_project_roles_map = {
    for item in local.sa_project_roles : "${item.proj_key}/${item.role}" => item
  }
}

resource "google_service_account" "this" {
  for_each = local.sa_projects

  project      = google_project.this[each.key].project_id
  account_id   = try(each.value.service_account.account_id, null) != null ? each.value.service_account.account_id : substr("sa-${replace(lower(each.key), "_", "-")}", 0, 30)
  display_name = try(each.value.service_account.display_name, null) != null ? each.value.service_account.display_name : "SA-${each.value.name}"
  description  = "Service account for GitHub CI/CD pipeline"

  depends_on = [google_project_service.this]
}

resource "google_project_iam_member" "sa_roles" {
  for_each = local.sa_project_roles_map

  project = google_project.this[each.value.proj_key].project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this[each.value.proj_key].email}"
}
