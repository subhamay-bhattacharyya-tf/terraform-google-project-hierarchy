# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform module for creating and managing **Google Cloud Platform (GCP) folder and project hierarchies**.  
GitHub: [terraform-google-project-hierarchy](https://github.com/subhamay-bhattacharyya-tf/terraform-google-project-hierarchy)

This module enables **JSON-driven provisioning of GCP organizational structure**, including:

- Folder hierarchy under an organization
- Project creation under folders
- Billing account assignment
- Project labels
- Automatic API/service enablement

The module is designed for **platform engineering teams managing enterprise GCP organizations** using Infrastructure as Code.

### Requirements

- Terraform >= 1.3.0
- Google Provider >= 7.23.0

---

## Commands

### Terraform

```bash
# Format check (run from module directory)
terraform fmt -check -recursive

# Initialize without backend (for validation)
terraform init -backend=false

# Validate a module or example
terraform validate
```

### Running Tests

Tests are **Terratest-based (Go)** and require **GCP credentials** with sufficient permissions to create folders, projects, and enable APIs.

Typical permissions required:

- Organization Folder Admin
- Project Creator
- Billing Account User
- Service Usage Admin

```bash
# From test/ directory — run all tests
cd test && go mod tidy && go mod download

# Run a single test
go test -v -timeout 30m -run TestGoogleProjectHierarchy ./google_project_hierarchy_test.go ./helpers_test.go
```

Each test must be paired with `helpers_test.go`.

Tests run in **parallel**, create **real GCP resources**, and clean up resources via `defer terraform.Destroy`.

⚠️ Running tests may incur **cloud costs**.

### Pre-commit

```bash
pre-commit run --all-files
```

Hooks run:

- `terraform fmt`
- `terraform validate`
- `terraform_docs` (auto-updates README module docs)
- `terraform_tflint`
- `terraform_trivy`
- `terrascan`
- `checkov`

These checks ensure **security, compliance, and Terraform best practices**.

---

### Release

```bash
npm run release
```

Runs `semantic-release` on the `main` branch only. Automatically versions, generates changelog, and tags GitHub releases based on Conventional Commits.

## Architecture (Target Design)

### Module Design Pattern

The module follows a **JSON-driven configuration model**.

Instead of passing many individual Terraform variables, the module accepts a **single structured configuration object**:

```text
hierarchy_config
```

This object defines:

- folders
- nested folder relationships
- projects
- services to enable
- billing configuration
- labels

This approach simplifies module usage and allows **entire GCP hierarchy definitions to be stored in version-controlled JSON files**.

Example usage:

```hcl
module "gcp_project_hierarchy" {
  source = "../modules/project-hierarchy"

  organization_id         = var.organization_id
  default_billing_account = var.billing_account

  hierarchy_config = jsondecode(file("${path.module}/hierarchy.json"))
}
```

---

### Folder Hierarchy Management

Folders are created using:

```text
google_folder
```

Each folder definition includes:

- `display_name`
- `parent_type`
- `parent_key`

Supported parent types:

- `organization`
- `folder`

Example:

```json
{
  "shared": {
    "display_name": "Shared",
    "parent_type": "organization"
  },
  "platform": {
    "display_name": "Platform",
    "parent_type": "folder",
    "parent_key": "shared"
  }
}
```

The module resolves folder dependencies and provisions folders in the correct order.

### Infrastructure (`terraform/`)

- AWS S3 bucket for static site hosting (private, OAC-based access)
- CloudFront distribution as CDN with S3 origin
- GitHub OIDC provider + IAM role for keyless CI/CD auth
- Terraform state stored in S3 backend with DynamoDB locking
- All resources tagged with `Project` and `Environment`

### CI/CD (`.github/workflows/`)

- GitHub Actions workflow triggers on push to `main`
- Syncs site files to S3, then invalidates CloudFront cache
- Uses OIDC for AWS authentication (no long-lived keys)

## MCP Servers (`.mcp.json`)

Two MCP servers are configured for Claude Code:

- **gcp** (`gcplabs.gcp-api-mcp-server`) — Direct Google API access for querying and managing resources
- **terraform** (`hashicorp/terraform-mcp-server`) — Terraform operations via Docker, workspace mounted at `/workspace`

AWS credentials and region are configured in `.claude/settings.local.json` (gitignored), not in `.mcp.json`. This keeps secrets out of version control and provides a single source of truth for all tools.

## Custom Agents (`.claude/agents/`)

This project has 4 specialized subagents. Use them by name when delegating tasks:

- **tf-writer** — generates Terraform code (has Write access + project memory)
- **security-auditor** — audits TF for security issues (Read-only, Sonnet)
- **cost-optimizer** — reviews infra cost (Read-only, Haiku)
- **drift-detector** — detects state drift (Bash, Haiku)

## Skills (`.claude/skills/`)

All infrastructure and deployment tasks are handled via skills. Do not write Terraform or CI/CD code manually — use the appropriate skill. Action skills have `disable-model-invocation: true` (manual only). The `project-scope` skill has `user-invocable: false` (auto-loaded by Claude as background knowledge).

```text
/scaffold-terraform [region] [name]  → Generate all Terraform files (uses tf-writer agent)
/scaffold-cicd [aws-account-id]      → Generate GitHub Actions + OIDC IAM role
/tf-plan                             → Run terraform plan + risk analysis
/tf-apply                            → Run terraform apply + verify
/deploy                              → Sync S3 + invalidate CloudFront
/infra-status                        → Health dashboard of all resources
/infra-audit                         → Parallel security + cost + drift audit (forked context)
/setup-gh-actions [create|validate]  → Create or validate CI workflow
/tf-destroy                          → Safe destroy with confirmation
project-scope                        → Background knowledge: AWS service constraints (auto-loaded)
/commit                              → Auto-generate commit message (built-in)
/compact                             → Compress long conversation context (built-in)
```

---

### Project Provisioning

Projects are created using:

```text
google_project
```

Each project configuration supports:

- project name
- project ID
- parent folder
- billing account
- labels
- APIs to enable

Example project configuration:

```json
{
  "github-cicd": {
    "name": "GitHub CICD",
    "project_id": "prj-shared-github-cicd",
    "folder_key": "platform",
    "services": [
      "iam.googleapis.com",
      "cloudresourcemanager.googleapis.com"
    ]
  }
}
```

---

### API Enablement

Required APIs are enabled using:

```text
google_project_service
```

Services are defined per project and automatically enabled after project creation.

Example:

```text
bigquery.googleapis.com
storage.googleapis.com
iam.googleapis.com
```

The module dynamically iterates over service lists and enables them for each project.

---

### Billing Assignment

Projects can optionally specify a billing account.

If not specified, the module falls back to:

```text
default_billing_account
```

This allows centralized billing management while supporting per-project overrides.

---

### Labels and Metadata

Projects support optional labels for governance and cost allocation.

Example:

```json
"labels": {
  "env": "dev",
  "owner": "data"
}
```

Labels are applied during project creation.

---

## Repository Structure

```markdown
terraform-google-project-hierarchy
│
├── modules
│   └── project-hierarchy
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
│
├── examples
│   └── basic
│       ├── main.tf
│       └── hierarchy.json
│
├── test
│   ├── google_project_hierarchy_test.go
│   └── helpers_test.go
│
├── README.md
├── LICENSE
└── CLAUDE.md
```

Examples serve as **standalone Terraform root modules** used for CI validation.

---

## Conventions

### Commit Messages

Use **Conventional Commits** format:

```text
feat: add project service enablement
fix: correct folder dependency resolution
docs: update README usage example
chore: update provider versions
```

These commits are used by **semantic-release** for automated versioning.

---

### Branch Naming

Feature branches follow the format:

```text
TFMOD-<issue-number>-<short-description>
```

Example:

```text
TFMOD-12-project-service-enablement
```

Branches are typically created from GitHub issues.

---

### Terraform Style

Formatting rules:

- 2-space indentation
- LF line endings
- Maximum 80 characters per line (except Markdown)
- Explicit provider and version constraints
- Clear variable descriptions

All variables and outputs must be documented.

---

### TFLint Rules Enforced

The repository enforces strict Terraform linting rules:

- Typed variables
- Standard module structure
- Required provider declarations
- Pinned module sources
- Naming conventions
- Documented variables and outputs

Security scanners (`trivy`, `checkov`, `terrascan`) ensure infrastructure code follows **cloud security best practices**.

---

## Design Goals

This module aims to provide a **production-grade foundation** for managing GCP organizational structure using Terraform.

Key goals:

- JSON-driven configuration
- Enterprise-scale folder hierarchy management
- Automated project provisioning
- Governance through labels and validation
- Security and compliance scanning
- Compatibility with CI/CD pipelines

The module is intended to integrate with **platform engineering workflows, GitHub Actions pipelines, and Infrastructure-as-Code governance frameworks**.
