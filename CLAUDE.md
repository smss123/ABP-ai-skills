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
| Auto API Controllers, API Versioning, Integration Services, Dynamic C# Proxies | `abp-dev/references/api.md` | https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers |
| Razor Pages UI, tag helpers | `abp-dev/references/ui-razorpages.md` | https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages |
| ABP CLI, solution structure | `abp-dev/references/cli-structure.md` | https://docs.abp.io/en/abp/latest/CLI |
| Background Jobs & Workers | `abp-dev/references/background-jobs.md` | https://docs.abp.io/en/abp/latest/Background-Jobs |
| Local Event Bus, Domain Events | `abp-dev/references/event-bus.md` | https://docs.abp.io/en/abp/latest/Local-Event-Bus |
| Distributed Event Bus | `abp-dev/references/event-bus.md` | https://docs.abp.io/en/abp/latest/Distributed-Event-Bus |
| Multi-Tenancy | `abp-dev/references/multi-tenancy.md` | https://docs.abp.io/en/abp/latest/Multi-Tenancy |
| Settings | `abp-dev/references/settings.md` | https://docs.abp.io/en/abp/latest/Settings |
| Caching | `abp-dev/references/caching.md` | https://docs.abp.io/en/abp/latest/Caching |
| Testing & Troubleshooting | `abp-dev/references/testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Testing |
| Connection Strings, multi-DB | `abp-dev/references/connection-strings.md` | https://abp.io/docs/latest/framework/fundamentals/connection-strings |
| Localization, L[] shorthand | `abp-dev/references/localization.md` | https://abp.io/docs/latest/framework/fundamentals/localization |
| Object Extensions, Module Entity Extensions, Override Services | `abp-dev/references/object-extensions.md` | https://abp.io/docs/latest/framework/fundamentals/object-extensions |
| Options Pattern, Configure\<T\>, PreConfigure | `abp-dev/references/options.md` | https://abp.io/docs/latest/framework/fundamentals/options |
| Concurrency Check, IHasEntityVersion | `abp-dev/references/concurrency-check.md` | https://abp.io/docs/latest/framework/infrastructure/concurrency-check |
| Data Filtering, ISoftDelete, IMultiTenant, Custom Filters | `abp-dev/references/data-filtering.md` | https://abp.io/docs/latest/framework/infrastructure/data-filtering |
| Global Features, GlobalFeatureManager, RequiresGlobalFeature | `abp-dev/references/global-features.md` | https://abp.io/docs/latest/framework/infrastructure/global-features |
| Image Compression & Resizing, IImageCompressor, IImageResizer | `abp-dev/references/image-manipulation.md` | https://abp.io/docs/latest/framework/infrastructure/image-manipulation |
| Interceptors, AbpInterceptor, OnRegistered, DynamicProxy | `abp-dev/references/interceptors.md` | https://abp.io/docs/latest/framework/infrastructure/interceptors |
| JSON Serialization, IJsonSerializer, System.Text.Json vs Newtonsoft | `abp-dev/references/json.md` | https://abp.io/docs/latest/framework/infrastructure/json |
| String Encryption, IStringEncryptionService, AbpStringEncryptionOptions | `abp-dev/references/string-encryption.md` | https://abp.io/docs/latest/framework/infrastructure/string-encryption |
| Text Templating, Scriban, Razor, ITemplateRenderer, email templates | `abp-dev/references/text-templating.md` | https://abp.io/docs/latest/framework/infrastructure/text-templating/scriban |
| Timing, IClock, DateTimeKind, timezone, AbpClockOptions | `abp-dev/references/timing.md` | https://abp.io/docs/latest/framework/infrastructure/timing |
| Correlation ID, ICorrelationIdProvider, AbpCorrelationIdOptions | `abp-dev/references/correlation-id.md` | https://abp.io/docs/latest/framework/infrastructure/correlation-id |
| React Native Mobile UI, Expo, Environment.ts, OpenIddict mobile | `abp-dev/references/react-native.md` | https://abp.io/docs/latest/framework/ui/react-native |
| .NET MAUI Mobile UI, OIDC, adb reverse, C# proxies | `abp-dev/references/maui.md` | https://abp.io/docs/latest/framework/ui/maui |
| SignalR Real-Time Communication | `abp-dev/references/signalr.md` | https://abp.io/docs/latest/framework/real-time/signalr |
| UI Theming, Layout System, Theme Customization | `abp-dev/references/theming.md` | https://abp.io/docs/latest/ui-themes |
| Deployment, SSL, OpenIddict, Production Config | `abp-dev/references/deployment.md` | https://abp.io/docs/latest/deployment |
| Migrating IdentityServer4 → OpenIddict (ABP v6+) | `abp-dev/references/migration-identityserver-openiddict.md` | https://abp.io/docs/latest/release-info/migration-guides/openiddict-step-by-step |
| CMS Kit Module, blogs, pages, comments, reactions, tags | `abp-dev/references/cms-kit.md` | https://abp.io/docs/latest/modules/cms-kit |
| Features System, IFeatureChecker, Feature Management, IFeatureManager | `abp-dev/references/features.md` | https://abp.io/docs/latest/modules/feature-management |
| OpenIddict Module, OAuth endpoints, token lifetimes, claims | `abp-dev/references/openiddict.md` | https://abp.io/docs/latest/modules/openiddict |
| Module Database Tables, prefixes, connection string names | `abp-dev/references/database-tables.md` | https://abp.io/docs/latest/modules/database-tables |

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
