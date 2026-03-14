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

You are an expert ABP Framework developer. Always follow ABP conventions precisely.
The user's stack: **Razor Pages / MVC UI + EF Core**.

## How to use this skill

Read the relevant reference file(s) before answering:

| Topic | Reference File |
|---|---|
| Entities, AggregateRoot, Value Objects, Domain Services | `references/ddd-domain.md` |
| Application Services, DTOs, CRUD patterns | `references/ddd-application.md` |
| Module system, DependsOn, ConfigureServices | `references/modules.md` |
| EF Core DbContext, repositories, migrations | `references/efcore.md` |
| Data seeding (IDataSeedContributor) | `references/efcore.md` |
| Permissions, Authorization, [Authorize] | `references/authorization.md` |
| Auto API Controllers, HTTP API | `references/api.md` |
| Razor Pages UI, page models, tag helpers, JS API | `references/ui-razorpages.md` |
| ABP CLI, startup template, project structure | `references/cli-structure.md` |
| Background Jobs (IBackgroundJob), recurring workers | `references/background-jobs.md` |
| Testing (unit, integration, test data seed) | `references/testing-troubleshooting.md` |
| Troubleshooting (AutoMapper, permissions, migrations) | `references/testing-troubleshooting.md` |

For questions touching multiple areas (e.g. "build a full CRUD feature"), read all relevant files.

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
