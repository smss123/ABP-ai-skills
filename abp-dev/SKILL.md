---
name: abp-dev
description: >
  Expert guide for developing applications with the ABP Framework (abp.io) using ASP.NET Core,
  DDD patterns, and Razor Pages / MVC UI. Use this skill whenever the user mentions ABP, abp.io,
  Volo.Abp, AbpModule, application services, aggregate roots, domain services, ABP CLI, 
  IRepository, PermissionDefinitionProvider, IDataSeedContributor, Auto API Controllers,
  AbpDbContext, or any ABP-specific concept. Also trigger for questions about layered ABP project
  structure, startup templates, or ABP module dependencies. Always consult this skill before
  generating any ABP-related code, architecture advice, or explaining ABP concepts — even for
  seemingly simple questions like "how do I create an entity in ABP".
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
| **GitHub Copilot** | `abp-dev/SKILL.md` (this file) + `.github/copilot-instructions.md` | `.github/prompts/` — 11 reusable agent prompts (see table below) |
| **Claude Code** | `CLAUDE.md` | `.claude/commands/` — 11 slash commands (see table below) |
| **Windsurf** | `.windsurfrules` | `.windsurf/workflows/` — 11 Cascade workflows (see table below) |
| **Continue.dev** | `.continue/config.yaml` (`systemMessage`) | `.continue/config.yaml` (`agents:` block) — 10 specialized agents |

## 🚀 Super Agent — Start here for full-feature scaffolding

The **`abp-super`** agent is the top-level orchestrator. Give it a plain-language description of your feature and it will:

1. Parse entities, properties, and optional features from your description
2. Show you a confirmed analysis table
3. Present a phase-by-phase execution plan with file counts
4. Execute each sub-agent in the correct layer order:

```
Phase 1 → Domain layer     (entity, domain service, repository interface)
Phase 2 → App.Contracts    (permissions, DTOs, app service interface)
Phase 3 → Application      (app service impl, AutoMapper, specification, background worker)
Phase 4 → EF Core          (EfCore repository, DbSet, model config, module registration)
Phase 5 → Database         (migration commands)
Phase 6 → UI               (Razor Pages — optional)
Phase 7 → Seed data        (IDataSeedContributor — optional)
```

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
| **abp-entity** | `#abp-entity.prompt.md` | `/project:abp-entity` | *(use abp-crud)* | Domain entity class + repository interface + domain service (domain layer only) |
| **abp-domain-service** | `#abp-domain-service.prompt.md` | `/project:abp-domain-service` | `abp-domain-service` | Manager class only — uniqueness enforcement, `GuidGenerator.Create()` |
| **abp-repository** | `#abp-repository.prompt.md` | `/project:abp-repository` | `abp-repository` | Repository interface (Domain) + EF Core implementation + model config + module registration snippets |
| **abp-app-service** | `#abp-app-service.prompt.md` | `/project:abp-app-service` | `abp-app-service` | DTOs + app service interface + implementation + AutoMapper entries |
| **abp-permissions** | `#abp-permissions.prompt.md` | `/project:abp-permissions` | `abp-permissions` | Permission constants + `PermissionDefinitionProvider` + localization keys |
| **abp-specification** | `#abp-specification.prompt.md` | `/project:abp-specification` | `abp-specification` | `Specification<T>` class for domain query filtering with `.And()/.Or()/.Not()` combinators |
| **abp-background-worker** | `#abp-background-worker.prompt.md` | `/project:abp-background-worker` | `abp-background-worker` | Background job (`AsyncBackgroundJob<TArgs>`) or periodic worker (`AsyncPeriodicBackgroundWorkerBase`) |
| **abp-razor-page** | `#abp-razor-page.prompt.md` | `/project:abp-razor-page` | `abp-razor-page` | Razor Pages UI — list page + JS DataTable + create/edit modals + menu registration |
| **abp-data-seed** | `#abp-data-seed.prompt.md` | `/project:abp-data-seed` | `abp-data-seed` | `IDataSeedContributor` with idempotent guard, `IGuidGenerator`, `autoSave: true` |

You are an expert ABP Framework developer. Always follow ABP conventions precisely.
The user's stack: **Razor Pages / MVC UI + EF Core**.

## How to use this skill

Follow these steps **in order** for every ABP-related question:

1. **Read the local reference file(s)** from the table below — they contain curated, correct patterns.
2. **Fetch the official documentation page** listed in the same row using `web_fetch` (or a browser tool) to get the latest API details, version-specific notes, or anything the reference file may not cover.
3. Synthesise both sources before generating code or advice.

> If a fetch fails (network unavailable), rely on the local reference file and note that the answer is based on cached documentation.

| Topic | Reference File | Official Documentation URL |
|---|---|---|
| Entities, AggregateRoot, Value Objects | `references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Entities |
| Domain Services | `references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Domain-Services |
| Value Objects | `references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Value-Objects |
| Repositories | `references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Repositories |
| Application Services, DTOs, CRUD patterns | `references/ddd-application.md` | https://docs.abp.io/en/abp/latest/Application-Services |
| Module system, DependsOn, ConfigureServices | `references/modules.md` | https://docs.abp.io/en/abp/latest/Module-Development-Basics |
| EF Core DbContext, repositories, migrations | `references/efcore.md` | https://docs.abp.io/en/abp/latest/Entity-Framework-Core |
| Data seeding (IDataSeedContributor) | `references/efcore.md` | https://docs.abp.io/en/abp/latest/Data-Seeding |
| Permissions, Authorization, [Authorize] | `references/authorization.md` | https://docs.abp.io/en/abp/latest/Authorization |
| Auto API Controllers, HTTP API | `references/api.md` | https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers |
| Razor Pages UI, page models, tag helpers, JS API | `references/ui-razorpages.md` | https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages |
| ABP CLI, startup template, project structure | `references/cli-structure.md` | https://docs.abp.io/en/abp/latest/CLI |
| Background Jobs (IBackgroundJob) | `references/background-jobs.md` | https://docs.abp.io/en/abp/latest/Background-Jobs |
| Recurring background workers | `references/background-jobs.md` | https://docs.abp.io/en/abp/latest/Background-Workers |
| Testing (unit, integration, test data seed) | `references/testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Testing |
| Troubleshooting (AutoMapper, permissions, migrations) | `references/testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Customizing-Application-Modules-Guide |

For questions touching multiple areas (e.g. "build a full CRUD feature"), read all relevant files and fetch all relevant documentation pages.

## Core ABP Principles (always apply)

1. **Layered architecture**: Domain → Application → Infrastructure (EF Core) → Web (Razor Pages)
2. **Never expose entities to the presentation layer** — always use DTOs
3. **Business logic lives in entities and domain services**, not in application services
4. **Application services orchestrate** — they call domain services / repositories, map to DTOs
5. **Protected/private setters on entity properties** — enforce changes through methods
6. **Always use `IGuidGenerator`** to generate Guid IDs, never `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, checked in Application Services and Razor Pages

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
└── Acme.MyApp.Web/                   ← Razor Pages, menus, page models
```
