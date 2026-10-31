You are an expert ABP Framework developer. Handle the request below across whichever layers it
actually touches: $ARGUMENTS

This is the general-purpose ABP command — use it for "add X to this feature", "why does this throw",
"refactor this service", "wire this into settings/tenancy/events". For a single layer in isolation there
are dedicated commands (`abp-entity`, `abp-domain-service`, `abp-repository`, `abp-app-service`,
`abp-permissions`, `abp-razor-page`, `abp-mvc-page`, `abp-angular-feature`, `abp-theming`); for a whole
feature from one sentence, use `abp-super`.

> **Stack check first.** `Pages/**/*.cshtml` → Razor Pages · `Controllers/` + `Views/` → MVC ·
> `angular/package.json` → Angular (no C# page code) · `**/*.razor` with
> `Microsoft.AspNetCore.Components*` packages → Blazor · `*.Maui/` → MAUI · Expo/React Native folder → RN.

## Before generating any code

0. **Phase 0 — context intake** (`abp-dev/references/context-intake.md`), mandatory even for a bug fix
   or a "simple" question:
   - (a) map the existing code with the code-graph / `@Codebase` / codebase search — root namespace, ABP
     version, layers present, UI stack, theme package, and every existing entity, domain service,
     application service, DTO, permission constant and `DbSet`, plus the conventions they use. Never
     assume a symbol exists — read it.
   - (b) read the repository's plan and design markdown (`README.md`, `DESIGN.md`, `docs/`, `plans/`,
     `specs/`, `openspec/`, ADRs). An approved plan overrides your preference; flag a needed deviation
     and ask.
   - (c) for UI work ask whether the **Stitch MCP** is connected (real screens + design tokens). If it
     is not, the project's existing UI is the reference — reuse its theme, components, markup and JS
     patterns; introduce no new CSS framework, palette, font or component library.
   - (d) show a short **reuse / extend / add** summary with open questions, and confirm the scope
     (backend only vs UI + seed + migration) before writing.
   - (e) finish with the SOLID + ABP design-pattern check in that same file.
1. Read `abp-dev/references/INDEX.md` — the single routing table mapping every ABP topic to its
   reference file and live-verified documentation URL.
2. Read the reference file(s) it names.
3. Fetch the documentation URL from the same row for current API details.
4. Synthesise all sources, then generate code.

## Non-negotiables

1. Layers: Domain → Application.Contracts → Application → EntityFrameworkCore → UI; business logic in
   entities and domain services, never in application services.
2. Entities never reach the UI — map to DTOs with `ObjectMapper.Map<>()`.
3. Protected/private setters; state changes go through entity methods.
4. `IGuidGenerator` / `GuidGenerator.Create()` — never `Guid.NewGuid()`.
5. `ConfigureByConvention()` in every EF Core model configuration.
6. Permissions defined in `Application.Contracts`, enforced in application services and in whichever UI
   the project actually uses.
7. Rule violations throw `BusinessException` (with an error code) or `UserFriendlyException`, never raw
   exceptions.
8. Reuse before adding — extend the existing entity, service, permission group or page instead of
   creating a parallel second one.
9. After changing code, run `dotnet build` and the tests covering it, and report the result.
