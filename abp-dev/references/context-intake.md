# Phase 0 — Context intake (run before generating any code)

No ABP task starts with code. It starts with four questions answered from evidence:

1. **What already exists?** (codebase + knowledge graph)
2. **What was already decided?** (plan / design documents)
3. **What must the UI look like?** (Stitch, or the project's own UI as the reference)
4. **What does the user actually want?** (a short confirmation chat)

Only after those are answered do you route through `INDEX.md` and generate code. Skipping Phase 0
is what produces a second `ProductManager` next to an existing one, a Lepton-style page in a
Bootstrap project, or a scaffold that contradicts an approved plan.

---

## 0.0 ABP project detection (how the skill activates itself)

This section is the **single source of truth for detection** — `AGENTS.md`, `.windsurfrules`,
`CLAUDE.md`, `.github/copilot-instructions.md`, `.github/instructions/abp.instructions.md` and
`.continue/config.yaml` all point here instead of keeping their own copy.

Treat the workspace as an **ABP project** when **any one** of these signals is present:

| Signal | How to see it |
|---|---|
| `Volo.Abp*` package reference | any `*.csproj` / `Directory.Packages.props` / `*.props` line `PackageReference Include="Volo.Abp…"` |
| An ABP module class | `class … : AbpModule`, `[DependsOn(typeof(…Module))]`, `*.Module.cs` in `src/` |
| ABP app settings | `appsettings*.json` with `"Abp"`, `"AuthServer"`, `"RemoteServices"`, or `__AbpCurrentTenant` keys |
| ABP base types in code | `AbpDbContext`, `AggregateRoot`, `FullAuditedEntity`, `ITransientDependency`, `IRepository<,>`, `AbpController`, `AbpPageModel` |
| ABP solution shape | folders/projects ending in `.Domain.Shared`, `.Application.Contracts`, `.HttpApi`, `.DbMigrator`, `.EntityFrameworkCore`, plus `angular/` |
| ABP tooling | `abp.json`, `abp-template.json`, `.abp` folder, `etc/` from ABP Studio, `abp` CLI in scripts |
| The skill is already installed | an `abp-dev/references/` folder in the project root |

**On detection, activate automatically — do not wait to be asked:**

1. Announce in one line: `ABP project detected (signal: Volo.Abp package refs) — running Phase 0 before writing code.`
2. Load `abp-dev/SKILL.md` + `abp-dev/references/INDEX.md` (and the Phase 0 steps below) as the
   governing conventions for the whole task.
3. Apply the same rules to *any* request touching that project — a "simple" question about an entity,
   a bug fix, a refactor, a UI change — not only to scaffolding prompts.
4. If **no** signal matches, say so and answer as ordinary ASP.NET Core / the project's own stack; do
   not inject ABP patterns into a non-ABP codebase.

Detection runs again per session — a repo can gain the signals (e.g. ABP added mid-task), and a
subdirectory may be a separate non-ABP service inside an ABP solution.

---

## 0.1 Read the existing code through a knowledge graph

Use the code-intelligence layer available in the current harness, in this priority order:

| Available capability | Use it to get |
|---|---|
| Repo Wiki / knowledge-center MCP (`list_knowledge`, `read_knowledge`) | module breakdown, per-module architecture, conventions |
| A codebase graph MCP (`search_graph`, `trace_path`, `get_code_snippet`, `get_architecture`, `check_index_coverage`) | symbol lookup, call chains, exact source for a class |
| Workspace semantic search (`SearchWorkspace` / Copilot `#codebase` / Cascade `@Codebase`) | broad "where is X handled" answers across layers |
| Plain tools (Glob / Grep / Read) | the fallback when no graph is indexed — and always for verifying a specific file |

> If no graph exists for the target repo, say so and index it (generate the repo wiki / knowledge
> cards, or run the indexer the harness provides). Never present graph-derived claims as facts when
> the graph was empty — that is when hallucinated symbols appear.

### Minimum map to build for an ABP solution

Derive all of this from the repo — never assume it:

| Fact | Where to read it |
|---|---|
| Root namespace / project prefix (`Acme.BookStore`) | `*.sln`, `*.csproj` `<RootNamespace>` |
| ABP version | any `*.csproj` `Volo.Abp.*` `PackageReference` version, or `Directory.Packages.props` |
| Layers actually present (single module vs microservice) | solution folder list; presence of `*.HttpApi.Host`, `*.MongoDB`, `etc/` |
| UI stack(s) | see the stack table in `abp-dev/SKILL.md` (`Pages/`, `Views/`+`Controllers/`, `angular/`, `*.Maui/`) |
| Theme in use | `*.Web/csproj` → `LeptonX`, `LeptonLite`, or a custom theme package; `_ViewImports.cshtml` |
| Existing entities + aggregates | `*.Domain/` — `: ABPEntity`, `AggregateRoot`, `FullAuditedAggregateRoot` |
| Existing app services & DTOs | `*.Application/` and `*.Application.Contracts/` |
| Existing permission constants | `*Permissions.cs` + `PermissionDefinitionProvider` |
| DbContext & model config | `*.EntityFrameworkCore/` — `DbSet`s, `OnModelCreating`, `ConfigureByConvention()` |
| Conventions to copy (naming, mapping, localization keys) | 2–3 existing files in each layer closest to the new feature |
| Existing tests | `*.Tests/`, `*.TestBase/` — tells you the fixture style to follow |

Then answer explicitly, in one short table shown to the user:

- **reuses** what exists (which entity, service, permission group, CSS class, component)
- **extends** what exists (which file gets a new member)
- **adds** only what is genuinely new

Conflict rule: if a symbol with the target name already exists, do not create a second one — either
extend the existing one or rename the new one and tell the user why.

---

## 0.2 Read the plan and design documents

Search for markdown/text planning artefacts before writing anything of your own:

```
*.md at the repo root          README.md, DESIGN.md, ARCHITECTURE.md, CHANGELOG.md
docs/**  documentation/**      specs, ADRs, domain docs
plans/**  .plans/**  todos.md   task plans, implementation checklists
spec/**  openspec/**  .specify/**  spec-driven-development artefacts
.aider/**  .cursor/**  .kiro/**/specs  other assistant plan folders
**/*.story.md  **/*.prd.md  **/requirements*.md
```

For each file found, extract only what constrains the code:

- decided domain model, bounded contexts, aggregate boundaries
- naming, layering, and mapping conventions the team already agreed on
- explicit "do not" rules and non-goals
- phase/task checklists already marked done or pending
- acceptance criteria you must satisfy

Rules:

- An approved plan **overrides** your preference. Follow it, or flag the deviation in one line
  ("plan says X, I recommend Y because Z") and ask before diverging.
- Never overwrite a plan as a side effect of coding. Update it only when asked, or append a short
  "implemented" note.
- If a plan exists and its file paths disagree with the real repo, the repo wins — say so.
- If no plan documents exist, state that explicitly instead of silently inventing one.

---

## 0.3 UI source of truth (only when UI is in scope)

Pick exactly one, in this priority order, and record which one you used:

### A. Stitch MCP — preferred for new or redesigned screens

Ask the user for permission before relying on it:

> "For the UI I can use Stitch (Google's design MCP) to pull the actual screens, tokens, and
> component specs — that gives a much closer match to your design than guessing. Do you have the
> Stitch MCP connected for this workspace? If not, I'll follow your existing UI instead."

If connected:

1. list the project / screens from Stitch,
2. read the selected screen's spec (layout, components, spacing, colors, typography, states),
3. export or read design tokens,
4. map each design element onto what ABP already provides before hand-writing anything —
   ABP tag helpers, components and `abp.ModalManager` / `abp.DataTable` patterns come from
   `ui-razorpages.md`, `ui-mvc.md` or `ui-angular.md`,
5. implement the design in the project's own stack, not in a new framework.

If not connected: do not stall and do not invent a design system. Offer to proceed with option B and
move on.

### B. The existing UI is the reference (default)

Extract the visual language from real files, then reuse it:

| Extract | From |
|---|---|
| Theme + layout | `*.Web` `csproj` theme package, `_ViewImports.cshtml`, `_Layout.cshtml`, `Themes/` |
| Colour, spacing, typography tokens | `wwwroot/css/`, brand/theme overrides, `:root { --... }` custom properties, Tailwind/config if present |
| Card / table / modal markup | an existing `Pages/**/Index.cshtml` or `Views/**` screen of the same kind |
| Data-table & modal JS pattern | an existing `*.js` next to that page (`abp.ModalManager`, DataTable init) |
| Menu entries | the existing `*MenuContributor` |
| Localization keys | `*.Domain.Shared/Localization/en.json` structure and casing |
| Angular components | existing `shared/` components, `@abp/ng.*` usage, `config.json` routes |

Copy the closest existing screen and change the domain, not the framework:

- existing page uses `<abp-card>` → new page uses `<abp-card>`
- existing page uses a `createModal` via `abp.ModalManager` → same pattern
- existing grid is a DataTable with `columnData` → same shape, new columns
- do not add a CSS framework, icon set, font, or component library the project does not already use
- do not add per-page magic colours; reuse the tokens found above

### C. No UI at all in the project

Ask which stack the user wants (`-u mvc` / `-u razor` / `-u angular` / MAUI) before generating any
UI file, then follow that stack's reference file. If they only need an API, stop at Phase 4.

State the chosen source in one line before writing UI code, e.g.
`UI source: existing Razor Pages + LeptonX tokens (Stitch not connected)`.

---

## 0.4 Confirm with the user before executing

Show a compact intake summary — not a wall of text:

```
Existing code   : namespace Acme.BookStore, ABP 10.3, Razor Pages + LeptonX,
                  entities Book/Author exist, BookManager + IBookRepository exist,
                  Book permissions exist (Create/Edit/Delete)
Plans           : docs/plans/catalog-v2.md — phase 3 open, says "soft-delete books"
UI source       : existing Razor Pages markup + tokens (Stitch not connected)
Reuse / Extend  : extend Book + BookManager; reuse permission group "Catalog"
New             : Category entity, ICategoryRepository, CategoryDto, CategoryAppService,
                  Category page + modals, EF migration, seed contributor
Design          : Category 1—* Book (aggregate boundary stays at Book), SRP: no logic in the page
Open questions  : 1) Category unique by Name or Name+TenantId? 2) Migrate existing books?
```

Then ask two things and wait:

1. **"Is this scope right — reuse/extend/add anything to change?"**
2. **"Which phases do you want — backend only, or through UI + seed + migration?"**

Rules:
- Never run a migration, delete data, or edit `appsettings.json` secrets without explicit approval.
- Never begin Phase 1 while an open question changes the domain model.
- If the user gives a complete answer, proceed — do not re-ask what they already stated.

---

## 0.5 SOLID and design patterns as ABP layer rules

Phase 0 ends with an explicit design check. Each principle maps onto a concrete ABP rule:

| Principle | ABP implementation | Breaks when |
|---|---|---|
| **S**ingle Responsibility | one aggregate, one domain service per aggregate invariant, one app service per use case; page models only orchestrate | an app service mixing authorization, mapping and business rules |
| **O**pen/Closed | domain events + handlers, `ObjectExtensionManager`, interceptors, strategy services resolved from DI, virtual methods on entities | editing a shared handler with another `if (type == X)` |
| **L**iskov Substitution | depend on `IRepository<T>`, `IStringLocalizer<T>` etc.; a replacement keeps the same contract and semantics | a derived service throwing `NotImplementedException` or changing behaviour |
| **I**nterface Segregation | a `*Application.Contracts` interface per bounded use case; split `IXxxAppService` rather than growing it | DTOs/interfaces carrying fields one caller never uses |
| **D**ependency Inversion | domain layer declares the repository interface; EF Core implements it; consumers take `ITransientDependency` abstractions | `*.Domain` referencing EF Core, `DbContext` injected into a domain service |

Patterns to apply, in the ABP-native form:

- **Repository** — `IRepository<TEntity, TKey>`; query logic stays in the domain/app layer, not the page.
- **Specification** — `Specification<T>` + `.And()/.Or()/.Not()` for filterable queries (`ddd-domain.md`).
- **Aggregate root / domain service** — invariants enforced in the domain; `IGuidGenerator` for ids.
- **DTO + mapper** — never return entities; AutoMapper/AutoMapping profiles in `*.Application`.
- **Unit of Work** — rely on ABP's UoW at the app-service boundary; `autoSave` only in seed contributors.
- **Domain events** — local event bus for in-process reactions, distributed bus across services.
- **Factory / constructor** — static factory or named constructor on the entity for valid creation.
- **Strategy via DI** — multiple implementations resolved by key when behaviour branches.
- **Decorator / interceptor** — `AbpInterceptor` or `ReplaceService` instead of editing a framework service.
- **Composite menu/toolbar contributors** — extend `IMenuContributor` for new navigation.

State in the confirmation message, in one line, which of these the design uses and any principle you
are knowingly trading off.

---

## Anti-patterns that mean Phase 0 was skipped

- a duplicate `XxxManager` / `XxxAppService` / permission constant beside the existing one
- new entity inheriting a base class that the rest of the project does not use
- `Pages/` files added to an MVC solution, or Angular components added to `*.Web`
- a new CSS framework, colour, font, or component library nobody asked for
- a scaffold that contradicts `docs/` or the plan file the user pointed at
- generating a migration before confirming data-loss impact
- inventing a file path, namespace, or ABP API that does not exist in the installed version
