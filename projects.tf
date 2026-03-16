# ============================================================================
# terraform-google-project-hierarchy - Project Resources
# ============================================================================

locals {
  # Merged map of all created folder resource names (folders/<numeric_id> format)
  # Used to resolve folder_key references in project configurations
  all_folder_names = merge(
    { for k, v in google_folder.l0 : k => v.name },
    { for k, v in google_folder.l1 : k => v.name },
    { for k, v in google_folder.l2 : k => v.name },
  )
}

resource "google_project" "this" {
  for_each = local.projects

  name            = each.value.name
  project_id      = each.value.project_id
  folder_id       = local.all_folder_names[each.value.folder_key]
  billing_account = try(each.value.billing_account, var.default_billing_account)

  labels          = try(each.value.labels, {})
  deletion_policy = try(each.value.deletion_policy, "PREVENT")

  depends_on = [google_folder.l0, google_folder.l1, google_folder.l2]
}
