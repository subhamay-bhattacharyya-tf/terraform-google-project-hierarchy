## [unreleased]

### 🚀 Features

- Add GCP project hierarchy module with folder and project resources
- Enhance CI workflow and documentation for GCP project hierarchy module
- Update CI workflow to include changes in variable references and paths
- Update README structure, enhance CI workflow, and improve local folder logic
- Use try function to safely resolve monitoring project ID
- Add deletion_policy to projects and update hierarchy configuration for unique project IDs
- Enhance hierarchy configuration to include test_suffix for folder display names
- Implement billing account association via google_billing_project_info and update dependencies
- Enhance GCP Project Hierarchy Module with Multi-Billing and Alert Customization
- Add multi-billing test case to Terratest workflow
- Implement billing budget alerts and service accounts for GCP projects
- Add billing account to existing projects and create org_quotas.csv file

### 🐛 Bug Fixes

- Update notification channel and alert policy conditions to use monitoring_project_key
- Add deletion_protection to folder resources for consistency
- Ensure fallback for notification email in alert projects
- Update test command regex for Google Project Hierarchy tests
- Update alert thresholds and formatting in variables.tf
- Improve billing account handling in alerts and billing configurations
- Remove unnecessary whitespace in billing account checks
- Improve billing account handling using coalesce and try functions
- Add condition to run Terratest on main branch or workflow dispatch

### 🚜 Refactor

- Standardize formatting of project variables in hierarchy_config
- Remove billing account and notification email from hierarchy.json and update related documentation

### 📚 Documentation

- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]
- Update CHANGELOG.md [skip ci]

### 🎨 Styling

- Format alignment of project resource attributes for consistency

### 🧪 Testing

- Update alert policies to billing budgets in TestGoogleProjectHierarchyMultiBilling

### ⚙️ Miscellaneous Tasks

- Remove outdated S3 bucket example configurations and documentation
