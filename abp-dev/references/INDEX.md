# ABP Reference Index — single routing table

**This file is the only routing table for the ABP reference files.** Every agent instruction file
(`abp-dev/SKILL.md`, `CLAUDE.md`, `AGENT.md`, `.windsurfrules`, `.github/copilot-instructions.md`,
`.continue/config.yaml`) points here instead of keeping its own copy — that duplication is what
caused references to become unreachable and counts to drift.

How to use:

1. **Read `context-intake.md` first** — Phase 0: inspect the existing code through a knowledge graph,
   read the repo's plan/design `.md` files, pick the UI source of truth (Stitch MCP if connected,
   otherwise the project's existing UI as the reference), confirm scope with the user, then apply the
   SOLID / design-pattern check. No code generation before that.
2. Find the topic row below, read that reference file.
3. Fetch the doc URL in the same row (live-verified against ABP 10.x as of 2026-10-29).
4. Synthesise both, then generate code.

> When a fetch fails, use the local reference file and state that the answer is based on cached
> documentation.

---

## Process — always step 0

| Step | File | Notes |
|---|---|---|
| Existing-code inspection, plan docs, UI source of truth, user confirmation, SOLID & patterns | `context-intake.md` | https://abp.io/docs/latest/framework/architecture/domain-driven-design/general |

---

## Choosing a UI stack (read this first for any UI question)

| UI option | `abp new` flag | Reference file |
|---|---|---|
| Razor Pages (ABP's recommendation for server-side pages) | `-u razor` / default app template | `ui-razorpages.md` |
| ASP.NET Core MVC (controllers + views; shared infra with Razor Pages) | `-u mvc` | `ui-mvc.md` |
| Angular SPA (separate `angular/` folder, no `*.Web` project) | `-u angular` | `ui-angular.md` |
| .NET MAUI mobile app | mobile UI option in ABP Studio | `maui.md` |
| React Native / Expo mobile app | `-m react-native` | `react-native.md` |
| Server-side UI theming & layout system (MVC + Razor) | — | `theming.md` |

Detect the stack from the target project before generating anything: `Pages/` → Razor Pages,
`Views/` + `Controllers/` → MVC, `angular/package.json` → Angular, `*.Maui/` → MAUI.

---

## Domain layer

| Topic | File | Official docs |
|---|---|---|
| Entities, AggregateRoot, Value Objects | `ddd-domain.md` | https://docs.abp.io/en/abp/latest/Entities |
| Domain Services | `ddd-domain.md` | https://docs.abp.io/en/abp/latest/Domain-Services |
| Value Objects | `ddd-domain.md` | https://docs.abp.io/en/abp/latest/Value-Objects |
| Repositories | `ddd-domain.md` | https://docs.abp.io/en/abp/latest/Repositories |
| Specifications (`Specification<T>`, `.And()/.Or()/.Not()`) | `ddd-domain.md` | https://abp.io/docs/latest/framework/architecture/domain-driven-design/specifications |
| Domain Events & Entity History | `ddd-domain.md` | https://abp.io/docs/latest/framework/infrastructure/event-bus |

## Application layer

| Topic | File | Official docs |
|---|---|---|
| Application Services, DTOs, CRUD, object mapping | `ddd-application.md` | https://docs.abp.io/en/abp/latest/Application-Services |
| Auto API Controllers, API versioning, integration services | `api.md` | https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers |
| Permission definitions & checks | `authorization.md` | https://docs.abp.io/en/abp/latest/Authorization |
| Permission Management module (UI + storage) | `authorization.md` | https://abp.io/docs/latest/modules/permission-management |
| Data seeding | `efcore.md` | https://docs.abp.io/en/abp/latest/Data-Seeding |

## Data access

| Topic | File | Official docs |
|---|---|---|
| EF Core DbContext, repositories, migrations | `efcore.md` | https://docs.abp.io/en/abp/latest/Entity-Framework-Core |
| Connection strings, multiple databases | `connection-strings.md` | https://abp.io/docs/latest/framework/fundamentals/connection-strings |
| Module default database tables & prefixes | `database-tables.md` | https://abp.io/docs/latest/modules/database-tables |

## Infrastructure

| Topic | File | Official docs |
|---|---|---|
| Module system, `DependsOn`, lifecycle hooks | `modules.md` | https://docs.abp.io/en/abp/latest/Module-Development-Basics |
| Options pattern, `Configure<T>`, `PreConfigure` | `options.md` | https://abp.io/docs/latest/framework/fundamentals/options |
| Interceptors, `OnRegistered`, dynamic proxies | `interceptors.md` | https://abp.io/docs/latest/framework/infrastructure/interceptors |
| Settings (`ISettingProvider` / `ISettingManager`) | `settings.md` | https://docs.abp.io/en/abp/latest/Settings |
| Caching (`IDistributedCache<T>`, Redis) | `caching.md` | https://docs.abp.io/en/abp/latest/Caching |
| Background jobs & periodic workers | `background-jobs.md` | https://docs.abp.io/en/abp/latest/Background-Jobs |
| Local event bus, distributed event bus | `event-bus.md` | https://docs.abp.io/en/abp/latest/Local-Event-Bus |
| SignalR real-time hubs | `signalr.md` | https://abp.io/docs/latest/framework/real-time/signalr |
| Localization (`L["Key"]`, `StringLocalizer`, JSON resources) | `localization.md` | https://abp.io/docs/latest/framework/fundamentals/localization |
| Text templating (Scriban / Razor, email templates) | `text-templating.md` | https://abp.io/docs/latest/framework/infrastructure/text-templating/scriban |
| JSON serialization (`IJsonSerializer`) | `json.md` | https://abp.io/docs/latest/framework/infrastructure/json |
| String encryption (`IStringEncryptionService`) | `string-encryption.md` | https://abp.io/docs/latest/framework/infrastructure/string-encryption |
| Image manipulation (`IImageCompressor`, `IImageResizer`) | `image-manipulation.md` | https://abp.io/docs/latest/framework/infrastructure/image-manipulation |
| Timing (`IClock`, timezones) | `timing.md` | https://abp.io/docs/latest/framework/infrastructure/timing |
| Concurrency check (`IHasEntityVersion`) | `concurrency-check.md` | https://abp.io/docs/latest/framework/infrastructure/concurrency-check |
| Data filtering (`ISoftDelete`, `IMultiTenant`, custom filters) | `data-filtering.md` | https://abp.io/docs/latest/framework/infrastructure/data-filtering |
| Object & entity extensions, overriding registered services | `object-extensions.md` | https://abp.io/docs/latest/framework/fundamentals/object-extensions |
| Global features (`IFeatureChecker`-style gating) | `global-features.md` | https://abp.io/docs/latest/framework/infrastructure/global-features |
| Correlation ID propagation | `correlation-id.md` | https://abp.io/docs/latest/framework/infrastructure/correlation-id |

## Multi-tenancy & commercial modules

| Topic | File | Official docs |
|---|---|---|
| Multi-tenancy (`IMustHaveTenant`, per-tenant DBs) | `multi-tenancy.md` | https://docs.abp.io/en/abp/latest/Multi-Tenancy |
| Features system (`IFeatureManager`, feature management UI) | `features.md` | https://abp.io/docs/latest/modules/feature-management |
| OpenIddict module (applications, scopes, token lifetimes) | `openiddict.md` | https://abp.io/docs/latest/modules/openiddict |
| IdentityServer4 → OpenIddict migration | `migration-identityserver-openiddict.md` | https://abp.io/docs/latest/release-info/migration-guides/openiddict-step-by-step |
| CMS Kit (pages, blogs, comments, tags, menus) | `cms-kit.md` | https://abp.io/docs/latest/modules/cms-kit |

## UI — server-side

| Topic | File | Official docs |
|---|---|---|
| Razor Pages UI, page models, modals, JS | `ui-razorpages.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/overall |
| MVC UI: controllers, `_ViewImports`, tag helpers, bundling | `ui-mvc.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/tag-helpers |
| ABP JavaScript API (`abp.ajax`, `abp.modal`, `abp.notify`) | `ui-razorpages.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/javascript-api |
| Data tables / DTLite (theme-dependent) | `ui-razorpages.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/data-tables |
| Navigation & menus (`IMenuContributor`) | `ui-razorpages.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/navigation-menu |
| Toolbars & entity action extensions | `ui-mvc.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/toolbars |
| Bundling, minification, `abp install-libs` | `ui-mvc.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/bundling-minification |
| Forms & validation | `ui-razorpages.md` | https://abp.io/docs/latest/framework/ui/mvc-razor-pages/forms-validation |
| UI theming & layout system | `theming.md` | https://abp.io/docs/latest/ui-themes |

## UI — SPA & mobile

| Topic | File | Official docs |
|---|---|---|
| Angular: proxies, `environment.ts`, guards, theming | `ui-angular.md` | https://abp.io/docs/latest/framework/ui/angular/overview |
| Angular service proxies (`abp generate-proxy -t ng`) | `ui-angular.md` | https://abp.io/docs/latest/framework/ui/angular/service-proxies |
| .NET MAUI: OIDC, `adb reverse`, C# proxies | `maui.md` | https://abp.io/docs/latest/framework/ui/maui |
| React Native / Expo | `react-native.md` | https://abp.io/docs/latest/framework/ui/react-native |

## Tooling, testing & operations

| Topic | File | Official docs |
|---|---|---|
| ABP CLI, startup templates, solution structure | `cli-structure.md` | https://abp.io/docs/latest/cli |
| `abp new` command samples | `cli-structure.md` | https://abp.io/docs/latest/cli/new-command-samples |
| Testing (unit, integration, test fixtures) | `testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Testing |
| Troubleshooting & FAQ | `testing-troubleshooting.md` | https://docs.abp.io/en/abp/latest/Customizing-Application-Modules-Guide |
| Deployment (IIS/K8s, SSL, production config) | `deployment.md` | https://abp.io/docs/latest/deployment |

---

## Coverage not yet written as a reference file

Flag these explicitly instead of improvising, and fetch the doc page:

| Topic | Docs |
|---|---|
| Blazor UI (WebAssembly / Server / Hybrid) | https://abp.io/docs/latest/framework/ui/blazor/overall |
| Microservice solution (RabbitMQ, YARP gateway, outbox/inbox) | https://abp.io/docs/latest/framework/architecture/microservices |
| Blob Storing | https://abp.io/docs/latest/framework/infrastructure/blob-storing |
| Audit logging & security logs | https://abp.io/docs/latest/modules/audit-logging |
| OpenAPI / Swagger generation | https://abp.io/docs/latest/framework/api-development/swagger |
| Recurring background workers | https://abp.io/docs/latest/framework/infrastructure/background-workers |
| Production configuration hardening | https://abp.io/docs/latest/deployment/configuring-production |

If a topic has no verified URL in this file, say so and search https://abp.io/docs/latest — never
guess a URL or an API signature from memory.
