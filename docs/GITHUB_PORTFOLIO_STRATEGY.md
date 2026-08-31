# GitHub portfolio strategy

## Keep the repositories separate

`de-lab` is a learning system: curriculum, drills, challenges and interview preparation. Keep it public if useful, but do not use it as the main proof of completed delivery.

`mssql-data-engineering-portfolio` is a recruiter-facing evidence repository: bounded projects, runnable code, tests and runbooks. It should remain separate from the lab so reviewers do not need to distinguish exercises from completed artifacts.

The current `Data-Specialist-Portfolio` repository (last reviewed from its public main branch) is mostly a list of claimed projects plus two CV PDFs, without corresponding inspectable project artifacts. It weakens evidence compared with this repository. Recommended action after the new repo is published and verified: archive it or remove it from the profile’s Featured section; do not delete it until any useful documents are preserved.

## Recommended Featured order

1. `mssql-data-engineering-portfolio`
2. one strongest real analytics automation case with sanitized evidence
3. `de-lab` (learning discipline)
4. one deployed product/application project

Avoid featuring six unrelated identities at once. For SQL/data applications, a recruiter should understand the target direction within ten seconds.

## Profile adjustments after green CI

- Change the typing/header emphasis from broad “Strategist / Producer / Creator” to the current target: data analytics transitioning into SQL/data engineering.
- Add the new repository as the first Featured card.
- Keep `de-lab` labelled explicitly as learning/interview preparation.
- Remove skill icons that imply production hands-on depth not supported by a project (especially cloud/IaC) or add a working artifact first.
- Use one contact email consistently across CV, profile and application documents.

## Publish gate

Do not call the repository finished publicly until:

- SQL Server 2022 integration workflow is green;
- the Actions badge is added to the root README;
- one actual execution-plan optimization case has measured before/after evidence;
- GitHub topics are set: `sql-server`, `tsql`, `data-engineering`, `database-development`, `database-maintenance`, `portfolio`;
- the repository description clearly says “independent lab projects.”
