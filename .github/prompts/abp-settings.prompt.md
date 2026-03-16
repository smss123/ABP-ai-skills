---
mode: 'agent'
description: 'Scaffold ABP Framework settings — SettingDefinitionProvider, ISettingProvider (read), ISettingManager (write)'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold the **ABP settings system** for the feature the user describes.

If no feature name or setting names were provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/settings.md` and fetch https://docs.abp.io/en/abp/latest/Settings for the latest API details.

---

## Step 1 — Gather requirements

Ask the user:
1. **Feature/group name** (e.g. `Email`, `BookStore`, `Notifications`)
2. **Settings to define** — for each: name, default value, description, visible to clients? encrypted?
3. **Scopes needed** — Global only, or also Tenant and User overrides?

---

## Step 2 — Create `BookStoreSettings.cs` (Domain.Shared or Application.Contracts)

```csharp
namespace Acme.BookStore.Settings;

public static class BookStoreSettings
{
    private const string Prefix = "BookStore";

    public const string SmtpHost        = Prefix + ".SmtpHost";
    public const string MaxUploadSizeMb = Prefix + ".MaxUploadSizeMb";
    // add more constants here
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

ABP auto-discovers `SettingDefinitionProvider` — no registration needed.

---

## Step 4 — Read settings with ISettingProvider

```csharp
// In an application service or page model
var host   = await _settingProvider.GetOrNullAsync(BookStoreSettings.SmtpHost);
var maxMb  = await _settingProvider.GetAsync<int>(BookStoreSettings.MaxUploadSizeMb);
```

---

## Step 5 — Write settings with ISettingManager (admin only)

```csharp
// Global scope
await _settingManager.SetGlobalAsync(BookStoreSettings.SmtpHost, "mail.example.com");

// Tenant scope
await _settingManager.SetForCurrentTenantAsync(BookStoreSettings.MaxUploadSizeMb, "50");

// User scope
await _settingManager.SetForCurrentUserAsync(BookStoreSettings.MaxUploadSizeMb, "5");
```

---

## Step 6 — Localization keys

Add to `en.json`:

```json
{
  "Setting:SmtpHost":        "SMTP Server Host",
  "Setting:MaxUploadSizeMb": "Max Upload Size (MB)"
}
```

---

## After generating

Remind the user:
- Always check permissions before calling `ISettingManager` in API endpoints.
- Encrypted settings need `"StringEncryption": { "DefaultPassPhrase": "..." }` in `appsettings.json`.
- `isVisibleToClients: true` settings are exposed at `/api/abp/application-configuration` and via `abp.setting.get()` in JavaScript.
