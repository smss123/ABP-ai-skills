# ABP: Global Features

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/global-features
>
> Fetch this page for the latest API details before generating global-feature code.

---

## What Are Global Features?

Global Features are **compile-time / startup-time** switches that permanently enable or disable parts of a module. They affect:

- Which services are registered in the DI container
- Which database tables/columns are created by EF Core migrations

This makes them fundamentally different from the runtime [Features](settings.md) system:

| | Global Features | Runtime Features |
|---|---|---|
| Set at | App startup (PreConfigureServices) | Runtime (per-tenant, per-user) |
| Effect | DI registration + schema | Business logic gates only |
| Use case | Optional module capabilities | Tenant plan / license gating |

> If you need to enable/disable functionality per-tenant at runtime, use **Features** (`IFeatureChecker`), not Global Features.

---

## Defining a Global Feature

```csharp
// Domain.Shared or the module that owns the feature
[GlobalFeatureName("Shopping.Payment")]
public class PaymentFeature { }
```

Group multiple features under a module class for convenience:

```csharp
public class EcommerceModuleFeatures : GlobalModuleFeatures
{
    public const string ModuleName = "Ecommerce";

    public PaymentFeature    Payment    => GetFeature<PaymentFeature>();
    public SubscriptionFeature Subscription => GetFeature<SubscriptionFeature>();

    public EcommerceModuleFeatures(GlobalFeatureManager manager)
        : base(manager) { }
}
```

---

## Enabling / Disabling Features

Configure in the **host application's** module `PreConfigureServices` — must run before any module initializes services:

```csharp
public class MyAppModule : AbpModule
{
    private static readonly OneTimeRunner OneTimeRunner = new OneTimeRunner();

    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        OneTimeRunner.Run(() =>
        {
            GlobalFeatureManager.Instance.Enable<PaymentFeature>();

            // Or by name string
            GlobalFeatureManager.Instance.Disable("Shopping.Payment");

            // Via module extension methods (if the module provides them)
            GlobalFeatureManager.Instance.Modules().Ecommerce().Payment.Enable();
        });
    }
}
```

> Use `OneTimeRunner` to ensure the configuration block runs exactly once even if the module is initialized multiple times.

---

## Checking Feature Status

### Programmatic check

```csharp
if (GlobalFeatureManager.Instance.IsEnabled<PaymentFeature>())
{
    // feature is enabled
}
```

### Declarative guard (controller / page)

```csharp
[RequiresGlobalFeature(typeof(PaymentFeature))]
public class PaymentController : AbpController
{
    // Returns HTTP 404 if PaymentFeature is disabled
}
```

---

## Key Rules

- **DO** configure Global Features in `PreConfigureServices` with `OneTimeRunner` — never in `ConfigureServices`
- **DO NOT** use Global Features as a runtime flag — they are fixed at startup
- **DO** use `[RequiresGlobalFeature]` on controllers/pages to auto-return 404 when disabled
- **DO** use runtime **Features** (`IFeatureChecker`) when you need per-tenant or per-user gating
