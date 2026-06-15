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
- [Reference files](#reference-files)
- [Core ABP principles enforced by every agent](#core-abp-principles-enforced-by-every-agent)
- [Typical ABP solution structure](#typical-abp-solution-structure)
- [License](#license)

---

## What's included

| What | Where | Purpose |
|---|---|---|
| **Super agent** | platform-specific (see below) | Orchestrates all sub-agents from a plain-language scenario |
| **15 scaffold agents** | `.github/prompts/`, `.claude/commands/`, `.windsurf/workflows/`, `.continue/config.yaml` | One agent per ABP layer / concern (plus super agent = 16 total per platform) |
| **38 reference files** | `abp-dev/references/` | Curated, correct ABP patterns for every topic |
| **Platform instructions** | `.github/copilot-instructions.md`, `CLAUDE.md`, `.windsurfrules`, `.continue/config.yaml` | Injects ABP expertise into the AI assistant |

---

## Quick start

**1. Copy the config files into your ABP project root:**

```
cp -r .github/ .claude/ .windsurf/ .continue/ abp-dev/  /path/to/your/abp-project/
# (also copy CLAUDE.md and .windsurfrules for Claude Code / Windsurf)
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

1. **Parse** entities, properties, and optional features (background jobs, specs, UI, seeding) from your description
2. **Show** a confirmed analysis table — no code is written until you approve
3. **Present** a full file-by-file execution plan grouped by layer
4. **Execute** each sub-agent in the correct dependency order:

```
Phase 1 → Domain layer       entity class · domain service (Manager) · repository interface
Phase 2 → App.Contracts      permission constants · DTOs · app service interface
Phase 3 → Application        app service implementation · AutoMapper · specification · background worker
Phase 4 → EF Core            EfCoreRepository · DbSet · model config · module registration
Phase 5 → Database           EF Core migration commands
Phase 6 → UI (optional)      Razor Pages list + create/edit modals + JS DataTable + menu
Phase 7 → Seed (optional)    IDataSeedContributor with idempotent guard
```

5. **Print** a summary: total files generated, layer breakdown, next-steps checklist

### Example prompt

> *"I want to manage Products. Each Product has a Name (required, max 128 chars), a decimal Price, and an IsActive flag. I need Razor Pages UI and some seed data with 3 sample products."*

The Super Agent will scaffold ~15 files across all 7 phases without any further input.

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

| Agent | Copilot | Claude Code | Windsurf | What it generates |
|---|---|---|---|---|
| ⭐ **abp-super** | `#abp-super.prompt.md` | `/project:abp-super` | `abp-super` | **Full feature end-to-end** — orchestrates all sub-agents in phase order |
| 🔧 **abp-feature-scaffold** | `#abp-feature-scaffold.prompt.md` | `/project:abp-feature-scaffold` | `abp-feature-scaffold` | **Application layer for an existing entity** — error codes · localization · FluentValidation · permissions · app service · AutoMapper · optional Razor Pages UI (domain layer untouched) |
| **abp-crud** | `#abp-crud.prompt.md` | `/project:abp-crud` | `abp-crud` | All 12 CRUD files: entity · domain service · repo · DTOs · app service · EF Core · optional Razor Pages |
| **abp-entity** | `#abp-entity.prompt.md` | `/project:abp-entity` | `abp-entity` | Domain entity class + repository interface + domain service (domain layer only) |
| **abp-domain-service** | `#abp-domain-service.prompt.md` | `/project:abp-domain-service` | `abp-domain-service` | `<Entity>Manager` — uniqueness enforcement, `GuidGenerator.Create()` |
| **abp-repository** | `#abp-repository.prompt.md` | `/project:abp-repository` | `abp-repository` | `I<Entity>Repository` + `EfCore<Entity>Repository` + DbSet/config/module snippets |
| **abp-app-service** | `#abp-app-service.prompt.md` | `/project:abp-app-service` | `abp-app-service` | DTOs + `I<Entity>AppService` + `<Entity>AppService` + AutoMapper entries |
| **abp-permissions** | `#abp-permissions.prompt.md` | `/project:abp-permissions` | `abp-permissions` | Permission constants + `PermissionDefinitionProvider` + `en.json` localization keys |
| **abp-specification** | `#abp-specification.prompt.md` | `/project:abp-specification` | `abp-specification` | `Specification<T>` with `.And()/.Or()/.Not()` combinators |
| **abp-background-worker** | `#abp-background-worker.prompt.md` | `/project:abp-background-worker` | `abp-background-worker` | `AsyncBackgroundJob<TArgs>` (fire-and-forget) or `AsyncPeriodicBackgroundWorkerBase` (periodic) |
| **abp-razor-page** | `#abp-razor-page.prompt.md` | `/project:abp-razor-page` | `abp-razor-page` | Razor Pages list page · JS DataTable · create/edit modals · menu registration |
| **abp-data-seed** | `#abp-data-seed.prompt.md` | `/project:abp-data-seed` | `abp-data-seed` | `IDataSeedContributor` — idempotent guard, `IGuidGenerator`, `autoSave: true` |
| **abp-event-bus** | `#abp-event-bus.prompt.md` | `/project:abp-event-bus` | `abp-event-bus` | ETO class + `ILocalEventHandler<T>` or `IDistributedEventHandler<T>` + event bus wiring |
| **abp-multi-tenancy** | `#abp-multi-tenancy.prompt.md` | `/project:abp-multi-tenancy` | `abp-multi-tenancy` | `IMustHaveTenant`/`IMayHaveTenant`, `ICurrentTenant`, data filters, per-tenant databases |
| **abp-settings** | `#abp-settings.prompt.md` | `/project:abp-settings` | `abp-settings` | `SettingDefinitionProvider` + `ISettingProvider` (read) + `ISettingManager` (write) |
| **abp-caching** | `#abp-caching.prompt.md` | `/project:abp-caching` | `abp-caching` | `IDistributedCache<TCacheItem>`, `GetOrAddAsync`, cache invalidation, Redis setup |

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
├── abp-dev/
│   ├── SKILL.md                        ← Master skill definition (all platforms)
│   └── references/
│       ├── ddd-domain.md                          ← Entities, AggregateRoot, Domain Services, Repositories
│       ├── ddd-application.md                     ← Application Services, DTOs, CRUD patterns
│       ├── efcore.md                              ← EF Core DbContext, migrations, multi-DBMS switching
│       ├── authorization.md                       ← Permissions, [Authorize], PermissionDefinitionProvider, Audit Logging
│       ├── api.md                                 ← Auto API Controllers, Versioning, Integration Services, Static/Dynamic Proxies
│       ├── ui-razorpages.md                       ← Razor Pages, page models, tag helpers, JS API
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
│       ├── maui.md                                ← .NET MAUI mobile UI, OIDC, adb reverse
│       ├── react-native.md                        ← React Native / Expo mobile UI
│       └── migration-identityserver-openiddict.md ← IdentityServer4 → OpenIddict migration guide
│
├── .github/
│   ├── copilot-instructions.md         ← Copilot global instructions (auto-loaded)
│   └── prompts/
│       ├── abp-super.prompt.md         ⭐ Super agent
│       ├── abp-crud.prompt.md
│       ├── abp-entity.prompt.md
│       ├── abp-domain-service.prompt.md
│       ├── abp-repository.prompt.md
│       ├── abp-app-service.prompt.md
│       ├── abp-permissions.prompt.md
│       ├── abp-specification.prompt.md
│       ├── abp-background-worker.prompt.md
│       ├── abp-razor-page.prompt.md
│       ├── abp-data-seed.prompt.md
│       ├── abp-event-bus.prompt.md
│       ├── abp-multi-tenancy.prompt.md
│       ├── abp-settings.prompt.md
│       ├── abp-caching.prompt.md
│       └── abp-feature-scaffold.prompt.md
│
├── .claude/
│   └── commands/
│       ├── abp-super.md                ⭐ /project:abp-super
│       ├── abp-crud.md
│       ├── abp-entity.md
│       ├── abp-domain-service.md
│       ├── abp-repository.md
│       ├── abp-app-service.md
│       ├── abp-permissions.md
│       ├── abp-specification.md
│       ├── abp-background-worker.md
│       ├── abp-razor-page.md
│       ├── abp-data-seed.md
│       ├── abp-event-bus.md
│       ├── abp-multi-tenancy.md
│       ├── abp-settings.md
│       ├── abp-caching.md
│       └── abp-feature-scaffold.md
│
├── .windsurf/
│   └── workflows/
│       ├── abp-super.md                ⭐ run workflow abp-super
│       ├── abp-crud.md
│       ├── abp-entity.md
│       ├── abp-domain-service.md
│       ├── abp-repository.md
│       ├── abp-app-service.md
│       ├── abp-permissions.md
│       ├── abp-specification.md
│       ├── abp-background-worker.md
│       ├── abp-razor-page.md
│       ├── abp-data-seed.md
│       ├── abp-event-bus.md
│       ├── abp-multi-tenancy.md
│       ├── abp-settings.md
│       ├── abp-caching.md
│       └── abp-feature-scaffold.md
│
├── .continue/
│   └── config.yaml                     ← System message + docs index + all agents
│
├── .windsurfrules                      ← Windsurf global rules (auto-loaded)
├── CLAUDE.md                           ← Claude Code global instructions (auto-loaded)
├── LICENSE
└── README.md                           ← This file
```

---

## Reference files

Every agent reads the relevant reference file(s) before generating any code, and fetches the official ABP docs URL when the network is available.

| Reference file | Topics covered |
|---|---|
| `references/ddd-domain.md` | Entities, AggregateRoot, Value Objects, Domain Services, Repositories |
| `references/ddd-application.md` | Application Services, DTOs, CRUD patterns, ObjectMapper |
| `references/efcore.md` | DbContext, EF Core repositories, migrations, data seeding, multi-DBMS switching (MySQL/PostgreSQL/Oracle/SQLite) |
| `references/authorization.md` | Permission constants, `PermissionDefinitionProvider`, `[Authorize]`, resource permissions, dynamic claims, audit log module |
| `references/api.md` | Auto API Controllers, API versioning, integration services, static & dynamic C# client proxies, Swagger |
| `references/ui-razorpages.md` | Razor Pages, page models, tag helpers, JS API proxy |
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

---

## Core ABP principles enforced by every agent

Every agent in this repository enforces these rules — they are non-negotiable in generated code:

1. **Layered architecture** — Domain → Application → Infrastructure (EF Core) → Web (Razor Pages)
2. **Never expose entities** to the presentation layer — always map to DTOs with `ObjectMapper.Map<>()`
3. **Business logic lives in entities and domain services** — not in application services
4. **Application services orchestrate** — they call domain services / repositories and return DTOs
5. **Private/protected setters** on all entity properties — mutate state through business methods
6. **Always use `IGuidGenerator`** to create Guid IDs — never `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, enforced with `[Authorize]` in app services and Razor Pages
10. **`IDataSeedContributor`** must be idempotent — guard with `GetCountAsync() > 0` before inserting

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
