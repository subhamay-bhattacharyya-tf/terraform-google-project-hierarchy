---
name: scaffold-terraform
description: Generate Terraform Google Module for Project Hierarchy consisting of folders, projects, billing account association, API enablement, and alerting thresholds. Use when setting up a new project hierarchy module or regenerating infrastructure files.
disable-model-invocation: true
argument-hint: "[gcp-region] [project-name]"
---

Generate a complete **Terraform Google Module for Project Hierarchy** consisting of:

- Organization folders
- Nested folder hierarchy
- GCP projects
- Billing account association
- API/service enablement
- Monitoring alerts with configurable thresholds

Use `$ARGUMENTS` for optional overrides:

- `$0` = GCP region (default: `us-central1`)
- `$1` = Project name (default: `terraform-google-project-hierarchy`)

---

## What to Generate

Read `template-spec.md` in this skill folder for the full infrastructure specification.

Generate all Terraform module files in the repository root `/` directory following the template specification.

The generated structure should follow standard Terraform module layout:

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── locals.tf
├── folders.tf
├── projects.tf
├── services.tf
├── billing.tf
├── alerts.tf
├── README.md
├── examples
│   └── basic
│       ├── main.tf
│       └── hierarchy.json
└── test
    ├── google_project_hierarchy_test.go
    └── helpers_test.go
```

### Resources that should be generated

**Folder hierarchy**

- `google_folder`

**Project provisioning**

- `google_project`

**Billing configuration**

- `google_project_billing_info`

**API enablement**

- `google_project_service`

**Monitoring and alerting**

- `google_monitoring_alert_policy`
- `google_monitoring_notification_channel`

Alert policies should support configurable thresholds such as:

- budget alerts
- CPU utilization
- service usage thresholds
- error rate monitoring

---

## Configuration Model

The module should support a **JSON-driven configuration model** where a single input object defines:

- folders
- parent relationships
- projects
- billing configuration
- enabled APIs
- labels
- monitoring alerts

Example hierarchy configuration:

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
        "serviceusage.googleapis.com"
      ],
      "labels": {
        "env": "shared"
      }
    }
  }
}
```

---

## After Generation

After scaffolding the infrastructure files:

- [ ] List all files created
- [ ] Show a summary of Terraform resources that will be provisioned
- [ ] Remind the engineer to review the generated files
- [ ] Recommend running `/tf-plan` to validate the Terraform configuration