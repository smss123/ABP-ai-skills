---
mode: 'agent'
description: 'Scaffold ABP Razor Pages UI — list page, create/edit modals, JavaScript, and menu item'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold **Razor Pages UI** for the entity the user names — list page, create/edit modals, DataTable JavaScript, and menu registration.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

1. Read `abp-dev/references/ui-razorpages.md` — page model, tag helpers, JS, menu patterns.
2. Read `abp-dev/references/authorization.md` — permission checks in Razor Pages.
3. Fetch https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages for the latest API details.

Assumes the application service (`I<Entity>AppService`) and permissions (`BookStorePermissions.<Entity>s`) already exist.  
Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## Files to create

### 1. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml.cs`

```csharp
using Microsoft.AspNetCore.Mvc.RazorPages;
using Volo.Abp.AspNetCore.Mvc.UI.RazorPages;

namespace Acme.BookStore.Web.Pages.<Entity>s;

public class IndexModel : AbpPageModel
{
    public void OnGet() { }
}
```

### 2. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml`

```html
@page
@model Acme.BookStore.Web.Pages.<Entity>s.IndexModel
@using Acme.BookStore.Permissions
@using Microsoft.AspNetCore.Authorization
@inject IAuthorizationService AuthorizationService

@section scripts {
    <abp-script src="/Pages/<Entity>s/Index.js" />
}

<abp-card>
    <abp-card-header>
        <abp-row>
            <abp-column size-md="_6">
                <h2>@L["<Entity>s"]</h2>
            </abp-column>
            <abp-column size-md="_6" class="text-end">
                @if (await AuthorizationService.IsGrantedAsync(BookStorePermissions.<Entity>s.Create))
                {
                    <abp-button id="New<Entity>Button"
                                text="@L["New<Entity>"].Value"
                                icon="plus"
                                button-type="Primary" />
                }
            </abp-column>
        </abp-row>
    </abp-card-header>
    <abp-card-body>
        <abp-table striped-rows="true" id="<Entity>sTable"></abp-table>
    </abp-card-body>
</abp-card>
```

### 3. `src/Acme.BookStore.Web/Pages/<Entity>s/Index.js`

```javascript
$(function () {
    var l = abp.localization.getResource('BookStore');
    var createModal = new abp.ModalManager(abp.appPath + '<Entity>s/CreateModal');
    var editModal   = new abp.ModalManager(abp.appPath + '<Entity>s/EditModal');

    var dataTable = $('#<Entity>sTable').DataTable(
        abp.libs.datatables.normalizeConfiguration({
            serverSide: true,
            paging: true,
            order: [[1, 'asc']],
            searching: false,
            scrollX: true,
            ajax: abp.libs.datatables.createAjax(
                acme.bookStore.<entity>s.<entity>.getList
            ),
            columnDefs: [
                {
                    title: l('Actions'),
                    rowAction: {
                        items: [
                            {
                                text: l('Edit'),
                                visible: abp.auth.isGranted('BookStore.<Entity>s.Edit'),
                                action: function (data) {
                                    editModal.open({ id: data.record.id });
                                }
                            },
                            {
                                text: l('Delete'),
                                visible: abp.auth.isGranted('BookStore.<Entity>s.Delete'),
                                confirmMessage: function (data) {
                                    return l('<Entity>DeletionConfirmationMessage', data.record.name);
                                },
                                action: function (data) {
                                    acme.bookStore.<entity>s.<entity>
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
                { title: l('Name'), data: 'name' }
                // Add more column defs matching the entity's properties
            ]
        })
    );

    createModal.onResult(function () { dataTable.ajax.reload(); });
    editModal.onResult(function ()   { dataTable.ajax.reload(); });

    $('#New<Entity>Button').click(function () { createModal.open(); });
});
```

### 4. `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml.cs`

```csharp
using System.Threading.Tasks;
using Acme.BookStore.<Entity>s;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc.UI.RazorPages;

namespace Acme.BookStore.Web.Pages.<Entity>s;

public class CreateModalModel : AbpPageModel
{
    [BindProperty]
    public CreateUpdate<Entity>Dto <Entity> { get; set; } = new();

    private readonly I<Entity>AppService _<entity>AppService;

    public CreateModalModel(I<Entity>AppService <entity>AppService)
        => _<entity>AppService = <entity>AppService;

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync()
    {
        await _<entity>AppService.CreateAsync(<Entity>);
        return NoContent();
    }
}
```

### 5. `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml`

```html
@page
@model Acme.BookStore.Web.Pages.<Entity>s.CreateModalModel

<abp-modal>
    <abp-modal-header title="@L["New<Entity>"].Value"></abp-modal-header>
    <abp-modal-body>
        <form id="Create<Entity>Form" method="post">
            <abp-input asp-for="<Entity>.Name" />
            <!-- Add abp-input / abp-select for each DTO property -->
        </form>
    </abp-modal-body>
    <abp-modal-footer buttons="@(AbpModalButtons.Cancel|AbpModalButtons.Save)"></abp-modal-footer>
</abp-modal>
```

### 6. `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml.cs`

```csharp
using System;
using System.Threading.Tasks;
using Acme.BookStore.<Entity>s;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc.UI.RazorPages;

namespace Acme.BookStore.Web.Pages.<Entity>s;

public class EditModalModel : AbpPageModel
{
    [HiddenInput]
    [BindProperty(SupportsGet = true)]
    public Guid Id { get; set; }

    [BindProperty]
    public CreateUpdate<Entity>Dto <Entity> { get; set; } = new();

    private readonly I<Entity>AppService _<entity>AppService;

    public EditModalModel(I<Entity>AppService <entity>AppService)
        => _<entity>AppService = <entity>AppService;

    public async Task OnGetAsync()
    {
        var dto = await _<entity>AppService.GetAsync(Id);
        <Entity> = ObjectMapper.Map<<Entity>Dto, CreateUpdate<Entity>Dto>(dto);
    }

    public async Task<IActionResult> OnPostAsync()
    {
        await _<entity>AppService.UpdateAsync(Id, <Entity>);
        return NoContent();
    }
}
```

### 7. `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml`

```html
@page
@model Acme.BookStore.Web.Pages.<Entity>s.EditModalModel

<abp-modal>
    <abp-modal-header title="@L["Edit<Entity>"].Value"></abp-modal-header>
    <abp-modal-body>
        <form id="Edit<Entity>Form" method="post">
            <abp-input asp-for="Id" />
            <abp-input asp-for="<Entity>.Name" />
            <!-- Add abp-input / abp-select for each DTO property -->
        </form>
    </abp-modal-body>
    <abp-modal-footer buttons="@(AbpModalButtons.Cancel|AbpModalButtons.Save)"></abp-modal-footer>
</abp-modal>
```

### 8. Menu contributor snippet

Show the snippet to add inside `BookStoreMenuContributor.ConfigureMainMenuAsync`:

```csharp
if (await context.IsGrantedAsync(BookStorePermissions.<Entity>s.Default))
{
    context.Menu.AddItem(
        new ApplicationMenuItem(
            "BookStore.<Entity>s",
            l["Menu:<Entity>s"],
            url: "/<Entity>s",
            icon: "fa fa-list"
        )
    );
}
```

Also add the authorization convention in the Web module's `ConfigureServices`:
```csharp
Configure<RazorPagesOptions>(options =>
{
    options.Conventions.AuthorizePage("/<Entity>s/Index",       BookStorePermissions.<Entity>s.Default);
    options.Conventions.AuthorizePage("/<Entity>s/CreateModal", BookStorePermissions.<Entity>s.Create);
    options.Conventions.AuthorizePage("/<Entity>s/EditModal",   BookStorePermissions.<Entity>s.Edit);
});
```

Also add the AutoMapper entry for the Edit page's reverse mapping in `BookStoreWebAutoMapperProfile`:
```csharp
CreateMap<<Entity>Dto, CreateUpdate<Entity>Dto>();
```
