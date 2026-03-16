# ============================================================================
# terraform-google-project-hierarchy - Folder Resources
# ============================================================================

# Level 0: direct children of the GCP organization
resource "google_folder" "l0" {
  for_each = local.folders_l0

  display_name = each.value.display_name
  parent       = "organizations/${var.organization_id}"
}

# Level 1: children of Level 0 folders
resource "google_folder" "l1" {
  for_each = local.folders_l1

  display_name = each.value.display_name
  parent       = google_folder.l0[each.value.parent_key].name

  depends_on = [google_folder.l0]
}

# Level 2: children of Level 1 folders
resource "google_folder" "l2" {
  for_each = local.folders_l2

  display_name = each.value.display_name
  parent       = google_folder.l1[each.value.parent_key].name

  depends_on = [google_folder.l1]
}
