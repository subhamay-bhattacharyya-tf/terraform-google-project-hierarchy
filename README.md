# Terraform Module for GCP Folder and Project Hierarchy Management

![Release](https://github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy/actions/workflows/ci.yaml/badge.svg)&nbsp;![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/2943614c1b23ed2953571e8a7143a406/raw/terraform-google-project-hierarchy.json?)&nbsp;![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-623CE4?logo=anthropic&logoColor=white)

A Terraform module for creating and managing **Google Cloud Platform (GCP) folder and project hierarchies** using a JSON-driven configuration model.

## Overview

This module enables platform engineering teams to provision entire GCP organizational structures — including multi-level folder hierarchies, projects, billing associations, API enablement, and monitoring alerts — from a single structured JSON configuration file.

## Architecture

```
Organization
└── Shared (L0 folder)
    ├── Platform (L1 folder)
    │   └── github-cicd (project)
    └── Data (L1 folder)
        └── data-warehouse (project)
```

Resources provisioned:

| Resource | Description |
|---|---|
| `google_folder` | Multi-level folder hierarchy (up to 3 levels) |
| `google_project` | Projects placed within folders |
| `google_project_billing_info` | Billing account association |
| `google_project_service` | API/service enablement |
| `google_monitoring_notification_channel` | Email alert channel |
| `google_monitoring_alert_policy` | CPU, error rate, and service usage alerts |

## Requirements

| Requirement | Version |
|---|---|
| Terraform | >= 1.3.0 |
| Google Provider | >= 7.23.0 |

### Required IAM Permissions

The service account or user running Terraform must have:

- `resourcemanager.folders.create` (Organization Folder Admin)
- `resourcemanager.projects.create` (Project Creator)
- `billing.resourceAssociations.create` (Billing Account User)
- `serviceusage.services.enable` (Service Usage Admin)
- `monitoring.alertPolicies.create` (Monitoring AlertPolicy Editor)

## Usage

```hcl
module "gcp_project_hierarchy" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy"

  organization_id         = var.organization_id
  default_billing_account = var.billing_account
  notification_email      = "platform-alerts@example.com"

  alert_thresholds = {
    cpu_utilization = 0.8
    error_rate      = 0.05
    service_usage   = 100.0
  }

  hierarchy_config = jsondecode(file("${path.module}/hierarchy.json"))
}
```

## Example Hierarchy JSON

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
        "monitoring.googleapis.com"
      ],
      "labels": {
        "env": "shared",
        "team": "platform",
        "managed-by": "terraform"
      },
      "enable_alerts": true
    }
  },
  "monitoring_project_key": "github-cicd"
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `organization_id` | GCP organization ID | `string` | — | yes |
| `region` | Default GCP region | `string` | `"us-central1"` | no |
| `project_name` | Terraform project name | `string` | `"terraform-google-project-hierarchy"` | no |
| `default_billing_account` | Default billing account ID | `string` | `null` | no |
| `notification_email` | Email for alert notifications | `string` | `""` | no |
| `alert_thresholds` | Monitoring alert thresholds | `object` | `{}` | no |
| `hierarchy_config` | JSON-driven hierarchy configuration | `object` | — | yes |

### `alert_thresholds` Object

| Field | Description | Default |
|---|---|---|
| `cpu_utilization` | CPU utilization ratio (0.0–1.0) | `0.8` |
| `error_rate` | Error log entries per second | `0.05` |
| `service_usage` | API requests per second | `0.9` |

### `hierarchy_config` Object

| Field | Description |
|---|---|
| `folders` | Map of folder key to folder definition |
| `folders[].display_name` | Human-readable folder name |
| `folders[].parent_type` | `"organization"` or `"folder"` |
| `folders[].parent_key` | Key of the parent folder (when `parent_type = "folder"`) |
| `projects` | Map of project key to project definition |
| `projects[].name` | Project display name |
| `projects[].project_id` | Globally unique GCP project ID |
| `projects[].folder_key` | Key of the parent folder |
| `projects[].billing_account` | Per-project billing account override |
| `projects[].services` | List of GCP API URLs to enable |
| `projects[].labels` | Key-value labels to apply |
| `projects[].enable_alerts` | Create alert policies in this project |
| `monitoring_project_key` | Project key that hosts monitoring resources |

## Outputs

| Name | Description |
|---|---|
| `folder_ids` | Map of folder key to numeric GCP folder ID |
| `folder_names` | Map of folder key to `folders/<id>` resource name |
| `project_ids` | Map of project key to GCP project ID |
| `project_numbers` | Map of project key to GCP project number |
| `enabled_services` | Map of `project_key/service` to service name |
| `alert_policy_ids` | Resource names of created monitoring alert policies |
| `notification_channel_id` | Resource name of the email notification channel |

## Notes

- **Folder nesting**: Supports up to 3 levels of folder nesting under the organization. Level classification is based on `parent_type` and `parent_key` in the hierarchy_config.
- **Billing**: Billing is managed via `google_project_billing_info`, decoupled from project creation. Set `default_billing_account` or per-project `billing_account` in the config.
- **Monitoring**: Alert policies are created in the project identified by `monitoring_project_key`. The `monitoring.googleapis.com` API must be enabled on that project.
- **Service enablement**: APIs are enabled after billing association. `disable_on_destroy = false` prevents service disruption during Terraform destroy.

## License

Apache 2.0 — see [LICENSE](LICENSE).
