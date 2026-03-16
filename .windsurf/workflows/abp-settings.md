---
name: abp-settings
description: Scaffold ABP settings — SettingDefinitionProvider, ISettingProvider (read), ISettingManager (write)
---

# ABP Settings Scaffold

A Windsurf Cascade workflow that creates setting constants, a SettingDefinitionProvider, and wires up read/write access.

## Inputs

Before starting, ask the user:
1. **Feature/group name** (e.g. `Email`, `Notifications`)
2. **Settings to define** — for each: name, default value, description, visible to JS clients? encrypted?
3. **Scopes needed** — Global only, or also Tenant and User overrides?

---

## Step 1 — Read reference file

Read `abp-dev/references/settings.md` before generating any code.

---

## Step 2 — Create `BookStoreSettings.cs` (Domain.Shared or Application.Contracts)

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

## Step 3 — Create `BookStoreSettingDefinitionProvider.cs`

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

ABP auto-discovers this class — no module registration needed.

---

## Step 4 — Read with ISettingProvider

```csharp
var host  = await _settingProvider.GetOrNullAsync(BookStoreSettings.SmtpHost);
var maxMb = await _settingProvider.GetAsync<int>(BookStoreSettings.MaxUploadSizeMb);
```

---

## Step 5 — Write with ISettingManager (admin only)

```csharp
await _settingManager.SetGlobalAsync(BookStoreSettings.SmtpHost, "mail.example.com");
await _settingManager.SetForCurrentTenantAsync(BookStoreSettings.MaxUploadSizeMb, "50");
await _settingManager.SetForCurrentUserAsync(BookStoreSettings.MaxUploadSizeMb, "5");
```

---

## Step 6 — Localization keys for `en.json`

```json
{
  "Setting:SmtpHost":        "SMTP Server Host",
  "Setting:MaxUploadSizeMb": "Max Upload Size (MB)"
}
```

---

## Step 7 — Confirm

- `SettingDefinitionProvider` is auto-discovered by ABP — no registration needed
- Always check permissions before exposing `ISettingManager` calls via API
- Encrypted settings require `StringEncryption.DefaultPassPhrase` in `appsettings.json`
