# AGENTS.md — always-on rules for AI coding agents in this project

> **This file is loaded automatically** by agents that follow the open `AGENTS.md` convention
> (GitHub Copilot coding agent, Codex, Cursor, Zed, Amp, Jules, Qoder and others). Nothing needs to
> be attached or invoked — if the workspace is an ABP project, these rules apply to every task.
>
> Not to be confused with `AGENT.md` (singular) in this repository, which documents how to
> *install* the skills. This file is what runs inside a project.

## 1. Detect the framework, then activate

Look for **any one** of these ABP signals before doing anything else:

- `PackageReference Include="Volo.Abp…"` in any `*.csproj` / `Directory.Packages.props`
- a class deriving from `AbpModule`, or `[DependsOn(typeof(…Module))]`
- `AbpDbContext`, `AggregateRoot`, `FullAuditedEntity`, `IRepository<,>`, `AbpController`, `AbpPageModel`, `ITransientDependency`
- `appsettings*.json` containing `"Abp"`, `"AuthServer"` or `"RemoteServices"`
- projects ending in `.Domain.Shared`, `.Application.Contracts`, `.HttpApi`, `.DbMigrator`, `.EntityFrameworkCore` (± an `angular/` folder)
- `abp.json` / `abp-template.json` / `.abp/` / ABP Studio `etc/`

**If found:** state it in one line (`ABP project detected (signal: …) — running Phase 0 before writing code`), then
apply [abp-dev/SKILL.md](abp-dev/SKILL.md) and [abp-dev/references/INDEX.md](abp-dev/references/INDEX.md)
as the governing conventions **for the entire task** — including bug fixes, refactors and "simple"
questions, not just scaffolding requests.

**If not found:** do not inject ABP patterns; work with the project's actual stack. Re-detect if ABP
is added during the session or if the target folder is a separate non-ABP service.

The authoritative signal list, its edge cases and the full intake procedure live in
[abp-dev/references/context-intake.md](abp-dev/references/context-intake.md) — update that file,
not the copies here.

## 2. Phase 0 — context intake, before any code is generated

1. **Existing code**: read it through a knowledge graph (repo wiki / code-graph MCP / codebase
   search, with file search as fallback) and map root namespace, ABP version, layers, UI stack,
   theme package, and every existing entity, domain service, app service, DTO, permission constant
   and `DbSet` plus the conventions they use. Never assume a symbol exists.
2. **Plans**: read the repository's plan and design markdown (`README.md`, `DESIGN.md`, `docs/`,
   `plans/`, `specs/`, `openspec/`, ADRs). An approved plan overrides your preference — flag a
   needed deviation and ask.
3. **UI source of truth**: ask whether the **Stitch MCP** is connected (real screens + design
   tokens). If not, take the project's **existing UI as the reference** and reuse its theme,
   components, markup and JS patterns. Never introduce a CSS framework, palette, font or component
   library the project does not already use.
4. **Confirm**: show what will be reused, extended and added, list open questions, and confirm the
   phase scope (backend only vs UI + seed + migration) before generating.
5. **Design check**: SOLID in ABP form plus the native patterns — repository, specification,
   aggregate/domain service, DTO + mapper, domain events, strategy via DI, interceptor.

## 3. Then route, never guess

Read `abp-dev/references/INDEX.md`, open the reference file(s) it names, fetch the documentation URL
in the same row, and only then write code. If the network is unavailable, say the answer is based on
the cached reference file. Never invent an ABP class, member or URL from memory.

## 4. Non-negotiable ABP rules

- Layers: Domain → Application → Infrastructure (EF Core) → UI; business logic in the domain layer.
- Entities never reach the UI — map to DTOs with `ObjectMapper.Map<>()`.
- `IGuidGenerator` instead of `Guid.NewGuid()`; `ConfigureByConvention()` in every EF Core model config.
- Permissions in `Application.Contracts`, enforced with `[Authorize]` in app services and in the UI stack the project actually uses.
- Detect the UI stack before writing UI code: `Pages/` → Razor Pages, `Views/` + `Controllers/` → MVC,
  `angular/package.json` → Angular (proxies, no C# page code), `**/*.razor` with
  `Microsoft.AspNetCore.Components*` packages → Blazor, `*.Maui/` → MAUI, Expo/React Native folder → RN.
- Reuse before adding: extend the existing entity, service, permission group or page pattern instead
  of creating a parallel second one.
