# Azure SQL deployment target

Terraform configuration for a small, private-network Azure SQL Database target for the portfolio.

## Security choices

- TLS 1.2 minimum.
- Public network access disabled.
- Private endpoint plus private DNS.
- Generated globally unique names via a random suffix.
- Log Analytics workspace and database diagnostic settings.
- SQL administrator password is a sensitive input and is never stored in this repository.

## Validate without Azure credentials

From the repository root:

```powershell
./scripts/get-terraform.ps1
./scripts/validate-iac.ps1
```

## Plan/apply

Planning and applying require an authorized Azure subscription and credentials. Copy only non-secret values from `terraform.tfvars.example`; supply the password through `TF_VAR_sql_admin_password`.

This module intentionally has no default backend. Before a real team deployment, configure encrypted remote state with locking and least-privilege access.
