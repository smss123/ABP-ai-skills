# ABP Framework — Development Instructions for Claude Code

## Auto-activation

`CLAUDE.md` is loaded into every Claude Code session in this project, so these rules apply
automatically — no prompt needs attaching. Treat the workspace as an ABP project when **any** signal
is present: `Volo.Abp*` package references, `AbpModule` subclasses, `AbpDbContext`, `AggregateRoot` /
`FullAuditedEntity` / `IRepository<,>`, `AbpController` / `AbpPageModel`, `appsettings` containing
`"Abp"` / `"AuthServer"` / `"RemoteServices"`, projects ending in `.Domain.Shared` /
`.Application.Contracts` / `.HttpApi` / `.DbMigrator` / `.EntityFrameworkCore`, or `abp.json` /
`.abp/`. On detection, say one line —
`ABP project detected (signal: …) — running Phase 0 before writing code` — and apply the rules to the
entire task, including bug fixes, refactors and simple questions. If nothing matches, do not inject
ABP patterns. Authoritative signal list: `abp-dev/references/context-intake.md` §0.0.

This repository contains curated ABP Framework skills. When working on any ABP project, always apply the guidance below **before** generating code or advice.

## How to use these instructions

**Step 0 — Context intake (never skip)**, triggered automatically by the detection rule above. Before generating any ABP code, follow
`abp-dev/references/context-intake.md`:

- inspect the **existing code with a knowledge graph** — repo wiki / codebase MCP /
  `Explore`-style search, with Glob+Grep as fallback — and record root namespace, ABP version,
  layers, UI stack, theme, existing entities/services/permissions/DbSets and their conventions;
- read the repo's **plan and design `.md` files** (`docs/`, `plans/`, `specs/`, `DESIGN.md`, ADRs);
  an approved plan overrides your preference — flag a divergence instead of silently diverging;
- for UI work, pick the **design source of truth**: ask the user whether the **Stitch MCP** is
  connected (better UI), otherwise take the **project's existing UI as the reference** and reuse its
  theme, components, markup and JS patterns — never introduce a new visual language;
- **chat before executing**: show the reuse / extend / add summary and open questions, then confirm
  scope (backend only vs UI + migration + seed);
- check **SOLID and ABP design patterns** (repository, specification, aggregate/domain service,
  DTO + mapper, domain events, strategy, interceptor) as the same file tables them.

Then, in order:

1. **Read `abp-dev/references/INDEX.md`** — the single routing table that maps every ABP topic to
   its reference file and its live-verified documentation URL. It also covers which UI stack the
   project uses (MVC / Razor Pages / Angular / Blazor / MAUI / React Native).
2. **Read the reference file(s)** INDEX.md maps the question to.
3. **Fetch the official documentation URL** listed in the same row using the `WebFetch` tool to get
   the latest API details.
4. Synthesise all sources, then generate code.

> If a fetch fails (network unavailable), rely on the reference file and note that the answer is
> based on cached documentation.

Do not work from a remembered list of reference files — the table that used to live in this file was
the reason 24 references were unreachable. `INDEX.md` is authoritative and is updated in one place.

## Detect the UI stack before generating any UI code

| Signal in the target project | Stack | Reference file |
|---|---|---|
| `Pages/**/*.cshtml` | Razor Pages | `abp-dev/references/ui-razorpages.md` |
| `Controllers/` + `Views/` | ASP.NET Core MVC | `abp-dev/references/ui-mvc.md` |
| `angular/package.json` | Angular SPA | `abp-dev/references/ui-angular.md` |
| `**/*.razor` + `Microsoft.AspNetCore.Components*` packages | Blazor (WASM / Server / WebApp) | `abp-dev/references/ui-blazor.md` |
| `*.Maui/` project | .NET MAUI | `abp-dev/references/maui.md` |
| React Native / Expo folder | React Native | `abp-dev/references/react-native.md` |

Angular projects get `abp generate-proxy -t ng` services, never hand-written `HttpClient`; MAUI and
Blazor WASM get C# client proxies (`abp generate-proxy -t csharp`); MVC/Razor share the same tag-helper
and JavaScript API infrastructure; Blazor is `.razor` components, never `.cshtml` pages.

## Core ABP Principles (always apply)

1. **Layered architecture**: Domain → Application → Infrastructure (EF Core) → UI (MVC / Razor Pages / Angular / Blazor / MAUI)
2. **Never expose entities** to the presentation layer — always use DTOs
3. **Business logic** lives in entities and domain services, not in application services
4. **Application services orchestrate** — call domain services/repositories and map to DTOs
5. **Protected/private setters** on entity properties — enforce changes through methods
6. **Always use `IGuidGenerator`** to generate Guid IDs — never call `Guid.NewGuid()` directly
7. **Auto-register services** — ABP discovers `ITransientDependency`, `ISingletonDependency`, `IScopedDependency` automatically
8. **`ConfigureByConvention()`** must always be called in EF Core model configuration
9. **Permissions** are defined in `Application.Contracts`, checked in application services and in
   whichever UI the project uses (Razor Pages / MVC views, Angular `requiredPolicy`, Blazor `AbpAuthorizeView`, MAUI view models)
10. **Reuse before adding** — after Phase 0, extend existing entities, services, permissions and UI
    patterns instead of creating a parallel second set; SOLID over duplication

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
├── Acme.MyApp.Web/                   ← MVC or Razor Pages UI (Views/ vs Pages/)
└── angular/                          ← replaces *.Web when created with `-u angular`; has its own
                                         package.json, and the API is reached over HTTP only
```
