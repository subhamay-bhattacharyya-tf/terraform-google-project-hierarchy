# Example: Multi-Billing, Multi-Threshold, Multi-Notification GCP Hierarchy

This example demonstrates three independent per-project overrides working together in a single GCP organizational hierarchy using the `terraform-google-project-hierarchy` module:

| Feature | What it shows |
|---|---|
| **Per-project billing accounts** | Finance and Engineering each have a dedicated billing account; `eng-sandbox` falls back to the module default |
| **Per-project notification emails** | Finance projects alert to a Finance ops mailbox; Engineering projects alert to an Engineering ops mailbox |
| **Per-project alert thresholds** | Each production project defines its own CPU, error-rate, and service-usage thresholds tuned to its workload |

Use this as a reference for enterprise setups where cost allocation, on-call routing, and alerting sensitivity differ by department or workload type.

## Architecture

```
Organization
├── Finance (L0 folder)
│   ├── finance-reporting  billing: Finance  │  alerts → finance-ops@  │  cpu≤75%  err≤0.02/s  svc≤200/s
│   └── finance-analytics  billing: Finance  │  alerts → finance-ops@  │  cpu≤85%  err≤0.05/s  svc≤1000/s
└── Engineering (L0 folder)
    ├── eng-platform  billing: Engineering  │  alerts → eng-ops@  │  cpu≤90%  err≤0.1/s  svc≤500/s
    └── eng-sandbox   billing: default      │  no alerts
```

## Per-Project Overrides at a Glance

### Billing Accounts

| Project | Billing Source |
|---|---|
| `finance-reporting` | `var.finance_billing_account` (per-project) |
| `finance-analytics` | `var.finance_billing_account` (per-project) |
| `eng-platform` | `var.engineering_billing_account` (per-project) |
| `eng-sandbox` | `var.default_billing_account` (module fallback) |

### Notification Emails

| Project | Email Source | Alerts |
|---|---|---|
| `finance-reporting` | `var.finance_notification_email` (per-project) | yes |
| `finance-analytics` | `var.finance_notification_email` (per-project) | yes |
| `eng-platform` | `var.engineering_notification_email` (per-project) | yes |
| `eng-sandbox` | — | no |

### Alert Thresholds

| Project | CPU Utilization | Error Rate (per sec) | Service Usage (per sec) |
|---|---|---|---|
| `finance-reporting` | 75% | 0.02 | 200 |
| `finance-analytics` | 85% | 0.05 | 1000 |
| `eng-platform` | 90% | 0.1 | 500 |
| `eng-sandbox` | — | — | — |

Fields not specified fall back to the module-level `var.alert_thresholds` defaults (cpu: 0.8, error: 0.05, service: 0.9). In this example all three thresholds are set explicitly on every alert-enabled project.

## Resources Provisioned

| Resource | Description |
|---|---|
| `google_folder` | `finance`, `engineering` |
| `google_project` | `finance-reporting`, `finance-analytics`, `eng-platform`, `eng-sandbox` |
| `google_billing_project_info` | Per-project billing associations (up to 3 distinct accounts) |
| `google_project_service` | BigQuery, Storage, IAM, CRM, Service Usage, Monitoring APIs per project |
| `google_monitoring_notification_channel` | One email channel per alert-enabled project (when email is set) |
| `google_monitoring_alert_policy` | CPU, error rate, and service usage policies per alert-enabled project |

## Usage

### 1. Copy or reference the example

```hcl
module "gcp_project_hierarchy" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy//examples/multi-billing"

  organization_id                = "123456789012"
  finance_billing_account        = "FINANCE-111111-AAAAAA"
  engineering_billing_account    = "ENGINEE-222222-BBBBBB"
  default_billing_account        = "DEFAULT-333333-CCCCCC"
  finance_notification_email     = "finance-ops@example.com"
  engineering_notification_email = "eng-ops@example.com"
}
```

Or run directly as a root module:

```bash
git clone https://github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy.git
cd terraform-google-project-hierarchy/examples/multi-billing
```

### 2. Configure variables

Create a `terraform.tfvars` file:

```hcl
organization_id                = "123456789012"
finance_billing_account        = "FINANCE-111111-AAAAAA"
engineering_billing_account    = "ENGINEE-222222-BBBBBB"
default_billing_account        = "DEFAULT-333333-CCCCCC"
finance_notification_email     = "finance-ops@example.com"
engineering_notification_email = "eng-ops@example.com"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## How the Placeholder Pattern Works

Sensitive values (billing account IDs, email addresses) are kept out of `hierarchy.json` using placeholder strings. `main.tf` replaces them at plan time with a `locals` merge:

```hcl
projects = {
  for k, v in local.base_config.projects :
  k => merge(
    v,
    # Billing account substitution
    try(v.billing_account, "") == "FINANCE-BILLING-ACCT" ? {
      billing_account = var.finance_billing_account
    } : {},
    try(v.billing_account, "") == "ENGINEERING-BILLING-ACCT" ? {
      billing_account = var.engineering_billing_account
    } : {},
    # Notification email substitution
    try(v.notification_email, "") == "FINANCE-ALERT-EMAIL" ? {
      notification_email = var.finance_notification_email
    } : {},
    try(v.notification_email, "") == "ENGINEERING-ALERT-EMAIL" ? {
      notification_email = var.engineering_notification_email
    } : {},
  )
}
```

`alert_thresholds` values are plain numbers with no security sensitivity, so they are set directly in `hierarchy.json` with no substitution needed.

To add a new department:

1. Add placeholder strings in `hierarchy.json` for that department's billing account and email.
2. Add corresponding input variables in `main.tf`.
3. Add two more `merge` conditions (one for billing, one for email).

## Hierarchy JSON

```json
{
  "folders": {
    "finance": {
      "display_name": "Finance",
      "parent_type": "organization"
    },
    "engineering": {
      "display_name": "Engineering",
      "parent_type": "organization"
    }
  },
  "projects": {
    "finance-reporting": {
      "name": "Finance Reporting",
      "project_id": "prj-finance-reporting",
      "folder_key": "finance",
      "billing_account": "FINANCE-BILLING-ACCT",
      "notification_email": "FINANCE-ALERT-EMAIL",
      "alert_thresholds": {
        "cpu_utilization": 0.75,
        "error_rate": 0.02,
        "service_usage": 200.0
      },
      "services": [
        "bigquery.googleapis.com",
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "monitoring.googleapis.com"
      ],
      "labels": { "env": "prod", "team": "finance", "managed-by": "terraform" },
      "enable_alerts": true
    },
    "finance-analytics": {
      "name": "Finance Analytics",
      "project_id": "prj-finance-analytics",
      "folder_key": "finance",
      "billing_account": "FINANCE-BILLING-ACCT",
      "notification_email": "FINANCE-ALERT-EMAIL",
      "alert_thresholds": {
        "cpu_utilization": 0.85,
        "error_rate": 0.05,
        "service_usage": 1000.0
      },
      "services": [
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "monitoring.googleapis.com"
      ],
      "labels": { "env": "prod", "team": "finance", "managed-by": "terraform" },
      "enable_alerts": true
    },
    "eng-platform": {
      "name": "Engineering Platform",
      "project_id": "prj-eng-platform",
      "folder_key": "engineering",
      "billing_account": "ENGINEERING-BILLING-ACCT",
      "notification_email": "ENGINEERING-ALERT-EMAIL",
      "alert_thresholds": {
        "cpu_utilization": 0.9,
        "error_rate": 0.1,
        "service_usage": 500.0
      },
      "services": [
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "serviceusage.googleapis.com",
        "monitoring.googleapis.com"
      ],
      "labels": { "env": "prod", "team": "engineering", "managed-by": "terraform" },
      "enable_alerts": true
    },
    "eng-sandbox": {
      "name": "Engineering Sandbox",
      "project_id": "prj-eng-sandbox",
      "folder_key": "engineering",
      "services": [
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com"
      ],
      "labels": { "env": "dev", "team": "engineering", "managed-by": "terraform" },
      "enable_alerts": false
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `organization_id` | GCP organization ID | `string` | — | yes |
| `finance_billing_account` | Billing account ID for Finance projects | `string` | `null` | no |
| `engineering_billing_account` | Billing account ID for Engineering projects | `string` | `null` | no |
| `default_billing_account` | Fallback billing account for projects with no explicit billing account | `string` | `null` | no |
| `finance_notification_email` | Alert notification email for Finance projects | `string` | `""` | no |
| `engineering_notification_email` | Alert notification email for Engineering projects | `string` | `""` | no |
| `test_suffix` | Short suffix appended to project IDs and folder names to avoid conflicts across test runs. Max 4 characters. | `string` | `""` | no |

## Outputs

| Name | Description |
|---|---|
| `folder_ids` | Map of folder key to numeric GCP folder ID |
| `project_ids` | Map of project key to GCP project ID |
| `project_numbers` | Map of project key to GCP project number |
| `enabled_services` | Map of `project_key/service` to service name |
| `alert_policy_ids` | Map of project key to list of monitoring alert policy resource names |
| `notification_channel_ids` | Map of project key to email notification channel resource name |

## Requirements

| Requirement | Version |
|---|---|
| Terraform | >= 1.3.0 |
| Google Provider | >= 7.23.0 |

### Required IAM Permissions

| Permission | Role |
|---|---|
| `resourcemanager.folders.create` | Organization Folder Admin |
| `resourcemanager.projects.create` | Project Creator |
| `billing.resourceAssociations.create` | Billing Account User on **each** billing account used |
| `serviceusage.services.enable` | Service Usage Admin |
| `monitoring.alertPolicies.create` | Monitoring AlertPolicy Editor |
| `monitoring.notificationChannels.create` | Monitoring NotificationChannel Editor |

> **Note:** The principal running Terraform must hold Billing Account User on every billing account referenced — not just the default.

## Notes

- **Secrets**: Never commit billing account IDs or email addresses to source control. Use `terraform.tfvars` (gitignored) or environment variables (`TF_VAR_finance_billing_account`) to supply them at runtime.
- **Partial threshold overrides**: Per-project `alert_thresholds` fields are individually optional. You can override only `cpu_utilization` and leave `error_rate` and `service_usage` to inherit the module-level `var.alert_thresholds` defaults.
- **No alerts on sandbox**: `eng-sandbox` sets `"enable_alerts": false` and omits `monitoring.googleapis.com` from its services — no monitoring resources are created for it.
- **Destruction**: All projects use `deletion_policy = "DELETE"` to allow `terraform destroy` to complete without manual intervention. For production, omit this field or set it to `"PREVENT"`.
