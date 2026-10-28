---
name: abp-super
description: Super agent — parse a plain-language scenario and orchestrate all ABP sub-workflows to scaffold the complete feature end-to-end
---

# ABP Super Agent

A Windsurf Cascade orchestration workflow that takes a plain-language user scenario and automatically runs the right ABP sub-workflows in the correct layer order.

---

## Step 0 — Collect the scenario

Ask the user the following questions before proceeding:

1. **Scenario description** — what does the feature do? (e.g. "Manage products with categories, archive zero-stock items nightly, and show them in a Razor Page")
2. **Entities** — list each entity name and its properties (name : type : required/optional)
3. **Audit level** — FullAudit / Audit / None for each entity
4. **UI stack?** — Razor Pages / MVC / Angular / MAUI / none (detect from the project: `Pages/` vs `Views/`+`Controllers/` vs `angular/package.json` vs `*.Maui/`)
5. **Background job or worker?** — Yes / No. If yes: fire-and-forget job or periodic worker? What does it do?
6. **Specification(s)?** — Yes / No. If yes: what are the filter criteria?
7. **Domain Events?** — Yes / No. If yes: Local or Distributed? What event(s) should be raised and handled?
8. **Data seed?** — Yes / No. If yes: what seed records?

---

## Step 1 — Context intake, then read reference files

**Phase 0 first** (full procedure: `abp-dev/references/context-intake.md`):

1. **Existing code through a knowledge graph** — use `@Codebase` / a connected repo-wiki or code-graph
   MCP (Grep+Read as fallback) to record root namespace, ABP version from `*.csproj`, layers, UI
   stack, theme package, and every existing entity, domain service, app service, DTO, permission
   constant and `DbSet`, plus the conventions those files use. If nothing is indexed, say so instead
   of assuming symbols exist.
2. **Plan and design docs** — `README.md`, `DESIGN.md`, `docs/**`, `plans/**`, `specs/**`,
   `openspec/**`, ADRs. An approved plan overrides your preference; flag deviations and ask.
3. **UI source of truth** (if UI is in scope) — ask the user whether the **Stitch MCP** is connected;
   Stitch gives real screens and design tokens. Otherwise take the **existing UI as the reference**
   and reuse its theme, components, markup and JS patterns. Never add a CSS framework, palette, font
   or component library the project does not already use.
4. **Confirm before generating** — present a reuse / extend / add summary with open questions and ask
   which phases are wanted (backend only vs UI + seed + migration).
5. **SOLID / pattern check** — aggregate boundary plus repository / specification / domain events /
   strategy-via-DI / interceptor choices, in one line.

Then read ALL of the following before generating any code:
- `abp-dev/references/context-intake.md`
- `abp-dev/references/INDEX.md` ← the routing table for every other reference file
- `abp-dev/references/ddd-domain.md`
- `abp-dev/references/ddd-application.md`
- `abp-dev/references/efcore.md`
- `abp-dev/references/authorization.md`
- `abp-dev/references/background-jobs.md`
- `abp-dev/references/event-bus.md`
- the UI reference matching the stack detected in question 4:
  `ui-razorpages.md` · `ui-mvc.md` · `ui-angular.md` · `maui.md`

Never emit Razor files into an Angular/MAUI solution or Angular components into a `*.Web` project.

---

## Step 2 — Present analysis and confirm

Show the user a parsed summary:

| # | Item | Extracted value |
|---|---|---|
| Entities | PascalCase names | ... |
| Properties | per entity | ... |
| Audit level | per entity | ... |
| UI stack? | | Razor Pages / MVC / Angular / MAUI / none |
| Background task? | type + purpose | ... |
| Specification(s)? | criteria | ... |
| Data seed? | records | ... |

Ask: **"Is this correct? Shall I proceed with the full scaffold?"**

---

## Step 3 — Show the execution plan

Present a full checklist of files to be created. Wait for confirmation before executing.

Example:
```
Phase 1 — Domain
  - [ ] Product.cs
  - [ ] IProductRepository.cs
  - [ ] ProductManager.cs

Phase 2 — Application.Contracts
  - [ ] BookStorePermissions (Products block)
  - [ ] ProductDto.cs
  - [ ] CreateUpdateProductDto.cs
  - [ ] GetProductsInput.cs
  - [ ] IProductAppService.cs

Phase 3 — Application
  - [ ] ProductAppService.cs
  - [ ] AutoMapper entries
  - [ ] AffordableProductSpecification.cs  (if applicable)
  - [ ] ZeroStockArchiveWorker.cs  (if applicable)

Phase 4 — EF Core
  - [ ] EfCoreProductRepository.cs
  - [ ] DbContext snippets (DbSet + model config + module registration)

Phase 5 — Database
  - [ ] EF Core migration commands

Phase 6 — UI  (if requested)
  - [ ] Index.cshtml + Index.cshtml.cs
  - [ ] Index.js
  - [ ] CreateModal.cshtml + .cs
  - [ ] EditModal.cshtml + .cs
  - [ ] Menu contributor snippet

Phase 7 — Seed data  (if requested)
  - [ ] ProductDataSeedContributor.cs
```

---

## Step 4 — Execute Phase 1: Domain layer

For each entity, run the logic of:
- **workflow: `abp-domain-service`** → `<Entity>Manager.cs`
- **workflow: `abp-repository`** → `I<Entity>Repository.cs` + `EfCore<Entity>Repository.cs`
- Entity class follows the pattern in `abp-dev/references/ddd-domain.md`

Key rules:
- Extend correct audit base class
- Private setters, protected ORM constructor, primary constructor, business methods
- `GuidGenerator.Create()` in Manager — never `Guid.NewGuid()`
- Uniqueness enforcement in `CreateAsync` via `FindByNameAsync`

---

## Step 5 — Execute Phase 2: Application.Contracts layer

Run the logic of:
- **workflow: `abp-permissions`** → constants + definition provider + `en.json` keys
- **workflow: `abp-app-service`** → DTOs + interface

---

## Step 6 — Execute Phase 3: Application layer

Run the logic of:
- **workflow: `abp-app-service`** → implementation + AutoMapper entries
- **workflow: `abp-specification`** (if applicable)
- **workflow: `abp-background-worker`** (if applicable)
- **workflow: `abp-event-bus`** (if applicable — for domain events)

---

## Step 7 — Execute Phase 4: EF Core / Infrastructure

Run the logic of:
- **workflow: `abp-repository`** → EfCore repository implementation + DbSet + model config + module registration

---

## Step 8 — Migration reminder

```bash
dotnet ef migrations add "Added_<Feature>_Entities" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet run --project src/Acme.BookStore.DbMigrator
```

---

## Step 9 — Execute Phase 6: UI (if requested; stack from question 4)

- **Razor Pages** → run workflow `abp-razor-page` for each entity (`abp-dev/references/ui-razorpages.md`).
- **MVC** → controller + `Views/<Entity>s/` view + `Index.js` + menu contributor, per
  `abp-dev/references/ui-mvc.md`. Tag helpers require all `@addTagHelper` lines in `_ViewImports.cshtml`.
- **Angular** → `abp generate-proxy -t ng`, standalone component + route with `requiredPolicy`,
  menu via `data.route`, per `abp-dev/references/ui-angular.md`. No C# page files.
- **MAUI** → ViewModel + C# client proxy + OIDC/`appsettings.json` check, per
  `abp-dev/references/maui.md` (use the TFM the project declares).

---

## Step 10 — Execute Phase 7: Seed data (if requested)

Run the logic of **workflow: `abp-data-seed`** for each entity.

---

## Step 11 — Print summary

Output:
- Total files generated
- Layer-by-layer file list
- Next steps: migration, AutoMapper verification, permission management UI check
