# ABP: Localization

> 📖 Official docs:
> - Localization: https://abp.io/docs/latest/framework/fundamentals/localization
> - ABP CLI: https://abp.io/docs/latest/framework/fundamentals/cli-structure
>
> Fetch these pages for the latest API details before generating localization code.

## Resource Definition

Define a marker class in `Domain.Shared` (or `Application.Contracts`). The `[LocalizationResourceName]` attribute sets the resource key used in JSON files.

```csharp
// Domain.Shared/Localization/BookStoreResource.cs
using Volo.Abp.Localization;

namespace Acme.BookStore.Localization;

[LocalizationResourceName("BookStore")]
public class BookStoreResource { }
```

---

## JSON Translation Files

Store JSON files in `Domain.Shared` under `Localization/<ResourceName>/`.

```
Domain.Shared/
  Localization/
    BookStore/
      en.json
      ar.json
      tr.json
```

```json
// en.json
{
  "culture": "en",
  "texts": {
    "HelloWorld": "Hello World!",
    "WelcomeMessage": "Welcome, {0}!",
    "Permission:Books": "Book Management",
    "Permission:Books.Create": "Creating new books"
  }
}
```

```json
// ar.json
{
  "culture": "ar",
  "texts": {
    "HelloWorld": "مرحباً بالعالم!",
    "WelcomeMessage": "أهلاً بك، {0}!"
  }
}
```

---

## Module Registration

Register the resource and JSON files in the `Domain.Shared` module:

```csharp
Configure<AbpVirtualFileSystemOptions>(options =>
{
    options.FileSets.AddEmbedded<BookStoreDomainSharedModule>();
});

Configure<AbpLocalizationOptions>(options =>
{
    options.Resources
        .Add<BookStoreResource>("en")                       // default culture
        .AddBaseTypes(typeof(AbpUiResource))                // inherit ABP UI strings
        .AddVirtualJson("/Localization/BookStore");         // path to JSON files

    options.DefaultResourceType = typeof(BookStoreResource);

    options.Languages.Add(new LanguageInfo("en", "en", "English"));
    options.Languages.Add(new LanguageInfo("ar", "ar", "العربية", "rtl"));
    options.Languages.Add(new LanguageInfo("tr", "tr", "Türkçe"));
});
```

---

## Injecting & Using the Localizer

### In Application Services / Domain Services

```csharp
using Microsoft.Extensions.Localization;
using Volo.Abp.Application.Services;

public class BookAppService : ApplicationService
{
    // ApplicationService already exposes L property if LocalizationResource is set
    // Alternatively inject directly:
    private readonly IStringLocalizer<BookStoreResource> _localizer;

    public BookAppService(IStringLocalizer<BookStoreResource> localizer)
    {
        _localizer = localizer;
    }

    public string GetGreeting(string name)
        => _localizer["WelcomeMessage", name]; // uses format args
}
```

### Setting `LocalizationResource` on Base Class

```csharp
public class BookAppService : ApplicationService
{
    public BookAppService()
    {
        LocalizationResource = typeof(BookStoreResource); // enables L["key"] shorthand
    }

    public string GetGreeting(string name)
        => L["WelcomeMessage", name];
}
```

### In Razor Pages / Views

```csharp
// Page model
public class IndexModel : AbpPageModel
{
    public IndexModel()
    {
        LocalizationResourceType = typeof(BookStoreResource);
    }

    public string Greeting => L["WelcomeMessage", "User"];
}
```

```html
<!-- .cshtml -->
@inject IHtmlLocalizer<BookStoreResource> Localizer

<h1>@Localizer["HelloWorld"]</h1>
```

### In JavaScript (client-side)

ABP exposes localization strings via `abp.localization`:

```javascript
// Access localized text
const text = abp.localization.localize('HelloWorld', 'BookStore');
// or shorthand if default resource is set
const text = abp.localization.getResource('BookStore')('HelloWorld');
```

---

## Resource Inheritance

Inherit strings from another resource to avoid duplication:

```csharp
options.Resources
    .Add<BookStoreResource>("en")
    .AddBaseTypes(typeof(AbpUiResource), typeof(AbpValidationResource));
```

ABP falls back to the base resource's strings when a key is missing from the child.

---

## Client-Side API Endpoint

ABP exposes a standard HTTP endpoint so JavaScript / SPA / mobile clients can fetch localization data at runtime.

### JSON endpoint (all platforms)

```
GET /api/abp/application-localization?cultureName=en
GET /api/abp/application-localization?cultureName=ar&onlyDynamics=false
```

| Query param | Required | Default | Purpose |
|---|---|---|---|
| `cultureName` | Yes | — | Culture code, e.g. `en`, `en-US`, `ar` |
| `onlyDynamics` | No | `false` | Return only dynamically defined resources (reduces payload when client bundles static ones) |

### Script endpoint (MVC / Razor Pages only)

```
GET /Abp/ApplicationLocalizationScript?cultureName=en
```

Returns a JavaScript file that populates `abp.localization.*` automatically. ABP templates wire this up in the layout — no manual call needed.

> **Angular / React / Blazor**: use the framework's native ABP localization service instead of calling these endpoints directly — the ABP startup templates configure them automatically.

---

## Key Rules

- **DO** define one localization resource per module in `Domain.Shared`
- **DO** always provide an `en.json` as the default/fallback culture
- **DO** use `AbpUiResource` as a base type to inherit common UI strings
- **DO** mark the JSON files as `EmbeddedResource` in the `.csproj`
- **DO NOT** hard-code UI text — always use localization keys
- **DO NOT** duplicate ABP's built-in keys — inherit via `AddBaseTypes()`
