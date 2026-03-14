# ABP: Authorization & Permissions

## Permission Definition

Defined in `Application.Contracts` project. ABP auto-discovers providers.

```csharp
// Application.Contracts/Permissions/BookStorePermissions.cs
namespace Acme.BookStore.Permissions;

public static class BookStorePermissions
{
    public const string GroupName = "BookStore";

    public static class Books
    {
        public const string Default = GroupName + ".Books";
        public const string Create  = Default + ".Create";
        public const string Edit    = Default + ".Edit";
        public const string Delete  = Default + ".Delete";
    }

    public static class Authors
    {
        public const string Default = GroupName + ".Authors";
        public const string Create  = Default + ".Create";
        public const string Edit    = Default + ".Edit";
        public const string Delete  = Default + ".Delete";
    }
}
```

```csharp
// Application.Contracts/Permissions/BookStorePermissionDefinitionProvider.cs
using Acme.BookStore.Localization;
using Volo.Abp.Authorization.Permissions;
using Volo.Abp.Localization;

namespace Acme.BookStore.Permissions;

public class BookStorePermissionDefinitionProvider : PermissionDefinitionProvider
{
    public override void Define(IPermissionDefinitionContext context)
    {
        var bookStoreGroup = context.AddGroup(
            BookStorePermissions.GroupName,
            L("Permission:BookStore")
        );

        var booksPermission = bookStoreGroup.AddPermission(
            BookStorePermissions.Books.Default,
            L("Permission:Books")
        );
        booksPermission.AddChild(BookStorePermissions.Books.Create, L("Permission:Books.Create"));
        booksPermission.AddChild(BookStorePermissions.Books.Edit,   L("Permission:Books.Edit"));
        booksPermission.AddChild(BookStorePermissions.Books.Delete, L("Permission:Books.Delete"));
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

Add localization keys to `en.json` (Domain.Shared/Localization/BookStore/):
```json
{
  "Permission:BookStore":        "Book Store",
  "Permission:Books":            "Book Management",
  "Permission:Books.Create":     "Creating new books",
  "Permission:Books.Edit":       "Editing books",
  "Permission:Books.Delete":     "Deleting books"
}
```

---

## Checking Permissions in Application Services

```csharp
// Method 1: [Authorize] attribute (preferred)
[Authorize(BookStorePermissions.Books.Default)]
public class BookAppService : ApplicationService
{
    [Authorize(BookStorePermissions.Books.Create)]
    public async Task<BookDto> CreateAsync(CreateUpdateBookDto input) { ... }

    [Authorize(BookStorePermissions.Books.Delete)]
    public async Task DeleteAsync(Guid id) { ... }
}

// Method 2: IAuthorizationService (programmatic check)
public class BookAppService : ApplicationService
{
    public async Task DeleteAsync(Guid id)
    {
        await AuthorizationService.CheckAsync(BookStorePermissions.Books.Delete);
        // throws AbpAuthorizationException if not granted
        await _bookRepository.DeleteAsync(id);
    }
}
```

---

## Checking Permissions in Razor Pages

### In the Module's ConfigureServices

```csharp
Configure<RazorPagesOptions>(options =>
{
    options.Conventions.AuthorizePage("/Books/Index",       BookStorePermissions.Books.Default);
    options.Conventions.AuthorizePage("/Books/CreateModal", BookStorePermissions.Books.Create);
    options.Conventions.AuthorizePage("/Books/EditModal",   BookStorePermissions.Books.Edit);
});
```

### In Page Model

```csharp
public class IndexModel : AbpPageModel
{
    private readonly IAuthorizationService _authorizationService;

    public bool CanCreateBook { get; set; }

    public async Task OnGetAsync()
    {
        CanCreateBook = await _authorizationService
            .IsGrantedAsync(BookStorePermissions.Books.Create);
    }
}
```

### In Razor Page (.cshtml) — show/hide UI elements

```html
@inject IAuthorizationService AuthorizationService

@if (await AuthorizationService.IsGrantedAsync(BookStorePermissions.Books.Create))
{
    <abp-button id="NewBookButton" ...>New Book</abp-button>
}
```

### JavaScript side

```javascript
// abp.auth is populated automatically
if (abp.auth.isGranted('BookStore.Books.Create')) {
    $('#NewBookButton').show();
}
```

---

## ICurrentUser

Inject `ICurrentUser` anywhere to access the logged-in user:

```csharp
public class BookAppService : ApplicationService
{
    // ApplicationService already exposes CurrentUser property
    public Task<BookDto> CreateAsync(CreateUpdateBookDto input)
    {
        var userId   = CurrentUser.Id;          // Guid?
        var userName = CurrentUser.UserName;    // string?
        var tenantId = CurrentUser.TenantId;    // Guid? (multi-tenant)
        var isAuthenticated = CurrentUser.IsAuthenticated;
        ...
    }
}
```

---

## Audit Logging

ABP automatically logs every HTTP request + application service method call.
To customize what gets logged:

```csharp
// Disable audit for a specific method
[DisableAuditing]
public Task<List<BookDto>> GetListAsync(GetBooksInput input) { ... }

// Force audit log on an entity
public class Book : FullAuditedAggregateRoot<Guid> { }  // IsDeleted, DeleterId etc. tracked

// Configure globally in module
Configure<AbpAuditingOptions>(options =>
{
    options.IsEnabled = true;
    options.HideErrors = false;
    options.IsEnabledForGetRequests = false;  // don't log GET requests (default)
    options.EntityHistorySelectors.AddAllEntities();  // enable entity change history
});
```
