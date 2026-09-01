# GitHub portfolio strategy

## Keep the repositories separate

`de-lab` is a learning system: curriculum, drills, challenges and interview preparation. Keep it public if useful, but do not use it as the main proof of completed delivery.

`mssql-data-engineering-portfolio` is a recruiter-facing evidence repository: bounded projects, runnable code, tests and runbooks. It should remain separate from the lab so reviewers do not need to distinguish exercises from completed artifacts.

`Data-Specialist-Portfolio` is the recruiter-facing landing page. It links anonymized professional analytics cases to inspectable delivery repositories, while preserving a clear confidentiality boundary. Keep it featured alongside the technical proof repositories.

## Recommended Featured order

1. `Data-Specialist-Portfolio`
2. `mssql-data-engineering-portfolio`
3. `lakehouse-finance-data-engineering`
4. `de-lab` (learning discipline)
5. one deployed product/application project

Avoid featuring six unrelated identities at once. For SQL/data applications, a recruiter should understand the target direction within ten seconds.

## Profile adjustments after green CI

- Change the typing/header emphasis from broad “Strategist / Producer / Creator” to the current target: data analytics transitioning into SQL/data engineering.
- Add the new repository as the first Featured card.
- Keep `de-lab` labelled explicitly as learning/interview preparation.
- Qualify cloud/IaC precisely: Terraform is now implemented and validated; add a deployment badge/evidence only after a real controlled cloud run.
- Use one contact email consistently across CV, profile and application documents.

## Publish gate

Do not call the repository finished publicly until:

- SQL Server 2022 integration workflow is green;
- the Actions badge is added to the root README;
- one actual execution-plan optimization case has measured before/after evidence;
- GitHub topics are set: `sql-server`, `tsql`, `data-engineering`, `database-development`, `database-maintenance`, `portfolio`;
- the repository description clearly says “independent lab projects.”
