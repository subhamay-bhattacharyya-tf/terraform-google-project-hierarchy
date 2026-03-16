---
name: deploy
description: Verify GCP infrastructure deployment and validate created projects, services, and alerts. Use after terraform apply to confirm infrastructure is operational.
disable-model-invocation: true
user-invocable: true
---

Verify the deployed Google Cloud infrastructure created by Terraform.

Steps:

- [ ] Get Terraform outputs  
  `terraform output -json`

- [ ] List created projects  
  `gcloud projects list`

- [ ] Verify required services/APIs are enabled for each project  
  `gcloud services list --enabled --project <project-id>`

- [ ] Verify monitoring notification channels  
  `gcloud monitoring channels list --project <project-id>`

- [ ] Verify monitoring alert policies  
  `gcloud monitoring policies list --project <project-id>`

- [ ] Report the following:
  - Created folder hierarchy
  - Created project IDs
  - Enabled APIs per project
  - Alert policies and notification channels

If any step fails:

- Stop immediately
- Show the error
- Explain the most likely cause
- Suggest a fix

Do **not** continue to the next step after a failure.