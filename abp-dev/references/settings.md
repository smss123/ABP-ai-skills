# ABP: Settings

> 📖 Official docs:
> - Settings: https://docs.abp.io/en/abp/latest/Settings
> - Setting Management UI: https://docs.abp.io/en/abp/latest/Modules/Setting-Management
>
> Fetch these pages for the latest API details before generating settings code.

## Overview

ABP's settings system lets you define typed, hierarchical configuration values that can be scoped
to the application (global), a specific tenant, or a specific user.
Scope priority (highest wins): **User → Tenant → Global → Default**

> **ABP Settings vs `appsettings.json`**: Use ABP Settings for values that should be
> **changeable at runtime** (e.g. per-tenant SMTP host, upload limits, feature flags).
> Use `appsettings.json` / environment variables for infrastructure configuration that
> should **not change after deployment** (e.g. database connection strings, ports, secrets).

---

## 1. Define Settings

Create a `SettingDefinitionProvider` in the `Domain.Shared` or `Application.Contracts` project:

```csharp
// Domain.Shared/Settings/BookStoreSettingDefinitionProvider.cs
using Volo.Abp.Settings;

namespace Acme.BookStore.Settings;

public class BookStoreSettingDefinitionProvider : SettingDefinitionProvider
{
    public override void Define(ISettingDefinitionContext context)
    {
        context.Add(
            new SettingDefinition(
                BookStoreSettings.SmtpHost,
                defaultValue: "localhost",
                displayName: L("Setting:SmtpHost"),
                description: L("Setting:SmtpHost.Description"),
                isVisibleToClients: false,           // don't expose to JS
                isEncrypted: false                   // set true for passwords
            ),
            new SettingDefinition(
                BookStoreSettings.MaxUploadSizeMb,
                defaultValue: "10",
                displayName: L("Setting:MaxUploadSizeMb"),
                isVisibleToClients: true             // available in JS via abp.setting.get()
            )
        );
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

```csharp
// Domain.Shared/Settings/BookStoreSettings.cs
namespace Acme.BookStore.Settings;

public static class BookStoreSettings
{
    private const string Prefix = "BookStore";

    public const string SmtpHost        = Prefix + ".SmtpHost";
    public const string MaxUploadSizeMb = Prefix + ".MaxUploadSizeMb";
}
```

ABP **auto-discovers** `SettingDefinitionProvider` — no registration needed.

---

## 2. Read Settings

### In Application Services (ISettingProvider)

```csharp
using Volo.Abp.Settings;

public class BookAppService : ApplicationService
{
    private readonly ISettingProvider _settingProvider;

    public BookAppService(ISettingProvider settingProvider)
    {
        _settingProvider = settingProvider;
    }

    public async Task SendNotificationAsync()
    {
        // Returns the effective value: User → Tenant → Global → Default
        var smtpHost = await _settingProvider.GetOrNullAsync(BookStoreSettings.SmtpHost);
        var maxSizeMb = await _settingProvider.GetAsync<int>(BookStoreSettings.MaxUploadSizeMb);
    }
}
```

### In Razor Pages (ISettingProvider injected via AbpPageModel)

```csharp
public class IndexModel : AbpPageModel
{
    private readonly ISettingProvider _settingProvider;

    public IndexModel(ISettingProvider settingProvider)
    {
        _settingProvider = settingProvider;
    }

    public async Task OnGetAsync()
    {
        var maxSize = await _settingProvider.GetAsync<int>(BookStoreSettings.MaxUploadSizeMb);
    }
}
```

### In JavaScript (for `isVisibleToClients: true` settings)

```javascript
// abp.setting.get() returns the string value
var maxSize = abp.setting.getInt('BookStore.MaxUploadSizeMb');
var host    = abp.setting.get('BookStore.SmtpHost');
```

---

## 3. Write Settings (ISettingManager)

`ISettingManager` can set values at Global, Tenant, or User scope.  
It lives in the `Application` layer (not `Application.Contracts` — never expose it directly to API clients).

```csharp
using Volo.Abp.SettingManagement;

public class SettingsAppService : ApplicationService
{
    private readonly ISettingManager _settingManager;

    public SettingsAppService(ISettingManager settingManager)
    {
        _settingManager = settingManager;
    }

    // Set for all users of the application (global)
    public async Task SetGlobalSmtpHostAsync(string host)
    {
        await _settingManager.SetGlobalAsync(BookStoreSettings.SmtpHost, host);
    }

    // Set for the current tenant only
    public async Task SetTenantMaxUploadAsync(int sizeMb)
    {
        await _settingManager.SetForCurrentTenantAsync(
            BookStoreSettings.MaxUploadSizeMb, sizeMb.ToString());
    }

    // Set for a specific user
    public async Task SetUserPreferenceAsync(Guid userId, string value)
    {
        await _settingManager.SetForUserAsync(userId, BookStoreSettings.MaxUploadSizeMb, value);
    }
}
```

---

## 4. Setting Scopes

| Scope | Method | Description |
|---|---|---|
| Global | `SetGlobalAsync` / `GetOrNullGlobalAsync` | Application-wide default |
| Tenant | `SetForCurrentTenantAsync` / `SetForTenantAsync` | Overrides global for one tenant |
| User | `SetForCurrentUserAsync` / `SetForUserAsync` | Overrides tenant for one user |

---

## 5. Encrypted Settings

For secrets (passwords, API keys), set `isEncrypted: true` in the definition:

```csharp
new SettingDefinition(
    BookStoreSettings.SmtpPassword,
    isEncrypted: true   // value is encrypted in the database using ABP's IStringEncryptionService
)
```

Configure the encryption passphrase in `appsettings.json`:

```json
{
  "StringEncryption": {
    "DefaultPassPhrase": "change-this-in-production-use-a-long-random-string"
  }
}
```

---

## 6. Localization keys for settings

Add to `en.json`:

```json
{
  "Setting:SmtpHost":              "SMTP Server Host",
  "Setting:SmtpHost.Description":  "Hostname or IP of the outgoing mail server",
  "Setting:MaxUploadSizeMb":       "Max Upload Size (MB)"
}
```

---

## Key Rules

- **DO** define setting names as constants in a static class (`BookStoreSettings`)
- **DO** place `SettingDefinitionProvider` in `Domain.Shared` or `Application.Contracts`
- **DO** use `ISettingProvider` (read-only, respects scope hierarchy) in most code
- **DO** use `ISettingManager` (read/write, explicit scope) only in admin/management services
- **DO** set `isEncrypted: true` for passwords and API keys
- **DO NOT** read settings via `IConfiguration` directly — always go through `ISettingProvider`
- **DO NOT** expose `ISettingManager` through Auto API Controllers to non-admin users — always check permissions first
