---
name: tf-apply
description: Run terraform apply to create or update Google Cloud infrastructure. Use after reviewing a terraform plan.
disable-model-invocation: true
user-invocable: true
---

Run `terraform apply -auto-approve -no-color` and verify the results.

After apply completes:

- [ ] Show the key outputs (created folder IDs/names, project IDs, project numbers, enabled services, alert policy IDs, notification channel ID)
- [ ] Verify that the expected folders and projects were created successfully
- [ ] Verify that required Google APIs were enabled for each project
- [ ] Verify that alerting resources were created when configured
- [ ] Report any errors and suggest fixes

Checks to perform after apply:

- Confirm `google_folder` resources were created in the expected hierarchy
- Confirm `google_project` resources were created under the correct folders
- Confirm billing association was applied where expected
- Confirm `google_project_service` resources completed successfully
- Confirm `google_monitoring_notification_channel` and `google_monitoring_alert_policy` resources exist when alerting is configured

If apply fails:

- [ ] Do NOT retry automatically
- [ ] Show the error clearly
- [ ] Identify the most likely root cause
- [ ] Suggest a concrete fix
- [ ] Wait for instructions before any further action