---
name: tf-plan
description: Run terraform plan and analyze the output for risks. Use before applying any infrastructure changes.
disable-model-invocation: true
user-invocable: true
---

Run `terraform plan -no-color` and analyze the output.

Summarize:

- [ ] How many resources will be added, changed, or destroyed
- [ ] Any potential issues or risks (for example: resource replacements, IAM changes, project deletion, API disablement, billing impact, or data loss)
- [ ] Estimated blast radius

If the plan fails:

- [ ] Diagnose the error
- [ ] Identify the most likely root cause
- [ ] Suggest a concrete fix
- [ ] Indicate whether the issue is related to provider configuration, authentication, missing variables, backend initialization, invalid resource dependencies, or Terraform syntax/configuration

When analyzing the plan, pay special attention to:

- `google_folder` changes that may affect hierarchy structure
- `google_project` replacements or deletions
- billing account changes
- `google_project_service` removals or disablement
- monitoring alert policy changes
- any destructive actions affecting existing GCP resources

Classify blast radius as one of:

- `Low` — isolated non-destructive changes
- `Medium` — multiple resource updates or limited destructive impact
- `High` — project/folder deletion, replacement, billing changes, or broad service disruption