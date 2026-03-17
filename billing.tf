# ============================================================================
# terraform-google-project-hierarchy - Billing Configuration
# ============================================================================
#
# Billing accounts are associated with projects via google_billing_project_info.
# This is a separate resource from google_project so that google_project_service
# can express an explicit depends_on, ensuring billing is fully propagated
# before any service enablement API calls are made.
#
# Priority: per-project billing_account > var.default_billing_account
# ============================================================================

resource "google_billing_project_info" "this" {
  for_each = {
    for k, v in local.projects : k => v
    if(v.billing_account != null ? v.billing_account : var.default_billing_account) != null
  }

  project         = google_project.this[each.key].project_id
  billing_account = each.value.billing_account != null ? each.value.billing_account : var.default_billing_account
}
