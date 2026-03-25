# Terraform Template Specification

Generate these files in the `/` directory:

**main.tf:**

- Google folder resources to create folder hierarchy under an organization
- Google project resources to create projects under specific folders
- Project billing association using project-level billing account or default billing account
- Google project service resources to enable required APIs for each project
- Monitoring notification channel resource for alerts
- Monitoring alert policy resources with configurable threshold-based conditions
- Support JSON-driven hierarchy configuration loaded through a single structured input object
- Support project labels and metadata
- Ensure resource dependencies are handled correctly so folders are created before child folders and projects
- All supported resources should use common labels/tags where applicable through input variables

**variables.tf:**

- Variables for:
  - `organization_id`
  - `region` (default `"us-central1"`)
  - `project_name` (default `"terraform-google-project-hierarchy"`)
  - `default_billing_account` (default `null`)
  - `notification_email` (default `""`)
  - `alert_thresholds` as an object/map for configurable monitoring thresholds
  - `hierarchy_config` as a structured object representing folders, projects, services, billing, labels, and alerts
  - The module must support a **JSON-driven configuration model** where a single object defines:
  - folders
- parent relationships
- projects
- billing configuration
- enabled APIs
- labels
- monitoring alerts

Example configuration:

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

**outputs.tf:**

- Outputs for:
  - created folder IDs / names by key
  - created project IDs by key
  - created project numbers by key
  - enabled services by project
  - monitoring alert policy IDs
  - notification channel ID

**versions.tf:**

- Terraform block with:
  - required_version `>= 1.3.0`
  - required Google provider source `hashicorp/google`
  - version `>= 7.23.0`
- Google provider configuration using:
  - region variable where applicable
  - optional project context if needed for monitoring resources

**README.md:**

- Overview of the module
- Architecture summary
- Requirements
- Input variable documentation
- Output documentation
- Example usage with `jsondecode(file(...))`
- Example hierarchy JSON structure
- Notes about permissions required to create folders, projects, billing associations, services, and alerts

**examples/basic/main.tf:**

- Example root module invoking the child module from `../../`
- Example values for:
  - organization_id
  - default_billing_account
  - notification_email
  - hierarchy_config loaded from `hierarchy.json`

**examples/basic/hierarchy.json:**

- Example JSON configuration containing:
  - shared folder under organization
  - platform and data child folders
  - one or more sample projects
  - API/service lists
  - labels
  - optional alert settings

**test/google_project_hierarchy_test.go:**

- Terratest entry point for validating the example deployment
- Test should:
  - init and apply the example
  - validate key outputs
  - destroy resources with deferred cleanup

**test/helpers_test.go:**

- Shared Terratest helper functions for:
  - randomized naming
  - retry helpers
  - output assertions
  - cleanup helpers
  