# ABP: Features System & Feature Management Module

> 📖 Official docs:
> - Features system: https://abp.io/docs/latest/framework/infrastructure/features
> - Feature Management module: https://abp.io/docs/latest/modules/feature-management
>
> Fetch these pages for the latest API details before generating feature-gating code.

---

## Distinction

| | Features System | Feature Management Module |
|---|---|---|
| **Purpose** | Runtime checking — is a feature on/off? | Persistent storage of feature values per tenant/edition |
| **Key interface** | `IFeatureChecker` | `IFeatureManager` |
| **Where defined** | `FeatureDefinitionProvider` in Domain.Shared | Pre-installed module with DB tables |
| **Multi-tenancy** | Checks resolved per-tenant | Stores values per-tenant via `TenantFeatureManagementProvider` |

---

## Defining Features

```csharp
// Domain.Shared/Features/MyFeatureDefinitionProvider.cs
public class MyFeatureDefinitionProvider : FeatureDefinitionProvider
{
    public override void Define(IFeatureDefinitionContext context)
    {
        var group = context.AddGroup("MyApp");

        group.AddFeature(
            "MyApp.PdfExport",
            defaultValue: "false",
            displayName: LocalizableString.Create<MyAppResource>("Feature:PdfExport")
        );

        // Toggle feature (true/false)
        group.AddFeature(
            "MyApp.MaxProductCount",
            defaultValue: "10",
            valueType: new FreeTextStringValueType(new NumericValueValidator(0, 1000))
        );
    }
}
```

---

## Checking Features at Runtime (`IFeatureChecker`)

### In application services / domain services

```csharp
public class ReportAppService : ApplicationService
{
    public async Task<byte[]> ExportAsPdfAsync()
    {
        await FeatureChecker.CheckEnabledAsync("MyApp.PdfExport");
        // throws AbpAuthorizationException if feature is off
        ...
    }

    public async Task<bool> CanExportAsync()
        => await FeatureChecker.IsEnabledAsync("MyApp.PdfExport");

    public async Task<string> GetMaxCountAsync()
        => await FeatureChecker.GetOrNullAsync("MyApp.MaxProductCount");
}
```

`ApplicationService` exposes `FeatureChecker` as a base property — no injection needed.

### Attribute on application service methods

```csharp
[RequiresFeature("MyApp.PdfExport")]
public async Task<byte[]> ExportAsPdfAsync() { ... }
```

---

## Feature Management — Storing Values (`IFeatureManager`)

`IFeatureManager` is for **admin operations** that change feature values at runtime (e.g. tenant provisioning, edition management).

```csharp
private readonly IFeatureManager _featureManager;

// Enable PDF export for a specific tenant
await _featureManager.SetForTenantAsync(
    tenantId,
    "MyApp.PdfExport",
    "true"
);

// Read stored value for a tenant
var value = await _featureManager.GetOrNullForTenantAsync(
    "MyApp.PdfExport",
    tenantId
);
```

---

## Feature Value Provider Resolution Order

ABP resolves a feature value by checking providers in this order — first non-null value wins:

1. `DefaultValueFeatureManagementProvider` — hard-coded default (read-only)
2. `ConfigurationFeatureManagementProvider` — from `appsettings.json`
3. `EditionFeatureManagementProvider` — edition-level override
4. `TenantFeatureManagementProvider` — per-tenant stored value (highest priority)

### Override via `appsettings.json`

```json
{
  "Features": {
    "MyApp.PdfExport": "true"
  }
}
```

---

## Custom Feature Value Provider

```csharp
public class MyCustomFeatureManagementProvider : FeatureManagementProvider
{
    public override string Name => "MyCustom";

    protected override Task<string?> GetValueOrNullAsync(
        string name,
        string providerKey,
        CancellationToken cancellationToken = default)
    {
        // Return null to pass to next provider
        return Task.FromResult<string?>(null);
    }
}

// Register in module
Configure<FeatureManagementOptions>(options =>
{
    options.Providers.Add<MyCustomFeatureManagementProvider>();
});
```

---

## Tying Features to Permissions

```csharp
// In PermissionDefinitionProvider
booksPermission.WithFeatures("BookManagement");
```

The permission returns `Undefined` (not granted) when the feature is off, hiding it from the UI.

---

## Key Rules

- **DO** define features in `Domain.Shared` via `FeatureDefinitionProvider`
- **DO** use `IFeatureChecker.CheckEnabledAsync()` for guarding operations — it throws the right exception
- **DO** use `IFeatureManager.SetForTenantAsync()` only in admin/provisioning flows — not in regular app code
- **DO NOT** hardcode feature names as strings in multiple places — define constants in Domain.Shared
- **DO** use `[RequiresFeature]` on application service methods as the declarative alternative to programmatic checks
