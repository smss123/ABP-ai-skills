# ABP: Object Extensions & Module Customization

> 📖 Official docs:
> - Object Extensions: https://abp.io/docs/latest/framework/fundamentals/object-extensions
> - Module Entity Extensions: https://abp.io/docs/latest/framework/architecture/modularity/extending/module-entity-extensions
> - Extending Entities: https://abp.io/docs/latest/framework/architecture/modularity/extending/customizing-application-modules-extending-entities
> - Overriding Services: https://abp.io/docs/latest/framework/architecture/modularity/extending/customizing-application-modules-overriding-services
> - Customization Guide: https://abp.io/docs/latest/framework/architecture/modularity/extending/customizing-application-modules-guide
>
> Fetch these pages for the latest API details before generating module extension or service override code.

---

## 1. Extra Properties (Schema-Free Extension)

Any class implementing `IHasExtraProperties` (all ABP entities and DTOs do) can store dynamic properties as a JSON blob — no migration needed.

```csharp
// Set / get
user.SetProperty("SocialSecurityNumber", "123-45-6789");
string ssn = user.GetProperty<string>("SocialSecurityNumber");
bool has   = user.HasProperty("SocialSecurityNumber");
user.RemoveProperty("SocialSecurityNumber"); // prefer over setting null

// Copy between objects
user.MapExtraPropertiesTo(userDto); // copies matching extra props
```

**When to use:** Rapid prototyping, lightweight extensions, or data that doesn't need indexing/querying via SQL.

---

## 2. Module Entity Extensions (Typed Columns)

Add strongly-typed, database-column-backed properties to existing module entities (e.g., `IdentityUser`, `Tenant`). These appear automatically in the HTTP API and UI.

### 2a. Define the Extension

Call `ObjectExtensionManager` early in module startup — typically in `Domain.Shared` or `Application.Contracts`.

```csharp
// Domain.Shared/BookStoreDomainSharedModule.cs (in static constructor or PreConfigureServices)
ObjectExtensionManager.Instance
    .Modules()
    .ConfigureIdentity(identity =>
    {
        identity.ConfigureUser(user =>
        {
            user.AddOrUpdateProperty<string>("Title", property =>
            {
                property.Attributes.Add(new StringLengthAttribute(64));
                property.DefaultValue = "Mr.";
                property.DisplayName = LocalizableString.Create<BookStoreResource>("UserTitle");

                // UI configuration
                property.UI.OnTable.IsVisible = true;
                property.UI.OnCreateForm.IsVisible = true;
                property.UI.OnEditForm.IsVisible   = true;

                // API configuration
                property.Api.OnGet.IsAvailable    = true;
                property.Api.OnCreate.IsAvailable = true;
                property.Api.OnUpdate.IsAvailable = true;
            });
        });
    });
```

### 2b. Map to a Database Column (EF Core)

Add in your `EntityFrameworkCore` module:

```csharp
ObjectExtensionManager.Instance
    .MapEfCoreProperty<IdentityUser, string>(
        "Title",
        (entityBuilder, propertyBuilder) =>
        {
            propertyBuilder.HasMaxLength(64).HasDefaultValue("Mr.");
        }
    );
```

Then create and apply a migration:

```bash
dotnet ef migrations add AddUserTitleExtension --project src/Acme.BookStore.EntityFrameworkCore
dotnet ef database update --project src/Acme.BookStore.EntityFrameworkCore
```

### 2c. Supported Module Configuration Methods

```csharp
.ConfigureIdentity(identity => identity.ConfigureUser(...).ConfigureRole(...))
.ConfigureTenantManagement(tm => tm.ConfigureTenant(...))
// Other modules expose similar ConfigureXxx() helpers
```

---

## 3. Extending DTOs

Add extra properties to DTOs exposed by pre-built modules:

```csharp
ObjectExtensionManager.Instance
    .AddOrUpdateProperty<IdentityUserDto, string>("Title");
    // now "Title" is included in Get/Create/Update DTOs automatically
```

---

## 4. Overriding Module Services

### Replace via Interface

```csharp
[ExposeServices(typeof(IIdentityUserAppService))]
[Dependency(ReplaceServices = true)]
public class CustomIdentityUserAppService
    : IIdentityUserAppService, ITransientDependency
{
    // Full reimplementation
}
```

### Override via Inheritance (preferred — preserves existing behaviour)

```csharp
[Dependency(ReplaceServices = true)]
[ExposeServices(typeof(IdentityUserAppService), typeof(CustomIdentityUserAppService))]
public class CustomIdentityUserAppService : IdentityUserAppService
{
    public CustomIdentityUserAppService(/* same dependencies as base */) : base(...) { }

    public override async Task<IdentityUserDto> CreateAsync(IdentityUserCreateDto input)
    {
        // Pre/post processing around the original logic
        var result = await base.CreateAsync(input);
        // ... custom logic ...
        return result;
    }
}
```

### Replace via DI Descriptor

```csharp
context.Services.Replace(
    ServiceDescriptor.Transient<IEmailSender, CustomEmailSender>()
);
```

### Replace a Repository

```csharp
context.Services.AddDefaultRepository(
    typeof(MyEntity),
    typeof(CustomMyEntityRepository),
    replaceExisting: true
);
```

---

## 5. Constants for Property Names

Avoid magic strings — define constants alongside the extension:

```csharp
public static class BookStoreModuleExtensionConsts
{
    public const string ModuleName = "BookStore";

    public static class Identity
    {
        public const string UserTitle = "Title";
    }
}
```

---

## Key Rules

- **DO** call `ObjectExtensionManager` in `PreConfigureServices` or a static constructor — before the DI container builds
- **DO** map extra properties to EF Core columns when you need indexing or SQL queries
- **DO** define constants for property names to avoid typos
- **DO** prefer inheriting from the original service over full reimplementation
- **DO NOT** call `SetProperty` with `null` to remove a value — use `RemoveProperty` instead
- **DO NOT** use `MappingPropertyDefinitionChecks.None` unless you understand the mapping risks
