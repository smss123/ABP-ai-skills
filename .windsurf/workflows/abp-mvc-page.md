---
name: abp-mvc-page
description: Scaffold ASP.NET Core MVC UI for an ABP entity — Phase 0 first (existing Views as the visual reference, or Stitch MCP design tokens), then controller, views, DataTable JS, toolbar and menu
---

# ABP MVC UI Scaffold

A Windsurf Cascade workflow that creates a complete ASP.NET Core MVC UI for managing an ABP entity.

> **Stack check first.** `Controllers/` + `Views/` → this workflow · `Pages/**/*.cshtml` → the project
> uses Razor Pages, run `abp-razor-page` instead · `angular/package.json` → no C# UI code, use
> `abp-dev/references/ui-angular.md` · `*.Maui/` → `abp-dev/references/maui.md`.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Columns to show in the list** (e.g. Name, Price, Type)
3. **DTO properties for create/edit** (usually `CreateUpdate<Entity>Dto`)
4. Have the application service and permissions already been created?
5. Does the project already write explicit controllers, or does it rely on ABP **auto API controllers**
   and call the JS proxies directly?

---

## Step 1 — Read reference files

Read:
- `abp-dev/references/context-intake.md` ← Phase 0: read an existing `Views/**/Index.cshtml` + its
  controller + `.js` and reuse its theme, tag helpers, DataTable and modal patterns; verify the app
  service / DTOs / permission constants you bind to exist; for a new look ask whether the **Stitch MCP**
  is connected, otherwise the existing UI is the reference
- `abp-dev/references/ui-mvc.md`
- `abp-dev/references/authorization.md`

---

## Step 2 — Controller

Create `src/Acme.BookStore.Web/Controllers/<Entity>sController.cs`:
- extend `AbpControllerBase`, inject `I<Entity>AppService`
- `Index()` → `View()`; `GetListAsync`, `GetAsync`, `CreateAsync`, `UpdateAsync`, `DeleteAsync`
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on the class, per-action permissions on
  Create/Edit/Delete
- state in one line that ABP already exposes the app service over HTTP via auto API controllers, so this
  exists only for view actions/custom routes

---

## Step 3 — Index view

Create `Views/<Entity>s/Index.cshtml`:
- `<abp-card>` + permission-guarded New `<abp-button>`
- `<abp-table striped-rows="true" id="<Entity>sTable">`
- `@section Scripts { <abp-script src="/Views/<Entity>s/Index.js" /> }`

---

## Step 4 — Index.js (DataTable + modals)

Create `Views/<Entity>s/Index.js`:
- `new abp.ModalManager(...)` for create and edit
- `abp.libs.datatables.normalizeConfiguration({ serverSide: true, ajax:
  abp.libs.datatables.createAjax(acme.bookStore.<entity>s.<entity>.getList) })`
- `rowAction` Edit (if granted) / Delete (if granted, with confirm)
- column defs for the inputs chosen above; reload after every modal result

---

## Step 5 — Create and edit modals

Create `Views/<Entity>s/CreateModal.cshtml` and `EditModal.cshtml` (+ their actions/view models):
- `<abp-modal>` with `<abp-input asp-for="…">` / `<abp-select>` per DTO property
- Edit loads by id and maps `<Entity>Dto → CreateUpdate<Entity>Dto` with `ObjectMapper`

---

## Step 6 — Toolbar contributor

Create `Views/<Entity>s/<Entity>sToolbarContributor.cs` (`IToolbarContributor`) adding the New button
component to `StandardToolbars.Main`, plus the
`Configure<AbpToolbarOptions>(o => o.Contributors.Add<<Entity>sToolbarContributor>())` line.

---

## Step 7 — Menu registration

Show the `ApplicationMenuItem` snippet for the project's menu contributor, guarded by
`BookStorePermissions.<Entity>s.Default`.

---

## Step 8 — AutoMapper Web profile entry

```csharp
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```

---

## Step 9 — Confirm

Ask whether to add the localization keys for the page, menu item and delete confirmation to the Web
layer's `en.json`, and whether to run `dotnet build` now.
