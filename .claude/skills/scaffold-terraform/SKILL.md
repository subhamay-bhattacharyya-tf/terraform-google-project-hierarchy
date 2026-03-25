---
name: scaffold-terraform
description: Generate Terraform Google Module for Project Hierarchy consisting of folders, projects, billing account association, API enablement, monitoring alerts with thresholds, and GitHub CI pipeline. Use when setting up a new project hierarchy module or regenerating infrastructure files.
disable-model-invocation: true
argument-hint: "[gcp-region] [project-name]"
user-invocable: true
---

Generate a complete **Terraform Google Module for Project Hierarchy** consisting of:

- Organization folders
- Nested folder hierarchy
- GCP projects
- Billing account association
- API/service enablement
- Monitoring alerts with configurable thresholds
- GitHub CI pipeline for validation, example validation, Terratest execution, changelog generation, and semantic release

Use `$ARGUMENTS` for optional overrides:

- `$0` = GCP region (default: `us-central1`)
- `$1` = Project name (default: `terraform-google-project-hierarchy`)

---

## What to Generate

Read `template-spec.md` in this skill folder for the full infrastructure specification.

Generate all Terraform module files in the repository root `/` directory following the template specification.

The generated structure should follow standard Terraform module layout:

```text
.
├── .github
│   └── workflows
│       └── ci.yml
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

- `google_project_billing_info` where applicable, or equivalent billing association logic supported by the Google provider

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

## GitHub CI Pipeline to Generate

Also generate a GitHub Actions workflow at:

```text
.github/workflows/ci.yml
```

The CI pipeline should be adapted for this **Google Cloud Terraform module**, based on the provided AWS example, and should include the following jobs.

### Workflow triggers

Trigger on:

- push to:
  - `main`
  - `feature/**`
  - `bug/**`
- pull request to `main`
- `workflow_dispatch`

Restrict paths so workflow runs only when Terraform/module-related files change.

### Workflow permissions

Use:

- `contents: read`
- `id-token: write`

Add broader permissions only where required for changelog or release jobs.

### Job 1: Terraform Validate

Validate the module directory.

Include steps for:

- checkout
- setup Terraform
- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`

Target the module root or module directories appropriate for this repository.

### Job 2: Validate Examples

Validate example configurations after module validation succeeds.

Include steps for:

- checkout
- setup Terraform
- `terraform init -backend=false`
- `terraform validate`

At minimum validate:

- `examples/basic`

### Job 3: Terratest

Run Go-based Terratest integration tests after example validation succeeds.

Adapt the AWS-based test workflow to GCP by:

- using Google Cloud authentication instead of AWS authentication
- using Workload Identity Federation or service account credentials, depending on repository design
- setting environment variables appropriate for GCP tests
- running the Terratest entry point for this project hierarchy module

Include steps for:

- checkout
- setup Terraform with `terraform_wrapper: false`
- setup Go
- authenticate to GCP
- download Go dependencies
- run Terratest
- capture test output
- append test output to `$GITHUB_STEP_SUMMARY`

Use test names and filenames appropriate for this repository, for example:

- `TestGoogleProjectHierarchy`
- `google_project_hierarchy_test.go`
- `helpers_test.go`

### Job 4: Generate Changelog

Generate changelog on non-main branches after validation succeeds.

Include steps for:

- checkout with full history
- run `git-cliff`
- write `CHANGELOG.md`
- commit updated changelog only if changed
- push the commit back to the branch

### Job 5: Semantic Release

Run semantic release only on `main` after validation and Terratest succeed.

Include steps for:

- checkout with full history
- setup Node.js
- run semantic release with changelog and git plugins
- use `GITHUB_TOKEN`

---

## CI Adaptation Requirements

When generating the CI workflow, adapt the provided AWS S3 example to **Google Cloud**.

### Replace AWS-specific behavior with GCP-specific behavior

Do not generate any AWS-specific content such as:

- `aws-actions/configure-aws-credentials`
- `AWS_REGION`
- `AWS_ROLE_ARN`

Instead, use Google Cloud equivalents such as:

- `google-github-actions/auth`
- `google-github-actions/setup-gcloud`

If using OIDC / Workload Identity Federation, support secrets or variables such as:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`

If using service account JSON credentials, use a secret such as:

- `GCP_CREDENTIALS`

Choose one authentication model consistently in the generated workflow.

### CI tool versions

Support repository or organization variables where appropriate, for example:

- `TERRAFORM_VERSION`
- `GO_VERSION`

Use sensible defaults if variables are not defined.

### Test summary output

Terratest steps must write human-readable results into the GitHub Step Summary.

### Release behavior

- changelog generation should happen only on non-main branches
- semantic release should happen only on `main`

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

## README

Generate a `README.md` with the following structure:

### Title

Use a descriptive title that reflects what the module does — **not** the repository name. Format:

```text
# Terraform Module for <short description of what it manages>
```

Example:

```text
# Terraform Module for GCP Folder and Project Hierarchy Management
```

### Badges

Add the following badge line immediately after the title, replacing `<repo-name>` with the actual repository name and `<cloud-badge>` with the appropriate cloud provider badge:

```markdown
![Release](https://github.com/subhamay-bhattacharyya-tf/<repo-name>/actions/workflows/ci.yaml/badge.svg)&nbsp;![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)&nbsp;![Commit Activity](https://img.shields.io/github/commit-activity/t/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Last Commit](https://img.shields.io/github/last-commit/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Release Date](https://img.shields.io/github/release-date/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Repo Size](https://img.shields.io/github/repo-size/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![File Count](https://img.shields.io/github/directory-file-count/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Issues](https://img.shields.io/github/issues/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Top Language](https://img.shields.io/github/languages/top/subhamay-bhattacharyya-tf/<repo-name>)&nbsp;![Custom Endpoint](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bsubhamay/d38e95a090be70513f16e3b1a3529d76/raw/<repo-name>.json?)&nbsp;![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-623CE4?logo=anthropic&logoColor=white)
```

The cloud badge should match the provider:

| Provider | Badge markdown |
| --- | --- |
| GCP | `![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)` |
| AWS | `![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazonaws&logoColor=white)` |

---

## After Generation

After scaffolding the infrastructure files:

- [ ] List all files created
- [ ] Show a summary of Terraform resources that will be provisioned
- [ ] Show the generated GitHub CI pipeline files
- [ ] Summarize the CI jobs included in the workflow
- [ ] Remind the engineer to review the generated files
- [ ] Recommend running `/tf-plan` to validate the Terraform configuration
```