# ABP AI Skills

> **AI coding skills for the [ABP Framework](https://abp.io) — works with GitHub Copilot, Claude Code, Windsurf, and Continue.dev.**

A collection of curated AI agent prompts, slash commands, and workflow definitions that give your AI coding assistant deep, accurate knowledge of ABP Framework patterns. Drop this repository (or copy its config files) into any ABP project and your AI will scaffold production-ready, convention-correct code across every layer.

**Author:** Samer Abdallah · **Company:** Xprema Systems

---

## Table of Contents

- [What's included](#whats-included)
- [Quick start](#quick-start)
- [⭐ Super Agent — scaffold a full feature in one prompt](#-super-agent--scaffold-a-full-feature-in-one-prompt)
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
| **14 scaffold agents** | `.github/prompts/`, `.claude/commands/`, `.windsurf/workflows/`, `.continue/config.yaml` | One agent per ABP layer / concern (plus super agent = 15 total per platform) |
| **14 reference files** | `abp-dev/references/` | Curated, correct ABP patterns for every topic |
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

## All agents at a glance

| Agent | Copilot | Claude Code | Windsurf | What it generates |
|---|---|---|---|---|
| ⭐ **abp-super** | `#abp-super.prompt.md` | `/project:abp-super` | `abp-super` | **Full feature end-to-end** — orchestrates all sub-agents in phase order |
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
│       ├── ddd-domain.md               ← Entities, AggregateRoot, Domain Services, Repositories
│       ├── ddd-application.md          ← Application Services, DTOs, CRUD patterns
│       ├── efcore.md                   ← EF Core DbContext, migrations, data seeding
│       ├── authorization.md            ← Permissions, [Authorize], PermissionDefinitionProvider
│       ├── api.md                      ← Auto API Controllers
│       ├── ui-razorpages.md            ← Razor Pages, page models, tag helpers, JS API
│       ├── cli-structure.md            ← ABP CLI, startup templates, solution structure
│       ├── background-jobs.md          ← Background jobs and periodic workers
│       ├── event-bus.md                ← Local domain events & Distributed Event Bus
│       ├── multi-tenancy.md            ← IMustHaveTenant, ICurrentTenant, data isolation
│       ├── settings.md                 ← SettingDefinitionProvider, ISettingProvider, ISettingManager
│       ├── caching.md                  ← IDistributedCache<T>, GetOrAddAsync, Redis setup
│       ├── modules.md                  ← Module system, DependsOn, ConfigureServices
│       └── testing-troubleshooting.md  ← Unit/integration testing, common pitfalls
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
│       └── abp-caching.prompt.md
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
│       └── abp-caching.md
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
│       └── abp-caching.md
│
├── .continue/
│   └── config.yaml                     ← System message + docs index + 13 agents
│
├── .windsurfrules                      ← Windsurf global rules (auto-loaded)
├── CLAUDE.md                           ← Claude Code global instructions (auto-loaded)
├── LICENSE
└── README.md                           ← This file
```

---

## Reference files

Every agent reads the relevant reference file(s) before generating any code, and fetches the official ABP docs URL when the network is available.

| Reference file | Topics covered | Official docs |
|---|---|---|
| `references/ddd-domain.md` | Entities, AggregateRoot, Value Objects, Domain Services, Repositories | [Entities](https://docs.abp.io/en/abp/latest/Entities) · [Domain Services](https://docs.abp.io/en/abp/latest/Domain-Services) · [Repositories](https://docs.abp.io/en/abp/latest/Repositories) |
| `references/ddd-application.md` | Application Services, DTOs, CRUD patterns, ObjectMapper | [Application Services](https://docs.abp.io/en/abp/latest/Application-Services) |
| `references/efcore.md` | DbContext, EF Core repositories, migrations, data seeding | [EF Core](https://docs.abp.io/en/abp/latest/Entity-Framework-Core) · [Data Seeding](https://docs.abp.io/en/abp/latest/Data-Seeding) |
| `references/authorization.md` | Permission constants, PermissionDefinitionProvider, `[Authorize]` | [Authorization](https://docs.abp.io/en/abp/latest/Authorization) |
| `references/api.md` | Auto API Controllers, HTTP API conventions | [Auto API Controllers](https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers) |
| `references/ui-razorpages.md` | Razor Pages, page models, tag helpers, JS API proxy | [Razor Pages UI](https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages) |
| `references/cli-structure.md` | ABP CLI commands, startup templates, solution structure | [ABP CLI](https://docs.abp.io/en/abp/latest/CLI) |
| `references/background-jobs.md` | Background jobs, periodic background workers | [Background Jobs](https://docs.abp.io/en/abp/latest/Background-Jobs) · [Background Workers](https://docs.abp.io/en/abp/latest/Background-Workers) |
| `references/event-bus.md` | Local domain events (`AddLocalEvent`, `ILocalEventHandler<T>`), Distributed Event Bus (`IDistributedEventBus`, `IDistributedEventHandler<T>`), ETOs | [Local Event Bus](https://docs.abp.io/en/abp/latest/Local-Event-Bus) · [Distributed Event Bus](https://docs.abp.io/en/abp/latest/Distributed-Event-Bus) |
| `references/multi-tenancy.md` | `IMustHaveTenant`, `IMayHaveTenant`, `ICurrentTenant`, tenant data isolation, `IDataFilter`, per-tenant databases | [Multi-Tenancy](https://docs.abp.io/en/abp/latest/Multi-Tenancy) |
| `references/settings.md` | `SettingDefinitionProvider`, `ISettingProvider`, `ISettingManager`, setting scopes (Global/Tenant/User), encrypted settings | [Settings](https://docs.abp.io/en/abp/latest/Settings) |
| `references/caching.md` | `IDistributedCache<T>`, `[CacheName]`, `GetOrAddAsync`, cache invalidation, multi-tenancy isolation, Redis setup | [Caching](https://docs.abp.io/en/abp/latest/Caching) |
| `references/modules.md` | Module system, `DependsOn`, `ConfigureServices`, `OnApplicationInitialization` | [Module Development](https://docs.abp.io/en/abp/latest/Module-Development-Basics) |
| `references/testing-troubleshooting.md` | Unit tests, integration tests, common AutoMapper/permission/migration pitfalls | [Testing](https://docs.abp.io/en/abp/latest/Testing) |

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
