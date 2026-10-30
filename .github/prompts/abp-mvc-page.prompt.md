---
mode: 'agent'
description: 'Scaffold an ASP.NET Core MVC UI for an ABP entity — Phase 0 first (existing Views as the visual reference, or Stitch MCP design tokens), then controller, views, DataTable JavaScript, toolbar and menu item'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold the **ASP.NET Core MVC UI** for the entity the user
names — controller, Razor views, DataTable JavaScript, toolbar and menu registration.

> **Stack check first.** `Controllers/` + `Views/` → this prompt. `Pages/**/*.cshtml` → the project uses
> Razor Pages, use `abp-razor-page` instead. `angular/package.json` → no C# UI code at all, use
> `abp-angular-feature`. `*.Maui/` → `abp-dev/references/maui.md`.

## Before generating any code

0. **Phase 0 — look at the real project first** (`abp-dev/references/context-intake.md`): read an existing
   `Views/<Something>/Index.cshtml` + its controller and `.js` and reuse its theme, tag helpers,
   DataTable and modal patterns; confirm the app service, DTOs and permission constants you bind to
   actually exist; for a new look, ask whether the **Stitch MCP** is connected (real screens + design
   tokens) — otherwise the existing UI is the reference and you do not invent a visual language.
1. Read `abp-dev/references/ui-mvc.md` and `abp-dev/references/authorization.md`.
2. Fetch the documentation URL that `abp-dev/references/INDEX.md` lists for the MVC UI row.
3. Only then write code.

Assumes `I<Entity>AppService`, `<Entity>Dto`, `CreateUpdate<Entity>Dto` and
`BookStorePermissions.<Entity>s` already exist. Replace `<Entity>` with the PascalCase entity name and
`<entity>` with camelCase.

## Files to create

### 1. `src/Acme.BookStore.Web/Controllers/<Entity>sController.cs`
```csharp
using System.Threading.Tasks;
using Acme.BookStore.<Entity>s;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc;

namespace Acme.BookStore.Web.Controllers;

[Route("app/<entity>s")]
public class <Entity>sController : AbpControllerBase
{
    private readonly I<Entity>AppService _<entity>AppService;

    public <Entity>sController(I<Entity>AppService <entity>AppService)
        => _<entity>AppService = <entity>AppService;

    public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> GetListAsync(Get<Entity>sInput input)
        => Ok(await _<entity>AppService.GetListAsync(input));

    [HttpGet]
    public async Task<IActionResult> GetAsync(Guid id)
        => Ok(await _<entity>AppService.GetAsync(id));

    [HttpPost]
    public async Task<IActionResult> CreateAsync(CreateUpdate<Entity>Dto input)
    {
        await _<entity>AppService.CreateAsync(input);
        return NoContent();
    }

    [HttpPut]
    public async Task<IActionResult> UpdateAsync(Guid id, CreateUpdate<Entity>Dto input)
    {
        await _<entity>AppService.UpdateAsync(id, input);
        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteAsync(Guid id)
    {
        await _<entity>AppService.DeleteAsync(id);
        return NoContent();
    }
}
```
ABP also exposes the app service over HTTP automatically (auto API controllers), so the JavaScript
below can call the service proxy directly — the controller above is only needed when you want explicit
routes or view-specific actions. Say which of the two the project already uses before adding one.

### 2. `src/Acme.BookStore.Web/Views/<Entity>s/Index.cshtml`
- `<abp-card>` with a header (title + New button guarded by the Create permission) and an
  `<abp-table striped-rows="true" id="<Entity>sTable">` body
- `@section Scripts { <abp-script src="/Views/<Entity>s/Index.js" /> }`

### 3. `src/Acme.BookStore.Web/Views/<Entity>s/Index.js`
- `abp.modal.create` / `new abp.ModalManager(...)` for create and edit
- `$('#<Entity>sTable').DataTable(abp.libs.datatables.normalizeConfiguration({...}))` with
  `serverSide: true` and `ajax: abp.libs.datatables.createAjax(acme.bookStore.<entity>s.<entity>.getList)`
- `rowAction` items Edit / Delete, each with `visible: abp.auth.isGranted('BookStore.<Entity>s.Edit')`
- column defs matching the DTO properties; reload the table after every modal result

### 4. Create / Edit modals
`Views/<Entity>s/CreateModal.cshtml` + `EditModal.cshtml` (and their view models) using
`<abp-modal>` with `<abp-input asp-for="...">` per DTO property, posted through `abp.ajax`.
Reuse the project's existing modal markup rather than introducing a new pattern.

### 5. Toolbar and menu
```csharp
// Views/<Entity>s/<Entity>sToolbarContributor.cs
public class <Entity>sToolbarContributor : IToolbarContributor
{
    public Task ConfigureToolbarAsync(IToolbarConfigurationContext context)
    {
        if (context.Toolbar.Name != StandardToolbars.Main) return Task.CompletedTask;
        context.Toolbar.Items.Add(new ToolbarItem(typeof(New<Entity>ButtonComponent)));
        return Task.CompletedTask;
    }
}
```
Show the `ApplicationMenuItem` block for the project's menu contributor, the toolbar contributor
registration, and the `[Authorize(BookStorePermissions.<Entity>s.Default)]` attribute on the controller.

### 6. AutoMapper Web profile
```csharp
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```

## After generating

Ask whether the localization keys for the page title, menu item and confirmation messages should be
added to the `*.Web` `Localizer` resources (`en.json`) now.
