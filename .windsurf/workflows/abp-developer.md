---
name: abp-developer
description: General ABP developer workflow — Phase 0 context intake (existing code, plan docs, UI source of truth, scope confirmation, SOLID check), then implement the change across the correct ABP layers
---

# ABP Developer

A Windsurf Cascade workflow for the work that is not a single-layer scaffold: extend a feature, fix a
bug, refactor a service, wire something into settings/tenancy/event bus.

For a whole feature from one sentence run `abp-super`; for one layer in isolation use the dedicated
workflow (`abp-entity`, `abp-domain-service`, `abp-repository`, `abp-app-service`, `abp-permissions`,
`abp-razor-page`, `abp-mvc-page`, `abp-angular-feature`, `abp-theming`).

## Step 1 — Detect the stack

`Pages/**/*.cshtml` → Razor Pages · `Controllers/` + `Views/` → MVC · `angular/package.json` → Angular
(no C# page code) · `**/*.razor` with `Microsoft.AspNetCore.Components*` packages → Blazor ·
`*.Maui/` → MAUI · Expo/React Native folder → React Native.

## Step 2 — Phase 0 (mandatory, even for bug fixes)

Read `abp-dev/references/context-intake.md` and run it:
1. **Existing code** — map the solution through a code graph (`@Codebase`, RepoWiki, graph MCP; file
   search as fallback): root namespace, ABP version, layers, UI stack, theme package, and every existing
   entity, domain service, application service, DTO, permission constant and `DbSet` plus their
   conventions. Never assume a symbol exists — read it.
2. **Plans** — read `README.md`, `DESIGN.md`, `docs/`, `plans/`, `specs/`, `openspec/`, ADRs. An approved
   plan overrides your preference; flag a deviation and ask.
3. **UI source of truth** — ask whether the **Stitch MCP** is connected (real screens + design tokens).
   If not, the project's existing UI is the reference: reuse its theme, components, markup and JS;
   introduce no new CSS framework, palette, font or component library.
4. **Confirm** — show a reuse / extend / add summary with open questions and confirm scope (backend only
   vs UI + seed + migration).
5. **Design check** — SOLID in ABP form plus repository, specification, aggregate/domain service,
   DTO + mapper, domain events, strategy-via-DI, interceptor.

## Step 3 — Route, never guess

Read `abp-dev/references/INDEX.md`, open the reference file(s) it names, fetch the documentation URL in
the same row, then synthesise. If the network is unavailable, say the answer is based on the cached
reference file.

## Step 4 — Implement under these rules

1. Layers: Domain → Application.Contracts → Application → EntityFrameworkCore → UI; business logic in
   entities and domain services.
2. Entities never reach the UI — `ObjectMapper.Map<>()` to DTOs.
3. Protected/private setters; state changes through entity methods.
4. `IGuidGenerator` / `GuidGenerator.Create()` — never `Guid.NewGuid()`.
5. `ConfigureByConvention()` in every EF Core model configuration.
6. Permissions in `Application.Contracts`, enforced in app services and in the UI stack in use.
7. `BusinessException` / `UserFriendlyException` for rule violations, never raw exceptions.
8. Reuse before adding — extend the existing entity/service/permission group/page.

## Step 5 — Verify and report

`dotnet build`, run the tests covering the change, report the result and list the files touched.
