# ABP Framework — Development Instructions for Claude Code

This repository contains curated ABP Framework skills. When working on any ABP project, always apply the guidance below **before** generating code or advice.

## How to use these instructions

1. **Read the reference file** for the relevant topic from the table below.
2. **Fetch the official documentation URL** listed in that file using the `WebFetch` tool to get the latest API details.
3. Synthesise both sources, then generate code.

> If a fetch fails (network unavailable), rely on the reference file and note that the answer is based on cached documentation.

## Reference Files

| Topic | File | Official Docs |
|---|---|---|
| Entities, AggregateRoot, Value Objects | `abp-dev/references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Entities |
| Domain Services | `abp-dev/references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Domain-Services |
| Repositories | `abp-dev/references/ddd-domain.md` | https://docs.abp.io/en/abp/latest/Repositories |
| Application Services, DTOs, CRUD | `abp-dev/references/ddd-application.md` | https://docs.abp.io/en/abp/latest/Application-Services |
| Module system, DependsOn | `abp-dev/references/modules.md` | https://docs.abp.io/en/abp/latest/Module-Development-Basics |
| EF Core DbContext, migrations | `abp-dev/references/efcore.md` | https://docs.abp.io/en/abp/latest/Entity-Framework-Core |
| Data seeding | `abp-dev/references/efcore.md` | https://docs.abp.io/en/abp/latest/Data-Seeding |
| Permissions, Authorization | `abp-dev/references/authorization.md` | https://docs.abp.io/en/abp/latest/Authorization |
| Auto API Controllers | `abp-dev/references/api.md` | https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers |
| Razor Pages UI, tag helpers | `abp-dev/references/ui-razorpages.md` | https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages |
| ABP CLI, solution structure | `abp-dev/references/cli-structure.md` | https://docs.abp.io/en/abp/latest/CLI |
| Background Jobs & Workers | `abp-dev/references/background-jobs.md` | https://docs.abp.io/en/abp/latest/Background-Jobs |
| Local Event Bus, Domain Events | `abp-dev/references/event-bus.md` | https://docs.abp.io/en/abp/latest/Local-Event-Bus |
| Distributed Event Bus | `abp-dev/references/event-bus.md` | https://docs.abp.io/en/abp/latest/Distributed-Event-Bus |
| Testing & Troubleshooting | `abp-dev/references/testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Testing |

For questions covering multiple areas (e.g. "build a full CRUD feature"), read all relevant reference files.

## Core ABP Principles (always apply)

1. **Layered architecture**: Domain → Application → Infrastructure (EF Core) → Web (Razor Pages)
2. **Never expose entities** to the presentation layer — always use DTOs
3. **Business logic** lives in entities and domain services, not in application services
4. **Application services orchestrate** — call domain services/repositories and map to DTOs
5. **Protected/private setters** on entity properties — enforce changes through methods
6. **Always use `IGuidGenerator`** to generate Guid IDs — never call `Guid.NewGuid()` directly
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
