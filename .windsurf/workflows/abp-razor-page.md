---
name: abp-razor-page
description: Scaffold ABP Razor Pages UI — list page, create/edit modals, JavaScript DataTable, and menu item
---

# ABP Razor Pages UI Scaffold

A Windsurf Cascade workflow that creates a complete Razor Pages UI for managing an ABP entity.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Entity properties to show in the list** (e.g. Name, Price, Type)
3. **DTO properties for create/edit form** (usually same as CreateUpdateDto)
4. Have the application service and permissions already been created?

---

## Step 1 — Read reference files

Read:
- `abp-dev/references/ui-razorpages.md`
- `abp-dev/references/authorization.md`

---

## Step 2 — Index page

Create `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml.cs`:
- Extend `AbpPageModel`; `OnGet()` is a no-op (data loaded via AJAX)

Create `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml`:
- ABP card with permission-guarded "New" button and DataTable

---

## Step 3 — Index.js (DataTable + ModalManager)

Create `src/Acme.BookStore.Web/Pages/<Entity>s/Index.js`:
- `abp.ModalManager` for create and edit
- `DataTable` with `serverSide: true`, `createAjax` pointing at the auto-generated JS proxy
- `rowAction` items: Edit (if Edit permission granted), Delete (if Delete permission, with confirm)
- Column defs for the properties chosen in inputs

---

## Step 4 — Create modal

Create `Pages/<Entity>s/CreateModal.cshtml.cs`:
- `[BindProperty] CreateUpdate<Entity>Dto <Entity>` + `OnPostAsync()` calls `CreateAsync`

Create `Pages/<Entity>s/CreateModal.cshtml`:
- `<abp-modal>` with `<abp-input>` / `<abp-select>` per property

---

## Step 5 — Edit modal

Create `Pages/<Entity>s/EditModal.cshtml.cs`:
- `[HiddenInput][BindProperty(SupportsGet = true)] Guid Id`
- `OnGetAsync()` loads and maps entity via ObjectMapper
- `OnPostAsync()` calls `UpdateAsync`

Create `Pages/<Entity>s/EditModal.cshtml`:
- Same structure as Create modal, plus hidden `Id` field

---

## Step 6 — Menu registration

Show the `ApplicationMenuItem` snippet for `BookStoreMenuContributor` and the `AuthorizePage` conventions for the Web module's `ConfigureServices`.

---

## Step 7 — AutoMapper Web profile entry

Show the reverse mapping to add to `BookStoreWebAutoMapperProfile`:
```csharp
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```

---

## Step 8 — Confirm

Ask whether localization keys for the new page labels and menu items should also be added to `en.json`.
