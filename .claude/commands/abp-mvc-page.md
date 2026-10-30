You are an expert ABP Framework developer. Scaffold the **ASP.NET Core MVC UI** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Before that, run **Phase 0** (`abp-dev/references/context-intake.md`): read an existing
`Views/**/Index.cshtml` + its controller + its `.js` and reuse its theme, tag helpers, DataTable and
modal patterns; confirm the app service, DTOs and permission constants you bind to really exist; for a
new look, ask whether the **Stitch MCP** is connected (real screens + design tokens), otherwise the
existing UI is the reference — do not invent a new visual language.

Read `abp-dev/references/ui-mvc.md` and `abp-dev/references/authorization.md` before generating any code.

> **Stack check first.** Detect the project's UI before emitting files:
> `Controllers/` + `Views/` → MVC (this command) · `Pages/**/*.cshtml` → the project uses Razor Pages,
> switch to the `abp-razor-page` command · `angular/package.json` → no C# page code at all; use
> `abp-dev/references/ui-angular.md` (proxy + component + route) · `*.Maui/` → `abp-dev/references/maui.md`.

Assumes `I<Entity>AppService`, `<Entity>Dto`, `CreateUpdate<Entity>Dto` and
`BookStorePermissions.<Entity>s` already exist. Replace `<Entity>` with the PascalCase entity name and
`<entity>` with camelCase.

## What to generate

### 1. `src/Acme.BookStore.Web/Controllers/<Entity>sController.cs`
- Extend `AbpControllerBase`; constructor-inject `I<Entity>AppService`
- `Index()` returns `View()`; `[HttpGet] GetListAsync/GetAsync`, `[HttpPost] CreateAsync`,
  `[HttpPut] UpdateAsync`, `[HttpDelete] DeleteAsync` — each returning the app service result
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on the controller, per-action permissions on the
  mutating actions
- Note in one line that ABP's **auto API controllers** already expose the app service over HTTP, so an
  explicit controller is only needed for view actions or custom routes — check which the project uses

### 2. `src/Acme.BookStore.Web/Views/<Entity>s/Index.cshtml`
- `<abp-card>` with header (title + New button guarded by the Create permission) and
  `<abp-table striped-rows="true" id="<Entity>sTable">`
- `@section Scripts { <abp-script src="/Views/<Entity>s/Index.js" /> }`

### 3. `src/Acme.BookStore.Web/Views/<Entity>s/Index.js`
- `new abp.ModalManager(...)` (or `abp.modal.create`) for create and edit
- `$('#<Entity>sTable').DataTable(abp.libs.datatables.normalizeConfiguration({ serverSide: true, … }))`
- `ajax: abp.libs.datatables.createAjax(acme.bookStore.<entity>s.<entity>.getList)`
- `rowAction` items: Edit (visible if Edit permission), Delete (visible if Delete, with confirm message)
- column defs matching the DTO properties; reload the table after each modal result

### 4. `Views/<Entity>s/CreateModal.cshtml` (+ view model / POST action)
- `<abp-modal>` with `<abp-input asp-for="…">` / `<abp-select>` per DTO property

### 5. `Views/<Entity>s/EditModal.cshtml` (+ GET by id + PUT action)
- Same structure, hidden `Id`

### 6. `Views/<Entity>s/<Entity>sToolbarContributor.cs`
- `IToolbarContributor` adding a "New" button view component to `StandardToolbars.Main`, plus the
  `Configure<AbpToolbarOptions>(options => options.Contributors.Add<<Entity>sToolbarContributor>())`
  registration line

### 7. Menu contributor snippet
Show the `ApplicationMenuItem` block to add to the project's menu contributor (permission-guarded).

### 8. AutoMapper Web profile entry
```csharp
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```

## After generating

Ask whether the localization keys for the page title, menu item and confirmation messages should be
added to the Web layer's `en.json`, and whether an EF Core migration or `dotnet build` should run now.
