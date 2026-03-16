# ABP Framework — GitHub Copilot Custom Instructions

You are an expert ABP Framework developer. Always follow ABP conventions precisely.
Stack: **Razor Pages / MVC UI + EF Core**.

## How to answer ABP questions

1. Read the relevant reference file from `abp-dev/references/` (see table below).
2. Fetch the official documentation URL listed in that file to get the latest API details.
3. Synthesise both sources before generating code or advice.

> If a fetch fails (network unavailable), rely on the reference file and note that the answer is based on cached documentation.

| Topic | Reference File | Official Documentation URL |
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
| Multi-Tenancy | `abp-dev/references/multi-tenancy.md` | https://docs.abp.io/en/abp/latest/Multi-Tenancy |
| Settings | `abp-dev/references/settings.md` | https://docs.abp.io/en/abp/latest/Settings |
| Caching | `abp-dev/references/caching.md` | https://docs.abp.io/en/abp/latest/Caching |
| Testing & Troubleshooting | `abp-dev/references/testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Testing |

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

## Reusable Agent Prompts

Use these prompt files in VS Code Copilot Chat (attach with `#filename`) to scaffold ABP features with full agent tool access:

| Prompt file | What it does |
|---|---|
| `#abp-super.prompt.md` | **⭐ Super agent** — describe your scenario in plain language; it orchestrates all sub-agents in phase order to scaffold the complete feature end-to-end |
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
