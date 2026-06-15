# ABP: Module System

> 📖 Official docs:
> - Module Development Basics: https://docs.abp.io/en/abp/latest/Module-Development-Basics
> - Dependency Injection: https://docs.abp.io/en/abp/latest/Dependency-Injection
> - Configuration: https://docs.abp.io/en/abp/latest/Configuration
>
> Fetch these pages for the latest API details before generating module or startup code.

## Module Class Basics

Every ABP project has exactly one class derived from `AbpModule`. This is the entry point
for dependency registration and application startup.

```csharp
using Volo.Abp.Modularity;

namespace Acme.BookStore;

[DependsOn(
    typeof(AbpAspNetCoreMvcModule),
    typeof(AbpAutofacModule),
    typeof(BookStoreDomainModule),
    typeof(BookStoreApplicationModule),
    typeof(BookStoreEntityFrameworkCoreModule)
)]
public class BookStoreWebModule : AbpModule
{
    // Phase 1a — pre-configuration (runs before ConfigureServices of all modules)
    // Override PreConfigureServices and use the inherited PreConfigure<TOptions>() method
    // to queue option actions before the DI container is fully built.
    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        // Conventional controllers must be registered here (not in ConfigureServices) so that
        // all other modules in the dependency graph can discover the auto-generated routes
        // and apply their own middleware/policies during their own ConfigureServices phase.
        // PreConfigure<T>() (inherited from AbpModule) enqueues the action at the pre-build stage.
        PreConfigure<AbpAspNetCoreMvcOptions>(options =>
        {
            options.ConventionalControllers
                   .Create(typeof(BookStoreApplicationModule).Assembly);
        });
    }

    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        // Standard Microsoft DI also works
        context.Services.AddHttpClient();
    }

    // Phase 2 — application pipeline (DI container is ready, IServiceProvider available)
    public override void OnApplicationInitialization(ApplicationInitializationContext context)
    {
        var app = context.GetApplicationBuilder();
        var env = context.GetEnvironment();

        if (env.IsDevelopment())
            app.UseDeveloperExceptionPage();
        else
            app.UseHsts();

        app.UseHttpsRedirection();
        app.UseStaticFiles();
        app.UseRouting();
        app.UseAuthentication();
        app.UseAuthorization();
        app.UseConfiguredEndpoints();   // ABP's endpoint configurator
    }
}
```

---

## Module Lifecycle Hooks (in order)

```
PreConfigureServices     → before ConfigureServices of all modules
ConfigureServices        ← main registration hook
PostConfigureServices    → after ConfigureServices of all modules

OnPreApplicationInitialization   → before OnApplicationInitialization
OnApplicationInitialization      ← main pipeline/startup hook
OnPostApplicationInitialization  → after OnApplicationInitialization

OnApplicationShutdown    ← cleanup
```

Each has an async version (e.g. `ConfigureServicesAsync`). If both sync and async are overridden, only async runs.

---

## DependsOn Attribute

```csharp
// Declare direct dependencies only — ABP resolves the full graph
[DependsOn(
    typeof(AbpDddDomainModule),          // from Volo.Abp.Ddd.Domain package
    typeof(BookStoreDomainSharedModule)
)]
public class BookStoreDomainModule : AbpModule { }
```

ABP initializes modules in dependency order (deepest dependency first).

---

## Typical Module Map (Layered Template)

```
BookStoreWebModule
    → BookStoreApplicationModule
        → BookStoreApplicationContractsModule
            → BookStoreDomainSharedModule
        → BookStoreDomainModule
            → BookStoreDomainSharedModule
    → BookStoreEntityFrameworkCoreModule
        → BookStoreDomainModule
    → AbpAspNetCoreMvcModule
    → AbpAutofacModule
```

---

## Configure<TOptions> Pattern

`Configure<T>` is ABP's fluent way to configure option classes. It's equivalent to
`services.Configure<T>` but more composable across modules.

```csharp
// Set connection string
Configure<AbpDbConnectionOptions>(options =>
{
    options.ConnectionStrings.Default = "Server=...";
});

// Add menu contributor
Configure<AbpNavigationOptions>(options =>
{
    options.MenuContributors.Add(new BookStoreMenuContributor());
});

// Localization
Configure<AbpLocalizationOptions>(options =>
{
    options.Languages.Add(new LanguageInfo("en", "en", "English"));
    options.Resources
        .Add<BookStoreResource>("en")
        .AddBaseTypes(typeof(AbpUiResource))
        .AddVirtualJson("/Localization/BookStore");
});
```

---

## Automatic Dependency Registration

ABP scans the module's assembly and auto-registers any class implementing:

| Interface | Lifetime |
|---|---|
| `ITransientDependency` | Transient |
| `IScopedDependency` | Scoped |
| `ISingletonDependency` | Singleton |

Additionally, classes deriving from `ApplicationService`, `DomainService`, `Repository<>`, etc.
are automatically registered. You rarely need `services.AddTransient<>()` manually.

```csharp
// Auto-registered as Transient:
public class MyService : IMyService, ITransientDependency { }

// Replace an existing ABP service:
[Dependency(ReplaceServices = true)]
public class MyConnectionStringResolver : DefaultConnectionStringResolver { }
```

---

## Plugin Modules (Runtime Loading)

Load modules from external assemblies at startup — useful for extensible/plugin architectures.

```csharp
// Program.cs
await builder.AddApplicationAsync<BookStoreWebModule>(options =>
{
    options.PlugInSources.AddFolder(@"D:\MyPlugins");          // all DLLs in folder
    // options.PlugInSources.AddFile(@"D:\MyPlugins\MyPlugin.dll");
    // options.PlugInSources.AddTypes(typeof(MyPlugInModule));
});
```

### Minimal plugin module

```csharp
// In the plugin DLL
public class MyPlugInModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddTransient<IMyService, MyService>();
    }
}
```

### Razor Pages plugin module

```csharp
public class MyMvcUIPlugInModule : AbpModule
{
    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        PreConfigure<IMvcBuilder>(mvcBuilder =>
        {
            mvcBuilder.PartManager.ApplicationParts.Add(
                new AssemblyPart(typeof(MyMvcUIPlugInModule).Assembly));
            mvcBuilder.PartManager.ApplicationParts.Add(
                new CompiledRazorAssemblyPart(typeof(MyMvcUIPlugInModule).Assembly));
        });
    }
}
```

---

## `[AdditionalAssembly]` Attribute

Register multiple assemblies under a single module — useful when a module spans more than one project:

```csharp
[DependsOn(typeof(AbpAspNetCoreMvcModule))]
[AdditionalAssembly(typeof(BookStoreApplicationModule))] // scan this assembly too
public class BookStoreWebModule : AbpModule { }
```

---

## Module Architecture Best Practices

### Layer package rules

| Layer | Package | Key Rules |
|---|---|---|
| **Domain.Shared** | Enums, consts, error codes | No entities, no business logic |
| **Domain** | Entities, domain services, repo interfaces | Depends only on Domain.Shared |
| **Application.Contracts** | Interfaces, DTOs, permissions | Depends on Domain.Shared only |
| **Application** | App service implementations | Depends on Domain + Application.Contracts |
| **EntityFrameworkCore** | DbContext, migrations, EF repos | Depends on Domain; isolated from Application |
| **HttpApi** | (Optional) manual controllers | Depends on Application.Contracts only |
| **Web** | Razor Pages, menus, UI | Depends on HttpApi package |

```
✓ DO  create a separate ORM integration package (EF Core, MongoDB) per module
✓ DO  create controllers per application service interface
✗ DO NOT  reference Application layer from EntityFrameworkCore
✗ DO NOT  reference Domain layer from Web/HttpApi
```

### Modular Monolith Pattern

Each business domain lives in its own ABP module sub-solution under `modules/`:

```
MySolution/
├── main/               ← host application (references all modules)
│   └── src/
│       └── MySolution.Web/
├── modules/
│   ├── ordering/       ← Ordering module sub-solution
│   │   └── src/
│   │       ├── Ordering.Domain/
│   │       ├── Ordering.Application/
│   │       └── Ordering.EntityFrameworkCore/
│   └── inventory/      ← Inventory module sub-solution
└── etc/                ← shared infra, profiles, deployment
```

Module communication: prefer **distributed events** (`IDistributedEventBus`) over direct service calls to maintain loose coupling, even within a monolith.

---

## Program.cs (ABP startup wiring)

```csharp
// Program.cs (top-level statements)
var builder = WebApplication.CreateBuilder(args);
builder.Host.UseAutofac();  // Autofac DI (recommended by ABP)
await builder.AddApplicationAsync<BookStoreWebModule>();

var app = builder.Build();
await app.InitializeApplicationAsync();
await app.RunAsync();
```
