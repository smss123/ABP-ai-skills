---
name: abp-dev
description: >
  Expert guide for developing applications with the ABP Framework (abp.io) using ASP.NET Core,
  DDD patterns, and MVC / Razor Pages / Angular / Blazor / .NET MAUI / React Native UI. Use this skill
  whenever the user mentions ABP, abp.io,
  Volo.Abp, AbpModule, application services, aggregate roots, domain services, ABP CLI, 
  IRepository, PermissionDefinitionProvider, IDataSeedContributor, Auto API Controllers,
  AbpDbContext, or any ABP-specific concept. Also trigger for questions about layered ABP project
  structure, startup templates, or ABP module dependencies. Always consult this skill before
  generating any ABP-related code, architecture advice, or explaining ABP concepts — even for
  seemingly simple questions like "how do I create an entity in ABP". Every task starts with
  Phase 0 context intake: inspect the existing code through a knowledge graph, read the repo's
  plan/design markdown, settle the UI source of truth (Stitch MCP if connected, otherwise the
  project's existing UI as the reference), confirm scope with the user, then apply ABP standards,
  SOLID and design patterns.
  source: "https://docs.abp.io/en/abp/latest/"
---
# Author:"Samer Abdallah"
# company:"Xprema Systems"
# release_date:"2024-06-30"
# ABP Framework Development Skill

## Supported AI Coding Platforms

This skill works across all major AI coding assistants. Use the configuration file for your tool:

| Platform | Instructions file | Agent / workflow files |
|---|---|---|
| **GitHub Copilot** | `abp-dev/SKILL.md` (this file) + `.github/copilot-instructions.md` | `.github/prompts/` — 22 reusable agent prompts (see table below) |
| **Claude Code** | `CLAUDE.md` | `.claude/commands/` — 22 slash commands (see table below) |
| **Windsurf** | `.windsurfrules` | `.windsurf/workflows/` — 22 Cascade workflows (see table below) |
| **Continue.dev** | `.continue/config.yaml` (`systemMessage`) | `.continue/config.yaml` (`agents:` block) — 22 specialized agents |

> The four platforms expose the **same 22 capabilities**; `scripts/verify-skill.sh` fails CI if one
> platform gains an agent the others do not have, or if a documented count drifts from what is on disk.

> **Routing table:** every topic → reference file → documentation URL mapping lives in
> **`abp-dev/references/INDEX.md`** (one place, so the platform files cannot drift apart).

## Automatic activation — no prompt needs attaching

This skill switches itself on. Treat the workspace as an ABP project when **any** signal is present:
`Volo.Abp*` package references · `AbpModule` subclasses or `[DependsOn(typeof(…))]` · `AbpDbContext`,
`AggregateRoot`, `FullAuditedEntity`, `IRepository<,>`, `AbpController`, `AbpPageModel` · `appsettings`
with `"Abp"`, `"AuthServer"` or `"RemoteServices"` · projects ending in `.Domain.Shared`,
`.Application.Contracts`, `.HttpApi`, `.DbMigrator`, `.EntityFrameworkCore` · `abp.json` / `.abp/` /
ABP Studio `etc/`.

On detection, announce it in one line — `ABP project detected (signal: …) — running Phase 0 before
writing code` — then apply this skill to the **entire task**, including bug fixes, refactors and
"simple" questions, not only scaffolding. If nothing matches, do not inject ABP patterns into the
project. The authoritative signal list and its edge cases are in
`references/context-intake.md` §0.0.

Which file carries the auto-activation rule per platform:

| Platform | Auto-loaded entry point |
|---|---|
| Copilot, Codex, Cursor, Zed, Qoder, Amp, Jules (open standard) | `AGENTS.md` at the project root |
| GitHub Copilot chat | `.github/copilot-instructions.md` + path-scoped `.github/instructions/abp.instructions.md` (`applyTo` globs for `*.cs`, `*.csproj`, `*.cshtml`, `*.razor`, `appsettings*.json`) |
| Claude Code | `CLAUDE.md` (every session) and this `SKILL.md` description |
| Windsurf | `.windsurfrules` (always on) |
| Continue.dev | `.continue/config.yaml` `systemMessage` + `rules:` with a file-path `pattern` |

## 🚀 Super Agent — Start here for full-feature scaffolding

The **`abp-super`** agent is the top-level orchestrator. Give it a plain-language description of your feature and it will:

1. Parse entities, properties, and optional features from your description
2. Show you a confirmed analysis table
3. Present a phase-by-phase execution plan with file counts
4. Execute each sub-agent in the correct layer order:

```
Phase 0 → Context intake  (codebase graph of existing code → plan/design .md files →
                           UI source of truth: Stitch MCP if connected, else the project's
                           existing UI as reference → confirm scope with the user → SOLID check)
Phase 1 → Domain layer     (entity, domain service, repository interface)
Phase 2 → App.Contracts    (permissions, DTOs, app service interface)
Phase 3 → Application      (app service impl, AutoMapper, specification, background worker, domain events)
Phase 4 → EF Core          (EfCore repository, DbSet, model config, module registration)
Phase 5 → Database         (migration commands)
Phase 6 → UI               (the stack detected above: Razor Pages / MVC / Blazor render the UI,
                            Angular / Blazor WASM / MAUI / React Native consume the HTTP API through
                            generated proxies instead — UI is optional in every phase)
Phase 7 → Seed data        (IDataSeedContributor — optional)
```

> For cross-cutting concerns, use the dedicated agents: **`abp-multi-tenancy`** (tenant isolation), **`abp-settings`** (setting definitions + read/write), **`abp-caching`** (distributed cache + Redis).

**How to invoke:**

| Platform | Command |
|---|---|
| GitHub Copilot | Attach `#abp-super.prompt.md` in Copilot Chat and describe your scenario |
| Claude Code | `/project:abp-super Build a product catalog with category filter, nightly archiver, and Razor Pages UI` |
| Windsurf | `run workflow abp-super` in Cascade |
| Continue.dev | Select **"ABP Super Agent"** from the agent picker |

---

## Agent Capabilities

Each platform also exposes focused single-responsibility agents for targeted scaffolding.  
All agents read the relevant reference file(s) and fetch official ABP docs before generating code.

| Agent / Command / Workflow | Copilot (`#`) | Claude (`/project:`) | Windsurf (`run workflow`) | What it does |
|---|---|---|---|---|
| **⭐ abp-super** | `#abp-super.prompt.md` | `/project:abp-super` | `abp-super` | **Orchestrator** — parses scenario, runs all sub-agents in phase order, produces complete feature |
| **abp-crud** | `#abp-crud.prompt.md` | `/project:abp-crud` | `abp-crud` | Full CRUD — entity + domain service + repository + DTOs + app service + EF Core + optional Razor Pages (12 files) |
| **abp-entity** | `#abp-entity.prompt.md` | `/project:abp-entity` | `abp-entity` | Domain entity class + repository interface + domain service (domain layer only) |
| **abp-domain-service** | `#abp-domain-service.prompt.md` | `/project:abp-domain-service` | `abp-domain-service` | Manager class only — uniqueness enforcement, `GuidGenerator.Create()` |
| **abp-repository** | `#abp-repository.prompt.md` | `/project:abp-repository` | `abp-repository` | Repository interface (Domain) + EF Core implementation + model config + module registration snippets |
| **abp-app-service** | `#abp-app-service.prompt.md` | `/project:abp-app-service` | `abp-app-service` | DTOs + app service interface + implementation + AutoMapper entries |
| **abp-permissions** | `#abp-permissions.prompt.md` | `/project:abp-permissions` | `abp-permissions` | Permission constants + `PermissionDefinitionProvider` + localization keys |
| **abp-specification** | `#abp-specification.prompt.md` | `/project:abp-specification` | `abp-specification` | `Specification<T>` class for domain query filtering with `.And()/.Or()/.Not()` combinators |
| **abp-background-worker** | `#abp-background-worker.prompt.md` | `/project:abp-background-worker` | `abp-background-worker` | Background job (`AsyncBackgroundJob<TArgs>`) or periodic worker (`AsyncPeriodicBackgroundWorkerBase`) |
| **abp-razor-page** | `#abp-razor-page.prompt.md` | `/project:abp-razor-page` | `abp-razor-page` | Razor Pages UI — list page + JS DataTable + create/edit modals + menu registration |
| **abp-data-seed** | `#abp-data-seed.prompt.md` | `/project:abp-data-seed` | `abp-data-seed` | `IDataSeedContributor` with idempotent guard, `IGuidGenerator`, `autoSave: true` |
| **abp-event-bus** | `#abp-event-bus.prompt.md` | `/project:abp-event-bus` | `abp-event-bus` | ETO class + `ILocalEventHandler<T>` or `IDistributedEventHandler<T>` + event bus wiring |
| **abp-multi-tenancy** | `#abp-multi-tenancy.prompt.md` | `/project:abp-multi-tenancy` | `abp-multi-tenancy` | `IMustHaveTenant`/`IMayHaveTenant` on entities, `ICurrentTenant`, data filters, per-tenant databases |
| **abp-settings** | `#abp-settings.prompt.md` | `/project:abp-settings` | `abp-settings` | `SettingDefinitionProvider` + `ISettingProvider` (read) + `ISettingManager` (write) |
| **abp-caching** | `#abp-caching.prompt.md` | `/project:abp-caching` | `abp-caching` | `IDistributedCache<TCacheItem>`, `GetOrAddAsync`, cache invalidation, Redis setup |
| **abp-feature-scaffold** | `#abp-feature-scaffold.prompt.md` | `/project:abp-feature-scaffold` | `abp-feature-scaffold` | Wires an **existing** entity through permissions → DTOs → app service → EF Core → UI → seed data |
| **abp-theming** | `#abp-theming.prompt.md` | `/project:abp-theming` | `abp-theming` | Custom theme / layout for the server-side UIs (MVC & Razor Pages): layout pages, branding, bundles |
| **abp-mvc-page** | `#abp-mvc-page.prompt.md` | `/project:abp-mvc-page` | `abp-mvc-page` | ASP.NET Core MVC UI — `AbpController` + views + JS DataTable + modal + toolbar/menu registration |
| **abp-angular-feature** | `#abp-angular-feature.prompt.md` | `/project:abp-angular-feature` | `abp-angular-feature` | Angular SPA feature — `abp generate-proxy -t ng`, service proxy, template-driven component, route + nav |
| **abp-test-runner** | `#abp-test-runner.prompt.md` | `/project:abp-test-runner` | `abp-test-runner` | Picks the right test fixture per layer, writes xUnit tests, runs `dotnet test`, reports failures |
| **abp-developer** | `#abp-developer.prompt.md` | `/project:abp-developer` | `abp-developer` | General ABP engineer for anything that is not a scaffold — bug fixes, refactors, reviews (runs Phase 0 first) |
| **abp-install** | `#abp-install.prompt.md` | `/project:abp-install` | `abp-install` | Installs this skill set into a target ABP project directory for the chosen platform(s) |

You are an expert ABP Framework developer. Always follow ABP conventions precisely.
Supports **all ABP UI stacks** — MVC, Razor Pages, Angular, Blazor, .NET MAUI, React Native — plus EF Core
data access. Detect which one the target project uses before generating UI code (table below).

## How to use this skill

**Phase 0 always comes first.** Never generate ABP code into a repository you have not inspected:

0. **Run the Phase 0 context intake** — `references/context-intake.md`. In order:
   a. read the **existing code through a knowledge graph** (repo wiki / codebase graph MCP / workspace
      search; Glob+Grep as fallback) and build the map: root namespace, ABP version, layers, UI stack,
      theme, existing entities/services/permissions/DbSets and the conventions they use;
   b. read any **plan or design `.md`** in the repo (`docs/`, `plans/`, `specs/`, `DESIGN.md`, ADRs) —
      an approved plan overrides your own preference, and you flag any divergence instead of silently
      changing course;
   c. for UI work, establish the **design source of truth**: ask the user to connect **Stitch MCP** for
      real screens and tokens, otherwise take the **project's existing UI as the reference** and reuse
      its theme, components, markup and JS patterns — never introduce a new visual language;
   d. **chat with the user**: show the reuse / extend / add summary plus open questions, and confirm
      scope (backend only? UI? migration?) before executing;
   e. check the design against **SOLID and the ABP-native patterns** (repository, specification,
      aggregate/domain service, DTO+mapper, domain events, strategy, interceptor) documented in the
      same file.

Only then continue with steps 1–4 below, in order, for every ABP-related question:

1. **Read `references/INDEX.md`** — the single routing table that maps every ABP topic to its
   reference file and to a live-verified documentation URL. It covers every file in `references/`;
   do not
   work from a remembered subset, and do not re-create a topic table inside another file.
2. **Read the local reference file(s)** named by that row — they contain curated, correct patterns.
3. **Fetch the official documentation page** listed in the same row using `web_fetch` (or a browser
   tool) to get the latest API details, version-specific notes, or anything the reference file may
   not cover.
4. Synthesise both sources before generating code or advice.

> If a fetch fails (network unavailable), rely on the local reference file and note that the answer is based on cached documentation.

## Detect the UI stack first

| Signal in the target project | Stack | Reference file |
|---|---|---|
| `Pages/**/*.cshtml` | Razor Pages | `references/ui-razorpages.md` |
| `Controllers/` + `Views/` | ASP.NET Core MVC | `references/ui-mvc.md` |
| `angular/package.json` | Angular SPA | `references/ui-angular.md` |
| `**/*.razor` + `Microsoft.AspNetCore.Components*` packages | Blazor (WASM / Server / WebApp) | `references/ui-blazor.md` |
| `*.Maui/` project | .NET MAUI | `references/maui.md` |
| React Native / Expo folder | React Native | `references/react-native.md` |

Rules that follow from the stack:

- **MVC vs Razor Pages** share the tag-helper, JavaScript-API, navigation, theming and bundling
  infrastructure — but not the page class (`AbpController` vs `AbpPageModel`) or the folder layout.
  Never mix conventions inside one screen, and never assume `Pages/` exists in an MVC solution.
- **Angular** never emits C# page code: it consumes the HTTP API through generated proxies
  (`abp generate-proxy -t ng`) and contributes navigation through route `data.route`. Hand-written
  `HttpClient` calls, `@addTagHelper` lines, or `abp.ModalManager` JS in an Angular project are bugs.
- **MAUI** uses C# client proxies + OIDC; check the project's declared `TargetFramework` (`net10.0-*`
  on ABP 10.x) before emitting `dotnet build -t:Run -f ...` commands.
- **Blazor** is C# components, not `.cshtml` pages: WASM / Hybrid apps consume the HTTP API through
  `abp generate-proxy -t csharp` (Blazor Server may inject the application service directly), and theme
  through `AbpThemingOptions` + bundles (`BlazorWebAssemblyStandardBundles`); tag helpers and
  `abp.ModalManager` JS do not belong in it.
- Server-side UIs need `abp install-libs`; the generated theme assets in `wwwroot/libs` are the usual
  cause of a blank page when it is skipped.

For questions touching multiple areas (e.g. "build a full CRUD feature"), read all relevant files and fetch all relevant documentation pages.

## Core ABP Principles (always apply)

1. **Layered architecture**: Domain → Application → Infrastructure (EF Core) → UI (MVC / Razor Pages / Angular / Blazor / MAUI)
2. **Never expose entities to the presentation layer** — always use DTOs
3. **Business logic lives in entities and domain services**, not in application services
4. **Application services orchestrate** — they call domain services / repositories, map to DTOs
5. **Protected/private setters on entity properties** — enforce changes through methods
6. **Always use `IGuidGenerator`** to generate Guid IDs, never `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, checked in application services and in
   whichever UI the project uses (Razor Pages / MVC views, Angular `requiredPolicy`, Blazor `AbpAuthorizeView`, MAUI view models)
10. **Reuse before adding** — Phase 0 tells you what already exists; extend an existing entity,
    domain service, permission group or UI pattern instead of creating a parallel second one
11. **SOLID in ABP form** — one aggregate per consistency boundary, depend on abstractions declared
    in the domain layer, branch behaviour with domain events / DI strategies / interceptors rather
    than `if (type == …)` inside shared code (see `references/context-intake.md`)

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
├── Acme.MyApp.Blazor/                ← replaces *.Web with `-u blazor` / `-u blazor-webapp`;
│                                         `-u blazor` (WebAssembly) adds a *.Blazor.Client project
└── angular/                          ← replaces *.Web when created with `-u angular`; has its own
                                         package.json, and the API is reached over HTTP only
```
