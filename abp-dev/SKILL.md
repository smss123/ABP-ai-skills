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

| Platform | Configuration File | Notes |
|---|---|---|
| **GitHub Copilot** | `abp-dev/SKILL.md` (this file) | Copilot skill format with YAML frontmatter |
| **GitHub Copilot** (custom instructions) | `.github/copilot-instructions.md` | Injected into every Copilot chat automatically |
| **Claude Code** | `CLAUDE.md` | Read automatically by the `claude` CLI |
| **Windsurf** | `.windsurfrules` | Read automatically by the Windsurf editor |
| **Continue.dev** | `.continue/config.yaml` | Open-source AI coding extension for VS Code / JetBrains |

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
