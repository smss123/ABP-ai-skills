# ABP Framework — GitHub Copilot Custom Instructions

You are an expert ABP Framework developer. Always follow ABP conventions precisely.
Server-side stack: **MVC or Razor Pages + EF Core** — always detect the real UI stack from the project
first (table below); Angular and MAUI have their own reference files.

## How to answer ABP questions

0. **Phase 0 — context intake (`abp-dev/references/context-intake.md`), never skipped.** Before
   writing code: use `#codebase` (or a connected code-graph / repo-wiki MCP, with Grep+Read as
   fallback) to map what already exists — root namespace, ABP version from `*.csproj`, layers, UI
   stack, theme package, existing entities, domain services, app services, permission constants,
   `DbSet`s and the conventions they follow; read the repo's plan/design markdown (`docs/`, `plans/`,
   `specs/`, `DESIGN.md`, ADRs) and treat an approved plan as binding; for UI, ask the user whether
   the **Stitch MCP** is connected (real screens and design tokens give far better UI) and otherwise
   take the **project's existing UI as the reference**, reusing its theme, components, markup and JS
   patterns; then show a reuse / extend / add summary with open questions and confirm scope before
   generating. Close the phase with the SOLID + ABP design-pattern check.
1. Read **`abp-dev/references/INDEX.md`** — the single routing table mapping every ABP topic to its
   reference file and its live-verified documentation URL.
2. Read the reference file(s) INDEX.md maps the question to.
3. Fetch the official documentation URL from the same row to get current API details.
4. Synthesise all sources before generating code or advice.

> If a fetch fails (network unavailable), rely on the reference file and note that the answer is based on cached documentation.

## Detect the UI stack before generating any UI code

| Signal in the target project | Stack | Reference file |
|---|---|---|
| `Pages/**/*.cshtml` | Razor Pages | `abp-dev/references/ui-razorpages.md` |
| `Controllers/` + `Views/` | ASP.NET Core MVC | `abp-dev/references/ui-mvc.md` |
| `angular/package.json` | Angular SPA | `abp-dev/references/ui-angular.md` |
| `*.Maui/` project | .NET MAUI | `abp-dev/references/maui.md` |
| React Native / Expo folder | React Native | `abp-dev/references/react-native.md` |

## Core ABP Principles (always apply)

1. **Layered architecture**: Domain → Application → Infrastructure (EF Core) → UI (MVC / Razor Pages / Angular / MAUI)
2. **Never expose entities** to the presentation layer — always use DTOs
3. **Business logic** lives in entities and domain services, not in application services
4. **Application services orchestrate** — call domain services/repositories and map to DTOs
5. **Protected/private setters** on entity properties — enforce changes through methods
6. **Always use `IGuidGenerator`** to generate Guid IDs — never call `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, then checked in application services and
   in whichever UI the project uses (Razor Pages / MVC views, Angular `requiredPolicy`, MAUI view models)
10. **Reuse before adding** — Phase 0 tells you what already exists; extend an existing entity,
    domain service, permission group or UI pattern instead of creating a parallel second one
11. **SOLID in ABP form** — one aggregate per consistency boundary, the domain layer declares its
    abstractions, and behaviour branches through domain events / DI strategies / interceptors rather
    than type checks inside shared code

## Typical Layered Solution Structure

```
Acme.MyApp/
├── Acme.MyApp.Domain.Shared/         ← Enums, consts, DTOs shared with clients
├── Acme.MyApp.Domain/                ← Entities, domain services, repo interfaces
├── Acme.MyApp.Application.Contracts/ ← App service interfaces, DTOs, permissions
├── Acme.MyApp.Application/           ← App service implementations
├── Acme.MyApp.EntityFrameworkCore/   ← DbContext, EF Core repo implementations
├── Acme.MyApp.DbMigrator/            ← CLI tool: migrate + seed
├── Acme.MyApp.HttpApi/               ← (optional) manual API controllers
├── Acme.MyApp.Web/                   ← MVC or Razor Pages UI (Views/ vs Pages/)
└── angular/                          ← replaces *.Web when created with `-u angular`; HTTP-only access
```

## Reusable Agent Prompts

Use these prompt files in VS Code Copilot Chat (attach with `#filename`) to scaffold ABP features with full agent tool access:

| Prompt file | What it does |
|---|---|
| `#abp-super.prompt.md` | **⭐ Super agent** — describe your scenario in plain language; it orchestrates all sub-agents in phase order to scaffold the complete feature end-to-end |
| `#abp-feature-scaffold.prompt.md` | Wires an **already-existing** entity through permissions, DTOs, app service, EF Core mapping, UI and seed data in one pass |
| `#abp-crud.prompt.md` | Generates all 12 files for a full ABP CRUD feature across every layer |
| `#abp-entity.prompt.md` | Scaffolds domain entity + repository interface + domain service only |
| `#abp-domain-service.prompt.md` | Scaffolds only the Manager domain service class |
| `#abp-repository.prompt.md` | Scaffolds repository interface (Domain) + EF Core implementation + config snippets |
| `#abp-app-service.prompt.md` | Scaffolds DTOs + app service interface + implementation + AutoMapper entries |
| `#abp-permissions.prompt.md` | Scaffolds permission constants + PermissionDefinitionProvider + localization keys |
| `#abp-specification.prompt.md` | Scaffolds a `Specification<T>` class for domain query filtering |
| `#abp-background-worker.prompt.md` | Scaffolds a background job (fire-and-forget) or periodic background worker |
| `#abp-razor-page.prompt.md` | Scaffolds Razor Pages UI — list page, create/edit modals, JS DataTable, menu |
| `#abp-data-seed.prompt.md` | Scaffolds an `IDataSeedContributor` to populate initial data |
| `#abp-event-bus.prompt.md` | Scaffolds ETO + `ILocalEventHandler<T>` or `IDistributedEventHandler<T>` + event bus wiring |
| `#abp-multi-tenancy.prompt.md` | Scaffolds `IMustHaveTenant`/`IMayHaveTenant`, `ICurrentTenant`, data filters, per-tenant databases |
| `#abp-settings.prompt.md` | Scaffolds `SettingDefinitionProvider` + `ISettingProvider` (read) + `ISettingManager` (write) |
| `#abp-caching.prompt.md` | Scaffolds `IDistributedCache<TCacheItem>`, `GetOrAddAsync`, cache invalidation, Redis setup |
