# ABP AI Skills

> **AI coding skills for the [ABP Framework](https://abp.io) — works with GitHub Copilot, Claude Code, Windsurf, and Continue.dev.**

A collection of curated AI agent prompts, slash commands, and workflow definitions that give your AI coding assistant deep, accurate knowledge of ABP Framework patterns. Drop this repository (or copy its config files) into any ABP project and your AI will scaffold production-ready, convention-correct code across every layer.

**Author:** Samer Abdallah · **Company:** Xprema Systems

---

## Table of Contents

- [What's included](#whats-included)
- [Quick start](#quick-start)
- [⭐ Super Agent — scaffold a full feature in one prompt](#-super-agent--scaffold-a-full-feature-in-one-prompt)
- [🔧 Feature Scaffold — wire up an existing entity in one pass](#-feature-scaffold--wire-up-an-existing-entity-in-one-pass)
- [All agents at a glance](#all-agents-at-a-glance)
- [Platform setup](#platform-setup)
  - [GitHub Copilot](#github-copilot)
  - [Claude Code](#claude-code)
  - [Windsurf](#windsurf)
  - [Continue.dev](#continuedev)
- [Repository structure](#repository-structure)
- [Keeping the skill honest](#keeping-the-skill-honest)
- [Reference files](#reference-files)
- [Core ABP principles enforced by every agent](#core-abp-principles-enforced-by-every-agent)
- [Typical ABP solution structure](#typical-abp-solution-structure)
- [License](#license)

---

## What's included

| What | Where | Purpose |
|---|---|---|
| **Automatic activation** | `AGENTS.md`, `.github/instructions/abp.instructions.md`, `.windsurfrules`, `CLAUDE.md`, `.continue/config.yaml` | The skill turns itself on when it detects an ABP project (`Volo.Abp*` refs, `AbpModule`, `AbpDbContext`, ABP project layout) — no prompt to attach, and it applies to bug fixes and refactors too |
| **Super agent** | platform-specific (see below) | Orchestrates all sub-agents from a plain-language scenario |
| **Scaffold agents** | 22 capabilities, identical on all four platforms (Copilot prompts · Claude commands · Windsurf workflows · Continue agents) | One agent per ABP layer / concern: super agent, feature scaffold, CRUD, MVC / Razor Pages / Angular UI, theming, testing, install |
| **Phase 0 — context intake** | `abp-dev/references/context-intake.md` | Before any code: existing-code knowledge graph → repo plan/design `.md` files → UI source of truth (Stitch MCP if connected, otherwise your existing UI as the reference) → confirm scope with you → SOLID & design-pattern check |
| **Reference files** | `abp-dev/references/` | Curated, correct ABP patterns for every topic |
| **`references/INDEX.md`** | `abp-dev/references/INDEX.md` | The single routing table (topic → reference → live doc URL). All platform instruction files point here, so no reference can become unreachable |
| **UI stack coverage** | `ui-razorpages.md`, `ui-mvc.md`, `ui-angular.md`, `ui-blazor.md`, `maui.md`, `react-native.md`, `theming.md` | Agents detect the project's UI (MVC / Razor Pages / Angular / Blazor / MAUI) before generating UI code |
| **Platform instructions** | `.github/copilot-instructions.md`, `CLAUDE.md`, `.windsurfrules`, `.continue/config.yaml`, `AGENT.md` | Injects ABP expertise into the AI assistant |
| **Self-verification** | `scripts/verify-skill.sh` + `.github/workflows/verify-skill.yml` | `make verify` checks routing, four-platform parity, Phase 0 coverage, documented counts, ABP anti-patterns in samples and per-file doc freshness — in CI on every push |

---

## Quick start

### Option A — one-liner (no clone needed)

**macOS / Linux / WSL:**
```bash
curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh \
  | bash -s -- /path/to/your-abp-project
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.ps1 | iex
# You will be prompted for the target directory
```

### Option B — from a cloned repo

```bash
git clone https://github.com/smss123/ABP-ai-skills.git
cd ABP-ai-skills
./install.sh /path/to/your-abp-project          # macOS/Linux
.\install.ps1 C:\path\to\your-abp-project       # Windows
```

### Install flags

| Flag | Values | Default | Effect |
|---|---|---|---|
| `--platform` / `-Platform` | `all` `copilot` `claude` `windsurf` `continue` | `all` | Install only for one AI tool |
| `--overwrite` / `-Overwrite` | — | false | Replace existing files without prompting |

```bash
# Claude Code only
./install.sh /path/to/project --platform claude

# Copilot only, overwrite existing
./install.sh /path/to/project --platform copilot --overwrite
```

**2. Open your project in your AI coding assistant.**

**3. Describe your feature — the Super Agent will do the rest:**

| Platform | What to type |
|---|---|
| GitHub Copilot | Attach `#abp-super.prompt.md` → type your scenario |
| Claude Code | `/project:abp-super Build a product catalog with Razor Pages UI` |
| Windsurf Cascade | `run workflow abp-super` |
| Continue.dev | Select **ABP Super Agent** from the agent picker |

---

## ⭐ Super Agent — scaffold a full feature in one prompt

The `abp-super` agent is the top-level orchestrator. Give it a plain-language description of what you want to build and it will:

1. **Run Phase 0 — context intake** before writing a single line: read the existing code through a
   codebase knowledge graph, read the repo's plan/design `.md` files, settle the UI source of truth
   (connect the **Stitch MCP** for real screens and tokens if you have it — otherwise your existing
   UI becomes the reference), then confirm with you what is reused, extended and newly added
2. **Parse** entities, properties, and optional features (background jobs, specs, UI, seeding) from your description
3. **Show** a confirmed analysis table — no code is written until you approve
4. **Present** a full file-by-file execution plan grouped by layer
5. **Execute** each sub-agent in the correct dependency order:

```
Phase 0 → Context intake     existing-code graph · plan docs · UI reference (Stitch or your pages) · SOLID check
Phase 1 → Domain layer       entity class · domain service (Manager) · repository interface
Phase 2 → App.Contracts      permission constants · DTOs · app service interface
Phase 3 → Application        app service implementation · AutoMapper · specification · background worker
Phase 4 → EF Core            EfCoreRepository · DbSet · model config · module registration
Phase 5 → Database           EF Core migration commands
Phase 6 → UI (optional)      Razor Pages list + create/edit modals + JS DataTable + menu
Phase 7 → Seed (optional)    IDataSeedContributor with idempotent guard
```

6. **Print** a summary: total files generated, layer breakdown, next-steps checklist

### Example prompt

> *"I want to manage Products. Each Product has a Name (required, max 128 chars), a decimal Price, and an IsActive flag. I need Razor Pages UI and some seed data with 3 sample products."*

The Super Agent first runs Phase 0 (it reads your existing code, your plan documents and your current
UI, then confirms scope with you), then scaffolds ~15 files across the remaining phases.

---

## 🔧 Feature Scaffold — wire up an existing entity in one pass

The `abp-feature-scaffold` agent is the fastest way to add all application-layer best practices to an entity that already exists in the domain layer. It reads the entity file first, extracts real properties and constants, then generates every artifact in the correct order:

| Step | Artifact | Layer |
|---|---|---|
| 1 | Read entity → extract properties, base class, Consts, business methods | — |
| 2 | `BookStoreDomainErrorCodes` typed error codes (`<Module>:000N`) | Domain.Shared |
| 3 | `en.json` localization keys — menu, permissions, error messages | Domain.Shared |
| 4 | `BookStorePermissions` + `PermissionDefinitionProvider` | Application.Contracts |
| 5 | `<Entity>Dto`, `CreateUpdate<Entity>Dto`, `Get<Entity>sInput` | Application.Contracts |
| 6 | `CreateUpdate<Entity>DtoValidator` (FluentValidation with async uniqueness) | Application |
| 7 | `I<Entity>AppService` interface | Application.Contracts |
| 8 | `<Entity>AppService` — `[Authorize]`, `EntityNotFoundException` auto-throw, `BusinessException` from Manager | Application |
| 9 | AutoMapper profile entries + optional Razor Pages UI prompt | Application / Web |

**Key enforcement rules baked in:**

- `IRepository.GetAsync` auto-throws `EntityNotFoundException` → HTTP 404 — no manual null-check
- `<Entity>Manager.CreateAsync` throws `BusinessException` with error code on duplicate — no re-check in app service
- `[StringLength]` always references `<Entity>Consts.MaxXxxLength` — never magic numbers
- Business methods only (`SetName()`) — never direct property assignment

Use this when you've already run `abp-entity` and now need to wire up everything above the domain layer.

---

## All agents at a glance

Every capability below ships on **all four platforms** — a Copilot prompt, a Claude command, a Windsurf
workflow and a Continue.dev agent. `scripts/verify-skill.sh` fails the build if one platform gains or
loses a capability, so this table cannot go stale.

| Agent | Copilot | Claude Code | Windsurf | What it generates |
|---|---|---|---|---|
| ⭐ **abp-super** | `#abp-super.prompt.md` | `/project:abp-super` | `abp-super` | **Full feature end-to-end** — orchestrates all sub-agents in phase order |
| 🧑‍💻 **abp-developer** | `#abp-developer.prompt.md` | `/project:abp-developer` | `abp-developer` | General ABP work — Phase 0, then the layers the request actually touches (bug fixes, refactors, "add X") |
| 🔧 **abp-feature-scaffold** | `#abp-feature-scaffold.prompt.md` | `/project:abp-feature-scaffold` | `abp-feature-scaffold` | **Application layer for an existing entity** — error codes · localization · FluentValidation · permissions · app service · AutoMapper · optional Razor Pages UI (domain layer untouched) |
| **abp-crud** | `#abp-crud.prompt.md` | `/project:abp-crud` | `abp-crud` | All 12 CRUD files: entity · domain service · repo · DTOs · app service · EF Core · optional Razor Pages |
| **abp-entity** | `#abp-entity.prompt.md` | `/project:abp-entity` | `abp-entity` | Domain entity class + repository interface + domain service (domain layer only) |
| **abp-domain-service** | `#abp-domain-service.prompt.md` | `/project:abp-domain-service` | `abp-domain-service` | `<Entity>Manager` — uniqueness enforcement, `GuidGenerator.Create()` |
| **abp-repository** | `#abp-repository.prompt.md` | `/project:abp-repository` | `abp-repository` | `I<Entity>Repository` + `EfCore<Entity>Repository` + DbSet/config/module snippets |
| **abp-app-service** | `#abp-app-service.prompt.md` | `/project:abp-app-service` | `abp-app-service` | DTOs + `I<Entity>AppService` + `<Entity>AppService` + AutoMapper entries |
| **abp-permissions** | `#abp-permissions.prompt.md` | `/project:abp-permissions` | `abp-permissions` | Permission constants + `PermissionDefinitionProvider` + `en.json` localization keys |
| **abp-specification** | `#abp-specification.prompt.md` | `/project:abp-specification` | `abp-specification` | `Specification<T>` with `.And()/.Or()/.Not()` combinators |
| **abp-background-worker** | `#abp-background-worker.prompt.md` | `/project:abp-background-worker` | `abp-background-worker` | `AsyncBackgroundJob<TArgs>` (fire-and-forget) or `AsyncPeriodicBackgroundWorkerBase` (periodic) |
| **abp-razor-page** | `#abp-razor-page.prompt.md` | `/project:abp-razor-page` | `abp-razor-page` | Server-side UI: list page · JS DataTable · create/edit modals · menu registration. Detects the stack first — Razor Pages (`Pages/`) or MVC (`Views/` + `Controllers/`); Angular/MAUI projects are routed to `ui-angular.md` / `maui.md` instead of getting C# page files |
| **abp-data-seed** | `#abp-data-seed.prompt.md` | `/project:abp-data-seed` | `abp-data-seed` | `IDataSeedContributor` — idempotent guard, `IGuidGenerator`, `autoSave: true` |
| **abp-event-bus** | `#abp-event-bus.prompt.md` | `/project:abp-event-bus` | `abp-event-bus` | ETO class + `ILocalEventHandler<T>` or `IDistributedEventHandler<T>` + event bus wiring |
| **abp-multi-tenancy** | `#abp-multi-tenancy.prompt.md` | `/project:abp-multi-tenancy` | `abp-multi-tenancy` | `IMustHaveTenant`/`IMayHaveTenant`, `ICurrentTenant`, data filters, per-tenant databases |
| **abp-settings** | `#abp-settings.prompt.md` | `/project:abp-settings` | `abp-settings` | `SettingDefinitionProvider` + `ISettingProvider` (read) + `ISettingManager` (write) |
| **abp-caching** | `#abp-caching.prompt.md` | `/project:abp-caching` | `abp-caching` | `IDistributedCache<TCacheItem>`, `GetOrAddAsync`, cache invalidation, Redis setup |
| **abp-mvc-page** | `#abp-mvc-page.prompt.md` | `/project:abp-mvc-page` | `abp-mvc-page` | MVC UI: controller · views · JS DataTable · toolbar contributor · menu entry (`references/ui-mvc.md`) |
| **abp-angular-feature** | `#abp-angular-feature.prompt.md` | `/project:abp-angular-feature` | `abp-angular-feature` | Angular feature: `abp generate-proxy -t ng` · list component · modal form · route + nav with `requiredPolicy` · localization (`references/ui-angular.md`) |
| **abp-theming** | `#abp-theming.prompt.md` | `/project:abp-theming` | `abp-theming` | Custom theme / layout for the server-side UIs: layout pages, branding, bundles (`references/theming.md`) |
| **abp-test-runner** | `#abp-test-runner.prompt.md` | `/project:abp-test-runner` | `abp-test-runner` | Tests at the right layer — xunit unit tests, `ApplicationTestBase` integration tests, Shouldly + NSubstitute — then runs `dotnet test` and reports (`references/testing-troubleshooting.md`) |
| **abp-install** | `#abp-install.prompt.md` | `/project:abp-install` | `abp-install` | Installs these skills into another ABP project: checks what exists, backs up hand-written rule files, runs `install.sh` / `install.ps1` |

> **Continue.dev** users: all agents are available via the agent picker (including the Super Agent at the top of the list).

---

## Platform setup

### GitHub Copilot

The `.github/copilot-instructions.md` file is automatically picked up by VS Code Copilot Chat. No extra configuration needed once the files are in your project.

**Invoke agents** by attaching the prompt file in Copilot Chat:

```
# In Copilot Chat (VS Code):
@workspace #abp-super.prompt.md Build a product catalog with category filter and Razor Pages UI
```

All prompt files live in `.github/prompts/`. Every prompt is set to `mode: 'agent'` so Copilot can read files, create files, and run commands autonomously.

---

### Claude Code

`CLAUDE.md` at the project root is automatically loaded by Claude Code in every session.

**Invoke agents** with slash commands:

```bash
# Full feature from a scenario:
/project:abp-super Build a blog module with Posts, Tags, Razor Pages UI, and sample seed data

# Individual layers:
/project:abp-entity Post
/project:abp-permissions Posts
/project:abp-razor-page Post
/project:abp-data-seed Post
```

All commands are in `.claude/commands/`. The `$ARGUMENTS` placeholder receives everything you type after the command name.

---

### Windsurf

`.windsurfrules` is automatically loaded by Windsurf as global rules for the workspace.

**Invoke workflows** in Cascade:

```
run workflow abp-super
run workflow abp-crud
run workflow abp-razor-page
```

All workflows are in `.windsurf/workflows/`. Each workflow follows the same multi-step pattern: read reference files → confirm with user → generate files.

---

### Continue.dev

`.continue/config.yaml` configures the system message, docs indexing, and agents.

**Use the agent picker** in the Continue sidebar to select:
- **ABP Super Agent** — full-feature orchestrator
- **ABP CRUD Scaffolder**, **ABP Entity + Domain**, **ABP App Service**, etc.

The config also indexes the official ABP documentation (`docs.abp.io`) so you can query it with `@ABP Framework` in chat.

---

## Repository structure

```
ABP-ai-skills/
│
├── AGENTS.md                             ← Auto-activation rules (loaded by Copilot/Codex/Cursor/Zed/Qoder)
├── abp-dev/
│   ├── SKILL.md                        ← Master skill definition (all platforms)
│   └── references/
│       ├── INDEX.md                               ← Routing table: topic → file → verified doc URL (single source)
│       ├── context-intake.md                      ← Phase 0: existing-code graph, plan docs, UI source of truth, SOLID/patterns
│       ├── ddd-domain.md                          ← Entities, AggregateRoot, Domain Services, Repositories
│       ├── ddd-application.md                     ← Application Services, DTOs, CRUD patterns
│       ├── efcore.md                              ← EF Core DbContext, migrations, multi-DBMS switching
│       ├── authorization.md                       ← Permissions, [Authorize], PermissionDefinitionProvider, Audit Logging
│       ├── api.md                                 ← Auto API Controllers, Versioning, Integration Services, Static/Dynamic Proxies
│       ├── ui-razorpages.md                       ← Razor Pages, page models, tag helpers, JS API
│       ├── ui-mvc.md                              ← ASP.NET Core MVC UI, AbpController, _ViewImports, bundling
│       ├── ui-angular.md                          ← Angular SPA: generate-proxy, environment.ts, guards, theming
│       ├── maui.md                                ← .NET MAUI mobile UI (ABP 10 / .NET 10 TFMs, OIDC, adb reverse)
│       ├── cli-structure.md                       ← ABP CLI, startup templates, solution structure
│       ├── background-jobs.md                     ← Background jobs and periodic workers
│       ├── event-bus.md                           ← Local domain events & Distributed Event Bus
│       ├── multi-tenancy.md                       ← IMustHaveTenant, ICurrentTenant, data isolation
│       ├── settings.md                            ← SettingDefinitionProvider, ISettingProvider, ISettingManager
│       ├── caching.md                             ← IDistributedCache<T>, GetOrAddAsync, Entity Cache, Redis setup
│       ├── modules.md                             ← Module system, DependsOn, ConfigureServices, Virtual File Explorer
│       ├── testing-troubleshooting.md             ← Unit/integration testing, common pitfalls
│       ├── localization.md                        ← en.json structure, L[] helper, IStringLocalizer, localization API
│       ├── features.md                            ← IFeatureChecker, FeatureDefinitionProvider, IFeatureManager
│       ├── concurrency-check.md                   ← IHasEntityVersion, optimistic concurrency
│       ├── connection-strings.md                  ← Connection string config, multi-DB, per-tenant DBs
│       ├── data-filtering.md                      ← IDataFilter, ISoftDelete, IMultiTenant, custom filters
│       ├── deployment.md                          ← Production config, SSL, OpenIddict certificates
│       ├── global-features.md                     ← GlobalFeatureManager, [RequiresGlobalFeature]
│       ├── image-manipulation.md                  ← IImageCompressor, IImageResizer, ImageSharp/Magick/SkiaSharp
│       ├── interceptors.md                        ← AbpInterceptor, OnRegistered, DynamicProxy
│       ├── json.md                                ← IJsonSerializer, System.Text.Json vs Newtonsoft
│       ├── object-extensions.md                   ← ObjectExtensionManager, Module Entity Extensions
│       ├── options.md                             ← Options pattern, Configure<T>, PreConfigure
│       ├── signalr.md                             ← SignalR real-time communication
│       ├── string-encryption.md                   ← IStringEncryptionService, AbpStringEncryptionOptions
│       ├── text-templating.md                     ← Scriban & Razor engines, ITemplateRenderer, email templates
│       ├── theming.md                             ← UI Theming, layout system, theme customization
│       ├── timing.md                              ← IClock, DateTimeKind, timezone, AbpClockOptions
│       ├── correlation-id.md                      ← ICorrelationIdProvider, AbpCorrelationIdOptions, propagation
│       ├── cms-kit.md                             ← CMS Kit module: blogs, pages, comments, reactions, tags
│       ├── openiddict.md                          ← OpenIddict module: OAuth endpoints, token lifetimes, claims
│       ├── database-tables.md                     ← Module DB table prefixes, connection string names
│       ├── ui-blazor.md                           ← Blazor WASM/Server/WebApp: components, theming, proxies
│       ├── microservices.md                       ← Microservice solution: apps/gateways/services, YARP, RabbitMQ
│       ├── blob-storing.md                        ← IBlobContainer, providers, encryption, pipelines
│       ├── audit-logging.md                       ← AuditLog/EntityChange, AbpAuditingOptions, security logs
│       ├── openapi-swagger.md                     ← Volo.Abp.Swashbuckle, AddAbpSwaggerGen, OIDC document
│       ├── background-workers.md                  ← AsyncPeriodicBackgroundWorkerBase, dynamic/cron workers
│       ├── production-hardening.md                ← Production checklist: prefixes, keys, headers, secrets
│       ├── react-native.md                        ← React Native / Expo mobile UI
│       └── migration-identityserver-openiddict.md ← IdentityServer4 → OpenIddict migration guide
│
├── .github/
│   ├── copilot-instructions.md         ← Copilot global instructions (auto-loaded)
│   ├── instructions/
│   │   └── abp.instructions.md         ← path-scoped ABP rules (`applyTo` globs: .cs/.csproj/.cshtml/…)
│   ├── prompts/                        ← one file per capability (see "All agents at a glance")
│   │   └── abp-*.prompt.md                abp-super, abp-developer, abp-crud, abp-entity, …
│   └── workflows/
│       └── verify-skill.yml            ← CI for the skill itself; never copied into a target project
│
├── .claude/
│   └── commands/                       ← the same capabilities as /project:abp-* commands
│
├── .windsurf/
│   └── workflows/                      ← the same capabilities as Cascade workflows
│
├── .continue/
│   └── config.yaml                     ← System message + docs index + all agents (`# id:` per agent)
│
├── scripts/
│   └── verify-skill.sh                 ← Self-verification harness (`make verify`, `make links`)
│
├── install.sh / install.ps1            ← Installers for macOS·Linux / Windows
├── Makefile                            ← make install · make verify · make links
├── AGENT.md                            ← Machine-readable install guide for AI agents
├── .windsurfrules                      ← Windsurf global rules (auto-loaded)
├── CLAUDE.md                           ← Claude Code global instructions (auto-loaded)
├── LICENSE
└── README.md                           ← This file
```

---

## Keeping the skill honest

This repository verifies itself. `make verify` runs `scripts/verify-skill.sh`, and the same script runs
in CI (`.github/workflows/verify-skill.yml`) on every push and pull request:

| Check | What fails the build |
|---|---|
| Routing | `INDEX.md` names a reference file that does not exist · a file exists that `INDEX.md` never routes to |
| Parity | one platform exposes a capability the others do not (all four must carry the same set) |
| Phase 0 | an always-loaded entry point stops referencing `context-intake.md` or stops delegating detection to §0.0 |
| Counts | a documented capability count disagrees with what is on disk; a hardcoded reference-file count appears at all |
| ABP rules | a code sample recommends `Guid.NewGuid()` or `throw new Exception` instead of `GuidGenerator.Create()` / `BusinessException` |
| Installers | `install.sh` / `install.ps1` fail to parse, or copy a path that does not exist |
| Freshness | a reference file loses its `applies_to_abp` / `doc_verified_on` frontmatter, or declares a date while its URLs were never checked |

A separate CI job installs the skill into a synthetic ABP project and asserts the resulting tree —
including that the skill's own `.github/workflows/` is **never** copied into someone's repository.
Documentation liveness (`make links`) runs weekly rather than on every push, so a transient abp.io
outage cannot block a merge.

---

## Reference files

Every agent runs **Phase 0** (`references/context-intake.md`) before generating code, then reads
`references/INDEX.md` — it maps each topic to its reference file and to a documentation URL that is
verified live — then reads the mapped file and fetches the official ABP docs URL when the network is
available.

| Reference file | Topics covered |
|---|---|
| `references/context-intake.md` | **Phase 0**: read existing code through a knowledge graph, read repo plan/design `.md` files, UI source of truth (Stitch MCP or the project's own UI as reference), confirm scope with the user, SOLID + ABP design-pattern check |
| `references/INDEX.md` | **Routing table**: every topic → reference file → verified doc URL, plus the UI-stack decision matrix |
| `references/ddd-domain.md` | Entities, AggregateRoot, Value Objects, Domain Services, Repositories |
| `references/ddd-application.md` | Application Services, DTOs, CRUD patterns, ObjectMapper |
| `references/efcore.md` | DbContext, EF Core repositories, migrations, data seeding, multi-DBMS switching (MySQL/PostgreSQL/Oracle/SQLite) |
| `references/authorization.md` | Permission constants, `PermissionDefinitionProvider`, `[Authorize]`, resource permissions, dynamic claims, audit log module |
| `references/api.md` | Auto API Controllers, API versioning, integration services, static & dynamic C# client proxies, Swagger |
| `references/ui-razorpages.md` | Razor Pages, page models, tag helpers, JS API proxy |
| `references/ui-mvc.md` | ASP.NET Core MVC UI: `AbpController`, `Views/` + `_ViewImports`, tag helpers, bundling, `abp install-libs`, menu/toolbars |
| `references/ui-angular.md` | Angular SPA: `environment.ts`, `abp generate-proxy -t ng`, route-based menu, `*abpPermission`/`PermissionService`, localization, LeptonX theming, SSR/PWA |
| `references/cli-structure.md` | ABP CLI commands, startup templates, solution structure |
| `references/background-jobs.md` | Background jobs, periodic background workers |
| `references/event-bus.md` | Local domain events, pre-built entity events, Distributed Event Bus, ETOs |
| `references/multi-tenancy.md` | `IMustHaveTenant`, `IMayHaveTenant`, `ICurrentTenant`, tenant data isolation, per-tenant databases |
| `references/settings.md` | `SettingDefinitionProvider`, `ISettingProvider`, `ISettingManager`, setting scopes, encrypted settings |
| `references/caching.md` | `IDistributedCache<T>`, `GetOrAddAsync`, Entity Cache, cache invalidation, Redis setup |
| `references/modules.md` | Module system, `DependsOn`, `ConfigureServices`, `OnApplicationInitialization`, Virtual File Explorer |
| `references/testing-troubleshooting.md` | Unit tests, integration tests, common pitfalls |
| `references/localization.md` | `en.json` structure, `L[]` helper, `IStringLocalizer`, culture files, client-side localization API |
| `references/features.md` | `FeatureDefinitionProvider`, `IFeatureChecker`, `[RequiresFeature]`, `IFeatureManager`, feature value providers |
| `references/concurrency-check.md` | `IHasEntityVersion`, optimistic concurrency, `AbpDbConcurrencyException` |
| `references/connection-strings.md` | Connection string config, multi-DB setup, per-module and per-tenant databases |
| `references/data-filtering.md` | `IDataFilter<T>`, `ISoftDelete`, `IMultiTenant`, custom EF Core / MongoDB filters |
| `references/deployment.md` | Production config, SSL, OpenIddict signing certificates, IIS/Azure/Docker deployment |
| `references/global-features.md` | `GlobalFeatureManager`, `[RequiresGlobalFeature]`, `GlobalModuleFeatures`, `OneTimeRunner` |
| `references/image-manipulation.md` | `IImageCompressor`, `IImageResizer`, ImageSharp / Magick.NET / SkiaSharp providers |
| `references/interceptors.md` | `AbpInterceptor`, `OnRegistered`, `AbpDynamicProxyOptions`, DI-resolved proxy constraints |
| `references/json.md` | `IJsonSerializer`, System.Text.Json vs Newtonsoft, `AbpJsonOptions` date formats |
| `references/object-extensions.md` | `ObjectExtensionManager`, Module Entity Extensions, overriding services |
| `references/options.md` | Options pattern, `Configure<T>`, `PreConfigure<T>`, `IOptions<T>` injection |
| `references/signalr.md` | SignalR real-time communication, ABP hub wiring |
| `references/string-encryption.md` | `IStringEncryptionService`, `AbpStringEncryptionOptions`, AES encrypt/decrypt |
| `references/text-templating.md` | Scriban & Razor engines, `ITemplateRenderer`, layout templates, email templates |
| `references/theming.md` | UI Theming, layout system, theme customization, branding |
| `references/timing.md` | `IClock`, `AbpClockOptions`, `DateTimeKind.Utc`, timezone middleware, `[DisableDateTimeNormalization]` |
| `references/correlation-id.md` | `ICorrelationIdProvider`, `AbpCorrelationIdOptions`, automatic propagation across HTTP/events/logs |
| `references/cms-kit.md` | CMS Kit module: blogs, pages, comments, reactions, ratings, tags, menus, global resources |
| `references/openiddict.md` | OpenIddict module: OAuth/OIDC endpoints, token lifetimes, custom claims, seed data format |
| `references/database-tables.md` | Module DB table prefixes, connection string names, schema customisation |
| `references/maui.md` | .NET MAUI mobile UI, OIDC with Secure Storage, `adb reverse`, C# proxy injection |
| `references/react-native.md` | React Native / Expo mobile UI, `Environment.ts`, OpenIddict mobile client setup |
| `references/migration-identityserver-openiddict.md` | Step-by-step IdentityServer4 → OpenIddict migration for ABP v6+ |
| `references/ui-blazor.md` | Blazor WebAssembly / Server / WebApp: ABP components, `IMenuManager`/`IToolbarManager`/`IBrandingProvider`, theming + bundles, `abp generate-proxy -t csharp` |
| `references/microservices.md` | Microservice solution: `apps` / `gateways` / `services`, YARP gateway, RabbitMQ distributed event bus, outbox/inbox, per-service databases, DbMigrator |
| `references/blob-storing.md` | `IBlobContainer`, `IBlobContainer<T>`, `[BlobContainerName]`, File System/Database/Azure/AWS-S3/Minio/Google providers, `UseEncryption()`, pipeline contributors |
| `references/audit-logging.md` | Audit logging module + infrastructure: `AuditLog`, `AuditLogAction`, `EntityChange`, `AbpAuditingOptions`, `IAuditLogStore`, security logs, module extension |
| `references/openapi-swagger.md` | `Volo.Abp.Swashbuckle`, `AddAbpSwaggerGen*` / `UseAbpSwaggerUI`, OAuth + OIDC variants, `HideAbpEndpoints()`, exposing or protecting `/swagger` |
| `references/background-workers.md` | `AsyncPeriodicBackgroundWorkerBase`, `AbpAsyncTimer`, `IBackgroundWorkerManager`, `IDynamicBackgroundWorkerManager` (cron), clustered execution + distributed locks |
| `references/production-hardening.md` | Production checklist: cache/lock `KeyPrefix`, passphrases, data-protection keys, forwarded headers, HSTS, secrets, Swagger off, logging, migrations at boot |

> Each reference file declares the ABP version it targets and the date its documentation was last
> verified in a frontmatter block (`applies_to_abp` / `doc_verified_on`); `make links` (or
> `bash scripts/verify-skill.sh --links`) HEAD-checks every abp.io URL the skill references, so a moved
> doc page shows up as a failure instead of as bad code generation.

---

## Core ABP principles enforced by every agent

Every agent in this repository enforces these rules — they are non-negotiable in generated code:

0. **Phase 0 — context intake before any code** — read the existing code through a knowledge graph, read the repo's plan/design markdown, settle the UI source of truth (Stitch MCP if connected, otherwise the project's existing UI as the reference), confirm scope with the user, then apply SOLID — see [`abp-dev/references/context-intake.md`](abp-dev/references/context-intake.md)
1. **Layered architecture** — Domain → Application → Infrastructure (EF Core) → UI (MVC / Razor Pages / Angular / MAUI), detected from the target project
2. **Never expose entities** to the presentation layer — always map to DTOs with `ObjectMapper.Map<>()`
3. **Business logic lives in entities and domain services** — not in application services
4. **Application services orchestrate** — they call domain services / repositories and return DTOs
5. **Private/protected setters** on all entity properties — mutate state through business methods
6. **Always use `IGuidGenerator`** to create Guid IDs — never `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, enforced with `[Authorize]` in app services and in whichever UI the project uses
10. **`IDataSeedContributor`** must be idempotent — guard with `GetCountAsync() > 0` before inserting
11. **Reuse before adding** — extend an existing entity, domain service, permission group or UI pattern instead of creating a parallel second one

---

## Typical ABP solution structure

```
Acme.MyApp/
├── Acme.MyApp.Domain.Shared/         ← Enums, consts, error codes shared with clients
├── Acme.MyApp.Domain/                ← Entities, domain services, repository interfaces
├── Acme.MyApp.Application.Contracts/ ← App service interfaces, DTOs, permission constants
├── Acme.MyApp.Application/           ← App service implementations, AutoMapper profiles
├── Acme.MyApp.EntityFrameworkCore/   ← DbContext, EF Core repository implementations
├── Acme.MyApp.DbMigrator/            ← CLI tool: run migrations + seed data
├── Acme.MyApp.HttpApi/               ← (optional) manual API controllers
└── Acme.MyApp.Web/                   ← Razor Pages, menus, bundling
```

---

## License

[MIT](LICENSE)
