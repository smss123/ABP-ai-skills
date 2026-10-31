---
description: ABP Framework — auto-attached whenever a C#, Razor, project or settings file from an ABP solution is in context
applyTo: "**/*.cs,**/*.csproj,**/*.props,**/*.cshtml,**/*.razor,**/*.js,**/appsettings*.json,**/*.sln"
---

# ABP project detected — activate automatically

Apply these rules for the **whole task**, not only for scaffolding requests. Bug fixes, refactors,
UI tweaks and "simple" ABP questions are covered too.

Detection signals (any one is enough; authoritative list in `abp-dev/references/context-intake.md`):
`Volo.Abp*` package references, `AbpModule` subclasses / `[DependsOn(typeof(…))]`, `AbpDbContext`,
`AggregateRoot` / `FullAuditedEntity` / `IRepository<,>`, `AbpController` / `AbpPageModel`, `appsettings`
with `"Abp"` / `"AuthServer"` / `"RemoteServices"`, projects ending in `.Domain.Shared` /
`.Application.Contracts` / `.HttpApi` / `.DbMigrator` / `.EntityFrameworkCore`, or `abp.json` / `.abp/`.

Say one line when it activates — `ABP project detected (signal: …) — running Phase 0 before writing code` —
then follow the order below. If none of the signals match, do not inject ABP patterns.

## Phase 0 — context intake (mandatory, before generating anything)

1. **Existing code** — map it with `#codebase` (or a connected code-graph / repo-wiki MCP, Grep+Read
   as fallback): root namespace, ABP version from `*.csproj`, layers, UI stack, theme package,
   existing entities, domain services, app services, DTOs, permission constants, `DbSet`s and the
   conventions those files actually use. Never assume a symbol exists.
2. **Plan documents** — read `README.md`, `DESIGN.md`, `docs/**`, `plans/**`, `specs/**`,
   `openspec/**` and ADRs. An approved plan overrides your preference; flag deviations and ask.
3. **UI source of truth** — ask whether the **Stitch MCP** is connected (real screens + design
   tokens). Otherwise reuse the project's existing pages/components as the reference: same theme,
   tag helpers, `abp.ModalManager`, DataTable, menu contributor, localization keys. No new CSS
   framework, palette, font or component library.
4. **Confirm scope** — present a reuse / extend / add summary with open questions and ask which
   phases are wanted (backend only vs UI + seed + migration) before writing files.
5. **Design check** — SOLID in ABP form plus the native patterns: repository, specification,
   aggregate + domain service, DTO and mapper, domain events, strategy via DI, interceptor.

## Then route, never guess

`abp-dev/references/INDEX.md` → the reference file it names → fetch the documentation URL in that row
→ only then generate. If a fetch fails, state that the answer is based on the cached reference file.
Never invent an ABP API or documentation URL from memory.

## Non-negotiable ABP rules

- Domain → Application → Infrastructure (EF Core) → UI; business logic stays in the domain layer.
- Entities never reach the UI; map with `ObjectMapper.Map<>()`.
- `IGuidGenerator` instead of `Guid.NewGuid()`; `ConfigureByConvention()` in every EF Core model config.
- Permissions live in `Application.Contracts` and are enforced with `[Authorize]` in app services and in
  whichever UI the project uses (Razor Pages / MVC views, Angular `requiredPolicy`, Blazor `AbpAuthorizeView`, MAUI view models).
- Detect the UI stack before writing UI code: `Pages/` → Razor Pages · `Views/` + `Controllers/` → MVC ·
  `angular/package.json` → Angular (generated proxies, no C# page code) · `**/*.razor` with
  `Microsoft.AspNetCore.Components*` packages → Blazor · `*.Maui/` → MAUI · Expo folder → React Native.
- Reuse before adding: extend the existing entity, service, permission group or page pattern rather than
  creating a parallel second one.
