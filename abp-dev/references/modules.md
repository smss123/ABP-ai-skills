# ABP: Module System

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
    // Phase 1 — configure services (DI container is being built)
    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        // Register conventional controllers BEFORE ConfigureServices so other modules can see them
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
