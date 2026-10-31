You are an expert ABP Framework developer. Scaffold **Razor Pages UI** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Before that, run **Phase 0** (`abp-dev/references/context-intake.md`): read an existing
`Pages/**/Index.cshtml` + its `.js` and reuse its theme, tag helpers, DataTable and `abp.ModalManager`
patterns; confirm the app service, DTOs and permission constants you bind to really exist; for a new
look, ask whether the **Stitch MCP** is connected (real screens + design tokens), otherwise the
existing UI is the reference — do not invent a new visual language.

Read `abp-dev/references/ui-razorpages.md` and `abp-dev/references/authorization.md` before generating any code.

> **Stack check first.** Detect the project's UI before emitting files:
> `Pages/**/*.cshtml` → Razor Pages (this command) · `Controllers/` + `Views/` → generate MVC
> controller + views instead, per `abp-dev/references/ui-mvc.md` · `angular/package.json` → no C#
> page code at all; use `abp-dev/references/ui-angular.md` (proxy + component + route) ·
> `*.Maui/` → `abp-dev/references/maui.md` (ViewModel + C# client proxy) · `**/*.razor` with
> `Microsoft.AspNetCore.Components*` packages → `abp-dev/references/ui-blazor.md` (`.razor`
> components, never `.cshtml` pages).

Assumes the application service (`I<Entity>AppService`) and permissions (`BookStorePermissions.<Entity>s`) already exist.

## What to generate

### 1. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml.cs`
- Extend `AbpPageModel`; `OnGet()` is a no-op (data loaded via AJAX DataTable)

### 2. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml`
- ABP card with header (title + New button guarded by Create permission) and DataTable body
- `@section scripts` loading `Index.js`

### 3. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.js`
- `abp.ModalManager` for create and edit modals
- `$('#<Entity>sTable').DataTable(...)` with `serverSide: true`
- `ajax: abp.libs.datatables.createAjax(acme.bookStore.<entity>s.<entity>.getList)`
- `rowAction` items: Edit (visible if Edit permission), Delete (visible if Delete permission, with confirm)
- Column defs matching entity properties
- `createModal.onResult` / `editModal.onResult` to reload the table

### 4. `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml.cs`
- `[BindProperty] CreateUpdate<Entity>Dto <Entity>`
- `OnGet()` → no-op
- `OnPostAsync()` → calls `_<entity>AppService.CreateAsync(<Entity>)`, returns `NoContent()`

### 5. `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml`
- `<abp-modal>` with form containing `abp-input` / `abp-select` for each DTO property

### 6. `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml.cs`
- `[HiddenInput][BindProperty(SupportsGet = true)] Guid Id`
- `[BindProperty] CreateUpdate<Entity>Dto <Entity>`
- `OnGetAsync()` → loads entity via `GetAsync(Id)`, maps `<Entity>Dto → CreateUpdate<Entity>Dto` via `ObjectMapper`
- `OnPostAsync()` → calls `UpdateAsync(Id, <Entity>)`, returns `NoContent()`

### 7. `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml`
- Same modal structure as CreateModal, but includes hidden `Id` input

### 8. Menu contributor snippet
Show the `ApplicationMenuItem` block to add to `BookStoreMenuContributor` and the `AuthorizePage` conventions for the Web module.

### 9. AutoMapper reverse mapping for Edit modal
```csharp
// In BookStoreWebAutoMapperProfile:
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```

## After generating

Ask the user whether they need localization keys added to `en.json` for the new page labels and menu items.
