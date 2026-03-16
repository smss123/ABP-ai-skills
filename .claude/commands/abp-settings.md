You are an expert ABP Framework developer. Scaffold the **ABP settings system** for the feature: $ARGUMENTS

If no feature or setting names were provided, ask for:
1. Feature/group name (e.g. `Email`, `Notifications`, `BookStore`)
2. Settings to define — for each: name, default value, visible to JS clients? encrypted?
3. Scopes needed — Global / Tenant / User

## Before generating any code

Read `abp-dev/references/settings.md` and fetch https://docs.abp.io/en/abp/latest/Settings for the latest API details.

---

## What to generate

### 1. `BookStoreSettings.cs` — constant names (Domain.Shared or Application.Contracts)

```csharp
namespace Acme.BookStore.Settings;

public static class BookStoreSettings
{
    private const string Prefix = "BookStore";

    public const string SmtpHost        = Prefix + ".SmtpHost";
    public const string MaxUploadSizeMb = Prefix + ".MaxUploadSizeMb";
}
```

---

### 2. `BookStoreSettingDefinitionProvider.cs`

```csharp
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
                isVisibleToClients: false
            ),
            new SettingDefinition(
                BookStoreSettings.MaxUploadSizeMb,
                defaultValue: "10",
                displayName: L("Setting:MaxUploadSizeMb"),
                isVisibleToClients: true
            )
        );
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

ABP auto-discovers `SettingDefinitionProvider` — no manual registration needed.

---

### 3. Read settings — `ISettingProvider` (in app services / page models)

```csharp
var host  = await _settingProvider.GetOrNullAsync(BookStoreSettings.SmtpHost);
var maxMb = await _settingProvider.GetAsync<int>(BookStoreSettings.MaxUploadSizeMb);
```

Scope priority: **User → Tenant → Global → Default**

---

### 4. Write settings — `ISettingManager` (admin/management services only)

```csharp
await _settingManager.SetGlobalAsync(BookStoreSettings.SmtpHost, "mail.example.com");
await _settingManager.SetForCurrentTenantAsync(BookStoreSettings.MaxUploadSizeMb, "50");
await _settingManager.SetForCurrentUserAsync(BookStoreSettings.MaxUploadSizeMb, "5");
```

---

### 5. Localization keys — add to `en.json`

```json
{
  "Setting:SmtpHost":        "SMTP Server Host",
  "Setting:MaxUploadSizeMb": "Max Upload Size (MB)"
}
```

---

## Key rules to enforce

- Setting name constants go in `Domain.Shared` or `Application.Contracts` (not `Domain`)
- Use `ISettingProvider` for all read operations — it respects the User→Tenant→Global hierarchy
- Use `ISettingManager` only in admin/management contexts; always check permissions first
- `isEncrypted: true` requires `StringEncryption.DefaultPassPhrase` in `appsettings.json`
- `isVisibleToClients: true` exposes the value via `abp.setting.get('...')` in JavaScript
