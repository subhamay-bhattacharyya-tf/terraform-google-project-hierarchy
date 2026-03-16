# ============================================================================
# terraform-google-project-hierarchy - Billing Configuration
# ============================================================================
#
# Billing accounts are associated with projects via the billing_account
# attribute on each google_project resource (see projects.tf).
#
# Priority: per-project billing_account > var.default_billing_account
#
# To manage billing budgets, use google_billing_budget from the google-beta
# provider. Example:
#
#   resource "google_billing_budget" "this" {
#     billing_account = var.default_billing_account
#     display_name    = "Project budget"
#     amount {
#       specified_amount { currency_code = "USD"; units = "1000" }
#     }
#     threshold_rules { threshold_percent = 0.8 }
#   }
# ============================================================================
