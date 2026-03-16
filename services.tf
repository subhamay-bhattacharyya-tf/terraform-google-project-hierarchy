# ============================================================================
# terraform-google-project-hierarchy - API/Service Enablement
# ============================================================================

resource "google_project_service" "this" {
  for_each = local.project_services_map

  project                    = each.value.project_id
  service                    = each.value.service
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [google_project.this]
}
