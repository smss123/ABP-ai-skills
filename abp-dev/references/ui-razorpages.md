# ABP: Razor Pages / MVC UI

> 📖 Official docs:
> - Razor Pages UI: https://docs.abp.io/en/abp/latest/UI/AspNetCore/Razor-Pages
> - Tag Helpers: https://docs.abp.io/en/abp/latest/UI/AspNetCore/Tag-Helpers/Index
> - JavaScript API / Modal Manager: https://docs.abp.io/en/abp/latest/UI/AspNetCore/JavaScript-API/Index
> - Navigation & Menus: https://docs.abp.io/en/abp/latest/UI/AspNetCore/Navigation-Menu
> - Localization: https://docs.abp.io/en/abp/latest/Localization
>
> Fetch these pages for the latest API details before generating UI, page model, or JavaScript code.

## Page Model Base Class

All Razor Page models should inherit from `AbpPageModel` (not `PageModel`):

```csharp
using Acme.BookStore.Books;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc.UI.RazorPages;

namespace Acme.BookStore.Web.Pages.Books;

public class IndexModel : AbpPageModel
{
    private readonly IBookAppService _bookAppService;

    public IReadOnlyList<BookDto> Books { get; set; } = new List<BookDto>();

    public IndexModel(IBookAppService bookAppService)
    {
        _bookAppService = bookAppService;
    }

    public async Task OnGetAsync()
    {
        var result = await _bookAppService.GetListAsync(new GetBooksInput());
        Books = result.Items;
    }
}
```

`AbpPageModel` gives you: `CurrentUser`, `CurrentTenant`, `ObjectMapper`,
`Logger`, `LocalizationResource`, `AuthorizationService`, `Clock`.

---

## Razor Page (.cshtml)

```html
@page
@model Acme.BookStore.Web.Pages.Books.IndexModel
@using Acme.BookStore.Permissions
@using Microsoft.AspNetCore.Authorization
@inject IAuthorizationService AuthorizationService

@section scripts {
    <abp-script src="/Pages/Books/Index.js" />
}

<abp-card>
    <abp-card-header>
        <abp-row>
            <abp-column size-md="_6">
                <h2>@L["Books"]</h2>
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
```

---

## ABP Tag Helpers

ABP provides Bootstrap-based tag helpers for all common UI elements:

```html
<!-- Buttons -->
<abp-button button-type="Primary" text="Save" icon="save" />
<abp-button button-type="Danger" text="Delete" icon="trash" />

<!-- Card -->
<abp-card>
    <abp-card-header>Title</abp-card-header>
    <abp-card-body>Content</abp-card-body>
</abp-card>

<!-- Form fields -->
<abp-input asp-for="Book.Name" />
<abp-select asp-for="Book.Type" asp-items="@Model.BookTypeSelectList" />
<abp-date-picker asp-for="Book.PublishDate" />

<!-- Table -->
<abp-table id="MyTable" striped-rows="true" />

<!-- Modal -->
<abp-modal>
    <abp-modal-header title="@L["CreateBook"].Value"></abp-modal-header>
    <abp-modal-body>
        <form id="CreateBookForm" method="post">
            <abp-input asp-for="Book.Name" />
            <abp-select asp-for="Book.Type" asp-items="..." />
        </form>
    </abp-modal-body>
    <abp-modal-footer buttons="@AbpModalButtons.Save | @AbpModalButtons.Cancel"></abp-modal-footer>
</abp-modal>

<!-- Row / Column grid -->
<abp-row>
    <abp-column size-md="_6">...</abp-column>
    <abp-column size-md="_6">...</abp-column>
</abp-row>
```

---

## Modal Page Pattern (Create/Edit)

ABP uses partial Razor Pages loaded in modals via AJAX.

```csharp
// Pages/Books/CreateModal.cshtml.cs
public class CreateModalModel : AbpPageModel
{
    [BindProperty]
    public CreateUpdateBookDto Book { get; set; } = new();

    private readonly IBookAppService _bookAppService;

    public CreateModalModel(IBookAppService bookAppService)
        => _bookAppService = bookAppService;

    public void OnGet() { }

    public async Task<IActionResult> OnPostAsync()
    {
        await _bookAppService.CreateAsync(Book);
        return NoContent();
    }
}
```

```html
<!-- Pages/Books/CreateModal.cshtml -->
@page
@model CreateModalModel

<abp-modal>
    <abp-modal-header title="@L["NewBook"].Value"></abp-modal-header>
    <abp-modal-body>
        <form id="CreateBookForm" method="post">
            <abp-input asp-for="Book.Name" />
            <abp-select asp-for="Book.Type" asp-items="@Html.GetEnumSelectList<BookType>()" />
            <abp-input asp-for="Book.Price" />
            <abp-date-picker asp-for="Book.PublishDate" />
        </form>
    </abp-modal-body>
    <abp-modal-footer buttons="@AbpModalButtons.Cancel|@AbpModalButtons.Save"></abp-modal-footer>
</abp-modal>
```

---

## JavaScript (DataTables + ABP Ajax)

```javascript
// Pages/Books/Index.js
$(function () {
    var l = abp.localization.getResource('BookStore');
    var createModal = new abp.ModalManager(abp.appPath + 'Books/CreateModal');
    var editModal   = new abp.ModalManager(abp.appPath + 'Books/EditModal');

    var dataTable = $('#BooksTable').DataTable(
        abp.libs.datatables.normalizeConfiguration({
            serverSide: true,
            paging: true,
            order: [[1, 'asc']],
            searching: false,
            scrollX: true,
            ajax: abp.libs.datatables.createAjax(
                acme.bookStore.books.book.getList  // auto-generated JS proxy
            ),
            columnDefs: [
                {
                    title: l('Actions'),
                    rowAction: {
                        items: [
                            {
                                text: l('Edit'),
                                visible: abp.auth.isGranted('BookStore.Books.Edit'),
                                action: function (data) {
                                    editModal.open({ id: data.record.id });
                                }
                            },
                            {
                                text: l('Delete'),
                                visible: abp.auth.isGranted('BookStore.Books.Delete'),
                                confirmMessage: function (data) {
                                    return l('BookDeletionConfirmationMessage', data.record.name);
                                },
                                action: function (data) {
                                    acme.bookStore.books.book
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
                { title: l('Name'),  data: 'name' },
                { title: l('Type'),  data: 'type',  render: (v) => l(`Enum:BookType.${v}`) },
                { title: l('Price'), data: 'price' }
            ]
        })
    );

    createModal.onResult(function () { dataTable.ajax.reload(); });
    editModal.onResult(function ()   { dataTable.ajax.reload(); });

    $('#NewBookButton').click(function () { createModal.open(); });
});
```

---

## Menu Contributor

```csharp
// Web/Menus/BookStoreMenuContributor.cs
using System.Threading.Tasks;
using Acme.BookStore.Permissions;
using Volo.Abp.UI.Navigation;

namespace Acme.BookStore.Web.Menus;

public class BookStoreMenuContributor : IMenuContributor
{
    public async Task ConfigureMenuAsync(MenuConfigurationContext context)
    {
        if (context.Menu.Name == StandardMenus.Main)
            await ConfigureMainMenuAsync(context);
    }

    private async Task ConfigureMainMenuAsync(MenuConfigurationContext context)
    {
        var l = context.GetLocalizer<BookStoreResource>();

        if (await context.IsGrantedAsync(BookStorePermissions.Books.Default))
        {
            context.Menu.AddItem(
                new ApplicationMenuItem(
                    "BooksStore",
                    l["Menu:BookStore"],
                    icon: "fa fa-book"
                ).AddItem(
                    new ApplicationMenuItem(
                        "BooksStore.Books",
                        l["Menu:Books"],
                        url: "/Books"
                    )
                )
            );
        }
    }
}
```

Register in module:
```csharp
Configure<AbpNavigationOptions>(options =>
{
    options.MenuContributors.Add(new BookStoreMenuContributor());
});
```

---

## Localization in Razor Pages

```csharp
// In PageModel — inject via AbpPageModel base
var text = L["Books"];  // uses the app's default localization resource

// Explicit resource
private readonly IStringLocalizer<BookStoreResource> _localizer;
// then: _localizer["MyKey"]
```

```html
<!-- In .cshtml -->
@L["Books"]
@L["WelcomeMessage", "John"]   <!-- with parameter -->
```
