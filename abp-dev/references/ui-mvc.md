---
applies_to_abp: "10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/overall
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/tag-helpers
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/javascript-api
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/modals
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/data-tables
  - https://abp.io/docs/latest/framework/ui/mvc-razor-pages/navigation-menu
---

# ABP: ASP.NET Core MVC UI

> 📖 Official docs (verified live against ABP 10.x):
>
> - MVC & Razor Pages UI overview: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/overall
> - Tag helpers: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/tag-helpers
> - JavaScript API: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/javascript-api
> - Modals: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/modals
> - Data tables: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/data-tables
> - Navigation & menus: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/navigation-menu
> - Toolbars: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/toolbars
> - Entity action extensions: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/entity-action-extensions
> - Bundling & minification: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/bundling-minification
> - Client-side package management: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/client-side-package-management
> - Forms & validation: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/forms-validation
> - Static JS proxies: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/static-javascript-proxies
> - Dynamic JS proxies: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/dynamic-javascript-proxies
> - Theming: https://abp.io/docs/latest/framework/ui/mvc-razor-pages/theming
>
> Fetch the relevant page before generating MVC code — tag-helper and data-table APIs are the parts
> most likely to have changed between ABP versions.

---

## MVC or Razor Pages?

ABP supports both server-side UIs, and they share the *same* infrastructure (tag helpers, JavaScript
API, navigation, theming, bundling, client-side package management). The official guidance is:

- **Razor Pages** for application UI pages → use `references/ui-razorpages.md`
- **MVC** for hand-written HTTP API controllers, and for teams that prefer controllers/views

If the user did not choose explicitly, `abp new <name> -u mvc` and `-u razor` both produce a `*.Web`
project — check the existing project's folder (`Controllers/` + `Views/` vs `Pages/`) before
generating anything, and stay consistent with what is already there.

---

## Solution shape (MVC UI)

```
Acme.MyApp.Web/
├── Controllers/                 ← AbpController-derived classes
├── Views/
│   ├── _ViewImports.cshtml      ← ABP tag helper registrations (do not lose these)
│   ├── _ViewStart.cshtml        ← Layout = "_Layout"
│   ├── Layout/                  ← theme layout pages
│   └── Books/                   ← Index.cshtml, CreateModal.cshtml, ...
├── Components/                  (optional) view components
├── Menus/                       ← INavigationProvider menu contributors (same as Razor Pages)
├── MyAppBrandingProvider.cs
├── MyAppWebAutoMapperProfile.cs
└── MyAppWebModule.cs            ← bundling, theme registration, module DependsOn
```

`abp install-libs` must have been run in the Web project folder — it copies the client-side
libraries referenced by the theme into `wwwroot/libs`. Generated UI looks blank/broken without it.

---

## Controller

Inherit **`AbpController`** (`Volo.Abp.AspNetCore.Mvc`) rather than plain `Controller`. It carries
ABP's ambient service properties the same way `AbpPageModel` does for Razor Pages — `CurrentUser`,
`CurrentTenant`, `ObjectMapper`, `Logger` (confirm the exact set on the overview doc page for the
ABP version in use).

```csharp
using System.Collections.Generic;
using Acme.MyApp.Books;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc;

namespace Acme.MyApp.Web.Controllers;

public class BooksController : AbpController
{
    private readonly IBookAppService _bookAppService;

    public BooksController(IBookAppService bookAppService)
    {
        _bookAppService = bookAppService;
    }

    public async Task<ActionResult IndexViewModel> IndexAsync()
    {
        var result = await _bookAppService.GetListAsync(new GetBooksInput());
        return View(new IndexViewModel { Books = result.Items });
    }

    // Form POST → validate, call the app service, redirect. Never touch repositories here.
    [HttpPost]
    public async Task<IActionResult> CreateAsync(CreateBookViewModel input)
    {
        if (!ModelState.IsValid)
            return View("CreateModal", input);

        await _bookAppService.CreateAsync(input);
        return RedirectToPage("/Books/Index");
    }
}
```

**View models vs DTOs:** controllers pass *view models* to views; view models are either the
Application.Contracts DTOs directly or thin wrappers around them. Domain entities never reach a view.

**Prefer Razor Pages for page-style UI** even in an MVC-selected solution — that is ABP's own
recommendation, and the `abp-razor-page` agent output stays compatible with MVC solutions.

---

## `_ViewImports.cshtml`

The startup template registers ABP's tag helper assemblies here. If you regenerate this file, keep
all four registrations (assembly names come from the generated project — read the existing file
before overwriting it):

```cshtml
@using Volo.Abp.AspNetCore.Mvc.UI
@addTagHelper *, Volo.Abp.AspNetCore.Mvc.UI
@addTagHelper *, Volo.Abp.AspNetCore.Mvc.UI.Bootstrap
@addTagHelper *, Volo.Abp.AspNetCore.Mvc.UI.Bundling
```

Without the Bundling tag helpers, `<abp-script>` / `<abp-style>` silently render nothing.

---

## View with ABP tag helpers

```cshtml
@model Acme.MyApp.Web.Views.Books.IndexViewModel
@using Acme.MyApp.Permissions
@using Microsoft.AspNetCore.Authorization
@inject IAuthorizationService AuthorizationService

<div class="card">
    <div class="card-body">
        <abp-card>
            <abp-card-header>
                <abp-row>
                    <abp-column size-md="_6">
                        <abp-card-title>@L["Books"]</abp-card-title>
                    </abp-column>
                    <abp-column size-md="_6" class="text-end">
                        @if (await AuthorizationService.IsGrantedAsync(BookStorePermissions.Books.Create))
                        {
                            <abp-button id="NewBookButton"
                                       text="@L["NewBook"].Value"
                                       icon="plus"
                                       button-type="Primary" />
                        }
                    </abp-column>
                </abp-row>
            </abp-card-header>
            <abp-card-body>
                <abp-table striped-rows="true" id="BooksTable"></abp-table>
            </abp-card-body>
        </abp-card>
    </div>
</div>

@section Scripts {
    <abp-script src="/Views/Books/Index.js" />
}
```

`@L["Key"]` is the MVC/Razor localization helper — see `references/localization.md` for resource
selection and the `::Key` prefix rules.

---

## JavaScript (DataTables + ABP JS API)

Same JS API surface as Razor Pages; only the file path differs. Put it next to the view:

```javascript
// Views/Books/Index.js — identical API to the Razor Pages version in ui-razorpages.md
$(function () {
    var l = abp.localization.getResource('MyApp');
    var createModal = new abp.ModalManager(abp.appPath + 'Books/Create');

    var dataTable = $('#BooksTable').DataTable(
        abp.libs.datatables.normalizeConfiguration({
            serverSide: true,
            paging: true,
            order: [[1, 'asc']],
            searching: false,
            scrollX: true,
            ajax: abp.libs.datatables.createAjax(
                acme.myApp.books.book.getList  // auto-generated JS proxy
            ),
            columnDefs: [
                {
                    title: l('Actions'),
                    rowAction: {
                        items: [
                            {
                                text: l('Delete'),
                                visible: abp.auth.isGranted('MyApp.Books.Delete'),
                                action: function (data) {
                                    acme.myApp.books.book
                                        .delete(data.record.id)
                                        .then(function () {
                                            abp.notify.info(l('SuccessfullyDeleted'));
                                            dataTable.ajax.reload();
                                        });
                                }
                            }
                        ]
                    }
                },
                { title: l('Name'), data: 'name' },
                { title: l('Price'), data: 'price' }
            ]
        })
    );

    createModal.onResult(function () { dataTable.ajax.reload(); });
    $('#NewBookButton').click(function () { createModal.open(); });
});
```

Available on both MVC and Razor Pages (`abp.ajax`, `abp.modal`, `abp.notify`, `abp.auth`,
`abp.localization`, `abp.settings`, `abp.currentTenant`, `abp.url`):
<https://abp.io/docs/latest/framework/ui/mvc-razor-pages/javascript-api>

For list screens, prefer the declarative tag-helper routes instead of hand-written JS where the
version supports them: data tables
(https://abp.io/docs/latest/framework/ui/mvc-razor-pages/data-tables), toolbars
(https://abp.io/docs/latest/framework/ui/mvc-razor-pages/toolbars), entity action extensions
(https://abp.io/docs/latest/framework/ui/mvc-razor-pages/entity-action-extensions).
LeptonX-based solutions use **DTLite**, not jQuery DataTables — check which theme is installed before
emitting table code.

---

## Bundling (Web module)

```csharp
public override void ConfigureServices(ServiceConfigurationContext context)
{
    Configure<AbpBundlingOptions>(options =>
    {
        options.ScriptBundles
            .Configure(typeof(Volo.Abp.AspNetCore.Mvc.UI.Theme.Shared.Toolbars.LayoutMenus?.GetType()),
                bundleConfig =>
                {
                    bundleConfig.AddToBundle = true;
                });

        options.ScriptBundles
            .Add("Pages/Books/Index.js",
                bundleConfig => bundleConfig.AddFiles("./Views/Books/Index.js"));
    });
}
```

Bundle names are virtual paths used by `<abp-script src="...">`. Details:
https://abp.io/docs/latest/framework/ui/mvc-razor-pages/bundling-minification

---

## Menus

Identical to Razor Pages — implement `INavigationProvider` in `Web/Menus/`:

```csharp
context.Menu.AddItem(
    new ApplicationMenuItem(
        "BooksStore",
        lGetOrNull: null,
        name: L["Books"],
        icon: "fa fa-list",
        url: "~/Books",
        requirePermission: BookStorePermissions.Books.Default,
        order: 1));
```

https://abp.io/docs/latest/framework/ui/mvc-razor-pages/navigation-menu

---

## Key rules

- **DO** check whether the target project is MVC (`Views/`) or Razor Pages (`Pages/`) before
  generating UI, and emit the matching layout — never mix the two conventions in one screen.
- **DO** run `abp install-libs` in the Web project after scaffolding UI; blank pages are the usual
  symptom of skipping it.
- **DO** keep all four `@addTagHelper` lines in `_ViewImports.cshtml`; read the existing file first
  rather than regenerating from memory.
- **DO** inherit `AbpController` / `AbpPageModel`, never the bare ASP.NET Core base classes.
- **DO** gate UI with the *same* permission constants defined in `Application.Contracts`
  (`AuthorizationService.IsGrantedAsync` in views, `abp.auth.hasPermission` in JS) — see
  `references/authorization.md`.
- **DO NOT** put business logic in controllers; controllers call application services only.
- **DO NOT** pass domain entities to views — always DTOs / view models.
- **DO** verify theme-dependent APIs (DataTables vs DTLite, tag helper names) against the docs URLs
  at the top of this file before writing generated code.
