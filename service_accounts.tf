# ============================================================================
# terraform-google-project-hierarchy - Service Accounts
# ============================================================================
#
# One service account is created per project that has enable_service_account = true.
#
# Naming convention:
#   account_id   : sa-<project-key>  (max 30 chars, lowercase, hyphens only)
#   display_name : SA-<project name>
#
# The service account is intended for use in GitHub CI/CD pipelines.
# Workload Identity Federation bindings should be added separately.
# ============================================================================

resource "google_service_account" "this" {
  for_each = {
    for k, v in local.projects : k => v
    if try(v.enable_service_account, false)
  }

  project      = google_project.this[each.key].project_id
  account_id   = substr("sa-${replace(lower(each.key), "_", "-")}", 0, 30)
  display_name = "SA-${each.value.name}"
  description  = "Service account for GitHub CI/CD pipeline"

  depends_on = [google_project_service.this]
}
