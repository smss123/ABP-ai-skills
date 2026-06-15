# ABP: Options Pattern

> 📖 Official docs:
> - Options: https://abp.io/docs/latest/framework/fundamentals/options
> - Microsoft Options docs: https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options
>
> Fetch the ABP page for the latest API details before generating options/configuration code.

## Overview

ABP uses Microsoft's `IOptions<T>` pattern with two ABP-specific additions:
- `Configure<T>()` — composable version of `services.Configure<T>()`, works across modules
- `PreConfigure<T>()` — queue actions **before** the DI container is built, for conditional service registration

---

## Defining an Options Class

Plain C# class — no base class needed.

```csharp
// Application/MyModuleOptions.cs
public class MyModuleOptions
{
    public bool IsFeatureEnabled { get; set; } = true;
    public int MaxRetryCount { get; set; } = 3;
    public string ApiKey { get; set; } = string.Empty;
}
```

---

## Configuring Options in a Module

```csharp
public class BookStoreWebModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<MyModuleOptions>(options =>
        {
            options.IsFeatureEnabled = true;
            options.MaxRetryCount = 5;
        });
    }
}
```

Multiple modules can call `Configure<T>` — actions are applied in dependency order (deepest first).

---

## Reading Options (Injection)

```csharp
public class BookAppService : ApplicationService
{
    private readonly MyModuleOptions _options;

    public BookAppService(IOptions<MyModuleOptions> options)
    {
        _options = options.Value;
    }

    public Task DoSomethingAsync()
    {
        if (_options.IsFeatureEnabled)
        {
            // ...
        }
        return Task.CompletedTask;
    }
}
```

---

## Pre-Configuration Pattern

Use `PreConfigure<T>` when you need option values **during** service registration (e.g., conditionally adding services).

### Step 1 — Define a Pre-Options Class

```csharp
public class MyModulePreOptions
{
    public bool UseCustomEmailSender { get; set; }
}
```

### Step 2 — Queue the Pre-Configuration

```csharp
// In the consuming module (before DI builds)
public class BookStoreApplicationModule : AbpModule
{
    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        PreConfigure<MyModulePreOptions>(options =>
        {
            options.UseCustomEmailSender = true;
        });
    }
}
```

### Step 3 — Read in `ConfigureServices`

```csharp
// In your library module
public class MyLibraryModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        var preOptions = context.Services.ExecutePreConfiguredActions<MyModulePreOptions>();

        if (preOptions.UseCustomEmailSender)
        {
            context.Services.AddTransient<IEmailSender, CustomEmailSender>();
        }
        else
        {
            context.Services.AddTransient<IEmailSender, DefaultEmailSender>();
        }
    }
}
```

---

## Common ABP Options Classes

| Class | Purpose |
|---|---|
| `AbpDbConnectionOptions` | Connection string mapping |
| `AbpLocalizationOptions` | Languages, resources |
| `AbpNavigationOptions` | Menu contributors |
| `AbpBundlingOptions` | CSS/JS bundles |
| `AbpThemingOptions` | Theme registration |
| `AbpBackgroundJobOptions` | Job execution toggle |
| `AbpMultiTenancyOptions` | Enable/disable multi-tenancy |
| `AbpAuditingOptions` | Audit log configuration |
| `AbpClaimsPrincipalFactoryOptions` | Dynamic claims |

---

## Key Rules

- **DO** use `Configure<T>()` in module `ConfigureServices` — it's composable across the module graph
- **DO** use `PreConfigure<T>()` only when you need values during service registration
- **DO NOT** inject `IOptions<T>` in singleton services that need live reload — use `IOptionsMonitor<T>` instead
- **DO NOT** read `IConfiguration` directly in domain/application layers — wrap in an options class
