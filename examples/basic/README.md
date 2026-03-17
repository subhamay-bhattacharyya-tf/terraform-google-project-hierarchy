# Example: Basic GCP Project Hierarchy

This example demonstrates a minimal JSON-driven GCP organizational hierarchy using the `terraform-google-project-hierarchy` module. It provisions two nested folders and two projects under a single shared parent folder, with a single default billing account applied to all projects.

Use this as a starting point when all projects share one billing account and you need a straightforward folder structure.

## Architecture

```
Organization
└── Shared (L0 folder)
    ├── Platform (L1 folder)
    │   └── github-cicd (project)
    └── Data (L1 folder)
        └── data-warehouse (project)
```

## Resources Provisioned

| Resource | Description |
|---|---|
| `google_folder` | `shared`, `platform`, `data` |
| `google_project` | `github-cicd`, `data-warehouse` |
| `google_billing_project_info` | Default billing account on both projects |
| `google_project_service` | IAM, CRM, BigQuery, Storage, Monitoring APIs |
| `google_billing_budget` | Billing budget alert on `github-cicd` |
| `google_service_account` | CI/CD service account on `github-cicd` (`SA-GitHub CICD`) |
| `google_monitoring_notification_channel` | Email notification channel (when `notification_email` is set) |

## Usage

### 1. Copy or reference the example

```hcl
module "gcp_project_hierarchy" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy//examples/basic"

  organization_id    = "123456789012"
  billing_account    = "ABCDEF-123456-GHIJKL"
  notification_email = "platform-alerts@example.com"
}
```

Or run directly as a root module:

```bash
git clone https://github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy.git
cd terraform-google-project-hierarchy/examples/basic
```

### 2. Configure variables

Create a `terraform.tfvars` file:

```hcl
organization_id    = "123456789012"
billing_account    = "ABCDEF-123456-GHIJKL"
notification_email = "platform-alerts@example.com"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Customising the Hierarchy

Edit `hierarchy.json` to add folders and projects. The module resolves parent references automatically — no ordering is required.

```json
{
  "folders": {
    "shared": {
      "display_name": "Shared",
      "parent_type": "organization"
    },
    "platform": {
      "display_name": "Platform",
      "parent_type": "folder",
      "parent_key": "shared"
    },
    "data": {
      "display_name": "Data",
      "parent_type": "folder",
      "parent_key": "shared"
    }
  },
  "projects": {
    "github-cicd": {
      "name": "GitHub CICD",
      "project_id": "prj-shared-github-cicd",
      "folder_key": "platform",
      "services": [
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "serviceusage.googleapis.com",
        "monitoring.googleapis.com"
      ],
      "labels": {
        "env": "shared",
        "team": "platform",
        "managed-by": "terraform"
      },
      "enable_alerts": true
    },
    "data-warehouse": {
      "name": "Data Warehouse",
      "project_id": "prj-shared-data-warehouse",
      "folder_key": "data",
      "services": [
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "cloudresourcemanager.googleapis.com"
      ],
      "labels": {
        "env": "shared",
        "team": "data",
        "managed-by": "terraform"
      },
      "enable_alerts": false
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `organization_id` | GCP organization ID | `string` | — | yes |
| `billing_account` | Default billing account ID for all projects | `string` | `null` | no |
| `notification_email` | Email address for monitoring alert notifications | `string` | `""` | no |
| `test_suffix` | Short suffix appended to project IDs and folder names to avoid conflicts across test runs. Max 4 characters. | `string` | `""` | no |

## Outputs

| Name | Description |
|---|---|
| `folder_ids` | Map of folder key to numeric GCP folder ID |
| `project_ids` | Map of project key to GCP project ID |
| `project_numbers` | Map of project key to GCP project number |
| `enabled_services` | Map of `project_key/service` to service name |
| `billing_budget_ids` | Map of project key to billing budget resource name |
| `service_account_emails` | Map of project key to CI/CD service account email |

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
| `billing.resourceAssociations.create` | Billing Account User |
| `serviceusage.services.enable` | Service Usage Admin |
| `billing.budgets.create` | Billing Budget Admin |
| `iam.serviceAccounts.create` | Service Account Admin |

## Notes

- **Billing**: Both projects inherit `billing_account` from the module-level `default_billing_account`. To override per project, add a `"billing_account"` field to the project entry in `hierarchy.json`. See the [multi-billing example](../multi-billing/) for a full demonstration.
- **Service accounts**: Set `"enable_service_account": true` on a project to create a service account named `SA-<project name>` (account ID `sa-<project-key>`). Intended for GitHub CI/CD pipelines.
- **Billing budgets**: A billing budget is created for each project with `"enable_alerts": true` and a billing account assigned. Threshold rules are configurable per project via `alert_thresholds.threshold_rules` in the JSON config; if omitted, they default to 25%, 50%, 100% actual spend + 100% forecasted. GCP notifies billing account IAM members automatically; set `notification_email` to also route alerts to a specific address.
- **Project IDs**: GCP project IDs are globally unique and cannot be reused after deletion for 30 days. The `test_suffix` variable is used by automated tests to avoid conflicts across runs.
- **Destruction**: Both projects use `deletion_policy = "DELETE"` so `terraform destroy` can remove them without manual intervention. For production use, omit this field or set it to `"PREVENT"`.
