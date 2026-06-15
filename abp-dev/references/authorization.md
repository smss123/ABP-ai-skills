# ABP: Authorization & Permissions

> 📖 Official docs:
> - Authorization & Permissions: https://docs.abp.io/en/abp/latest/Authorization
> - Permission Management: https://docs.abp.io/en/abp/latest/Permission-Management
> - Current User: https://docs.abp.io/en/abp/latest/CurrentUser
> - Audit Logging: https://docs.abp.io/en/abp/latest/Audit-Logging
>
> Fetch these pages for the latest API details before generating authorization or permission code.

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

## Resource-Based Authorization

Use when access depends on a **specific resource instance** (e.g., "can edit only their own document").

### 1. Define resource permissions

```csharp
// In PermissionDefinitionProvider
context.AddResourcePermission(
    name: BookStorePermissions.Books.Resources.View,
    resourceName: BookStorePermissions.Books.Resources.Name,    // e.g. "Book"
    managementPermissionName: BookStorePermissions.Books.ManagePermissions,
    displayName: L("Permission:Books.Resources.View")
);
```

### 2. Check resource permission in application service

```csharp
// Check against a specific entity instance
var isGranted = await AuthorizationService.IsGrantedAsync(
    book,
    BookStorePermissions.Books.Resources.Edit
);
if (!isGranted)
    throw new AbpAuthorizationException("No permission to edit this book.");
```

### 3. Batch check multiple permissions

```csharp
var result = await _resourcePermissionChecker.IsGrantedAsync(
    new[] { BookStorePermissions.Books.Resources.View,
            BookStorePermissions.Books.Resources.Edit },
    resourceName: "Book",
    objectKey: book.GetObjectKey()
);
```

### 4. Programmatic grant/revoke

```csharp
await _resourcePermissionManager.SetAsync(
    userId,
    BookStorePermissions.Books.Resources.Edit,
    resourceName: "Book",
    objectKey: book.GetObjectKey(),
    isGranted: true
);
```

---

## Permission Value Providers

ABP resolves permissions by querying a chain of providers in order:

| Provider | Source |
|---|---|
| `UserPermissionValueProvider` | Permissions granted directly to the user |
| `RolePermissionValueProvider` | Permissions from the user's roles |
| `ClientPermissionValueProvider` | Permissions granted to the OAuth client |

Each provider returns `Granted`, `Prohibited`, or `Undefined`. The chain stops at the first non-`Undefined` result.

### Custom Permission Value Provider

```csharp
public class SystemAdminPermissionValueProvider : PermissionValueProvider
{
    public const string ProviderName = "SA";
    public override string Name => ProviderName;

    public override async Task<PermissionGrantResult> CheckAsync(
        PermissionValueCheckContext context)
    {
        if (context.Principal?.FindFirst("role")?.Value == "SystemAdmin")
            return PermissionGrantResult.Granted;

        return PermissionGrantResult.Undefined;
    }
}

// Register in module:
Configure<PermissionOptions>(options =>
{
    options.ValueProviders.Add<SystemAdminPermissionValueProvider>();
});
```

---

## `IPermissionManager` — Programmatic Grant/Revoke

```csharp
// Grant a permission to a role
await _permissionManager.SetAsync(
    BookStorePermissions.Books.Create,
    RolePermissionValueProvider.ProviderName,
    roleName: "Editor",
    isGranted: true
);

// Grant to a user
await _permissionManager.SetAsync(
    BookStorePermissions.Books.Delete,
    UserPermissionValueProvider.ProviderName,
    providerKey: userId.ToString(),
    isGranted: true
);
```

---

## Feature-Dependent Permissions

Tie a permission's availability to a feature flag:

```csharp
booksPermission
    .WithFeatures("BookManagement")       // single feature
    .WithGlobalFeatures(typeof(BookStoreGlobalFeature)); // global feature
```

The permission is hidden in the UI and always returns `Undefined` when the feature is off.

---

## Multi-Tenancy Side on Permissions

```csharp
booksPermission.AddChild(
    BookStorePermissions.Books.Create, L("Permission:Books.Create")
).SetMultiTenancySide(MultiTenancySides.Tenant);   // Tenant only

context.AddGroup(BookStorePermissions.GroupName, L("Permission:BookStore"))
       .SetMultiTenancySide(MultiTenancySides.Host);  // Host only
```

---

## Dynamic Claims

Real-time claim refresh without requiring re-authentication — essential when roles/permissions change mid-session.

### Enable in module

```csharp
Configure<AbpClaimsPrincipalFactoryOptions>(options =>
{
    options.IsDynamicClaimsEnabled = true;
    // For tiered deployments (UI ≠ Auth Server):
    options.RemoteRefreshUrl = configuration["AuthServerUrl"] + options.RemoteRefreshUrl;
});
```

### Add middleware (before `UseAuthorization`)

```csharp
app.UseDynamicClaims();  // must come before app.UseAuthorization()
app.UseAuthorization();
```

### Custom claims contributor

```csharp
public class MyClaimsContributor : IAbpDynamicClaimsPrincipalContributor
{
    public async Task ContributeAsync(AbpClaimsPrincipalContributorContext context)
    {
        var identity = context.ClaimsPrincipal.Identities.FirstOrDefault();
        identity?.AddClaim(new Claim("department", "Finance"));
    }
}
```

> Cache results — this executes on every HTTP request.

---

## Simple State Checker

A generic condition system used by menu items, toolbar items, and permission definitions to show/hide/disable based on runtime state.

### Built-in extension methods (on `ApplicationMenuItem`, `PermissionDefinition`, etc.)

```csharp
menuItem
    .RequireAuthenticated()
    .RequirePermissions(requiresAll: false, "BookStore.Books", "BookStore.Authors")
    .RequireFeatures("BookManagement")
    .RequireGlobalFeatures(typeof(BookStoreGlobalFeature));
```

### Custom state checker

```csharp
public class OfficeHoursStateChecker : ISimpleStateChecker<ApplicationMenuItem>
{
    public Task<bool> IsEnabledAsync(
        SimpleStateCheckerContext<ApplicationMenuItem> context)
    {
        var hour = DateTime.UtcNow.Hour;
        return Task.FromResult(hour >= 8 && hour < 18); // only show 08:00–18:00
    }
}

// Apply to a menu item
menuItem.StateCheckers.Add(new OfficeHoursStateChecker());
```

### Global state checker (applies to all instances)

```csharp
Configure<AbpSimpleStateCheckerOptions<ApplicationMenuItem>>(options =>
{
    options.GlobalSimpleStateCheckers.Add<MyGlobalMenuStateChecker>();
});
```

### Programmatic check

```csharp
private readonly ISimpleStateCheckerManager<ApplicationMenuItem> _stateCheckerManager;

var isEnabled = await _stateCheckerManager.IsEnabledAsync(menuItem);
```

### Batch checking (performance — many items at once)

```csharp
// Implement ISimpleBatchStateChecker or inherit the base class
public class MyBatchChecker : SimpleBatchStateCheckerBase<ApplicationMenuItem>
{
    public override async Task<SimpleStateCheckerResult<ApplicationMenuItem>> IsEnabledAsync(
        SimpleBatchStateCheckerContext<ApplicationMenuItem> context)
    {
        var result = new SimpleStateCheckerResult<ApplicationMenuItem>(context.States);
        foreach (var state in context.States)
        {
            result[state] = await SomeCheckAsync(state);
        }
        return result;
    }
}

// Share a single instance across items so the batch method is called once
var checker = new MyBatchChecker();
foreach (var item in menuItems)
    item.StateCheckers.Add(checker);
```

---

## `AlwaysAllowAuthorizationService` (Integration Tests)

Bypass permission checks in test projects:

```csharp
// In test module
context.Services.AddAlwaysAllowAuthorization();
// or inject directly in tests:
IAuthorizationService authorizationService = new AlwaysAllowAuthorizationService();
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
