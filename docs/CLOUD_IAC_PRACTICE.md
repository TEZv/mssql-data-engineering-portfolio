# Cloud/IaC practice without local administrator rights

## Why this extension is logical

The three SQL projects remain the database-development evidence. `infra/azure-sql` is the delivery layer for the same portfolio: it provisions a secure Azure SQL target where the database code can later be deployed. It demonstrates how a local database build becomes a repeatable cloud environment.

```text
T-SQL projects -> GitHub CI -> Terraform -> private Azure SQL Database
                                  |
                                  +-> Log Analytics diagnostics
                                  +-> controlled apply / evidence / destroy
```

## Three levels of evidence

1. **Implemented:** readable Terraform, security choices, variables, outputs and runbook.
2. **Validated:** `terraform fmt`, `init -backend=false`, and `validate` pass locally/CI.
3. **Deployed:** a real `plan`, `apply`, smoke test and `destroy` are captured with redacted logs and cost evidence.

Only use the word “deployed” after level 3. The repository can reach level 2 without Azure credentials and without administrator access.

## No-admin local validation

`scripts/get-terraform.ps1` downloads the official Terraform ZIP into `.tools/terraform`; it does not write to Program Files, edit PATH, install a Windows service, or require elevation.

```powershell
./scripts/get-terraform.ps1
./scripts/validate-iac.ps1
```

GitHub Actions provides a second clean environment and runs the same format/init/validate gate.

## Browser-only real deployment

Use Azure Cloud Shell from the Azure portal when an Azure subscription is available. Cloud Shell is browser-accessible, authenticated to the current account, and managed by Microsoft. No installation on the work laptop is required.

Practice sequence:

1. Create a dedicated dev subscription/resource group scope and a strict budget alert.
2. Clone this repository in Cloud Shell.
3. Set sensitive variables as environment variables; never commit a password or `.tfstate`.
4. Run `terraform plan -out portfolio.tfplan` and review every resource.
5. Apply, run a minimal connectivity/schema smoke test, and capture redacted evidence.
6. Run `terraform destroy` the same session and confirm that the resource group is empty.

## Evidence to add after the first deployment

- Redacted plan summary with resource count and date.
- Azure portal screenshot showing SQL database, private endpoint and diagnostics.
- CI run link.
- Smoke-test output without credentials, subscription IDs or server FQDN if it is sensitive.
- Destroy confirmation and actual cost screenshot.
- A short incident note: one failure encountered, root cause, fix and prevention.

## Cost and security guardrails

- Never apply from a corporate subscription without explicit authorization.
- Use a personal learning subscription and set a spending budget before applying.
- The sample database uses a small serverless SKU and auto-pause, but it is not guaranteed to be free.
- Public network access is disabled; connectivity is expected through the private endpoint or an explicitly designed runner path.
- Terraform state contains sensitive values. For a real deployment, use an encrypted remote backend with restricted access.
