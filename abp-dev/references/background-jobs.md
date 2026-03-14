# ABP: Background Jobs & Workers

## One-Off Background Jobs

Use for fire-and-forget tasks (send email, process upload, etc.).

### 1. Define the args class (Domain or Application.Contracts)

```csharp
// Simple serializable POCO — no ABP base class needed
public class WelcomeEmailArgs
{
    public Guid UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
}
```

### 2. Implement the job (Application layer)

```csharp
using System.Threading.Tasks;
using Volo.Abp.BackgroundJobs;
using Volo.Abp.DependencyInjection;

namespace Acme.BookStore.Users;

public class WelcomeEmailJob : AsyncBackgroundJob<WelcomeEmailArgs>, ITransientDependency
{
    private readonly IEmailSender _emailSender;

    public WelcomeEmailJob(IEmailSender emailSender)
    {
        _emailSender = emailSender;
    }

    public override async Task ExecuteAsync(WelcomeEmailArgs args)
    {
        await _emailSender.SendAsync(
            args.Email,
            "Welcome!",
            $"Hi {args.UserName}, welcome to BookStore!"
        );
    }
}
```

### 3. Enqueue from an Application Service

```csharp
public class UserAppService : ApplicationService
{
    private readonly IBackgroundJobManager _backgroundJobManager;

    public UserAppService(IBackgroundJobManager backgroundJobManager)
    {
        _backgroundJobManager = backgroundJobManager;
    }

    public async Task RegisterAsync(RegisterUserDto input)
    {
        // ... create user logic ...

        // Enqueue — executes asynchronously after this request completes
        await _backgroundJobManager.EnqueueAsync(new WelcomeEmailArgs
        {
            UserId   = newUser.Id,
            Email    = input.Email,
            UserName = input.UserName
        });
    }
}
```

### 4. Module configuration

```csharp
// ABP's default in-process job manager is enabled automatically.
// For production, swap to Hangfire or Quartz:
[DependsOn(typeof(AbpHangfireModule))]
public class BookStoreApplicationModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpBackgroundJobOptions>(options =>
        {
            options.IsJobExecutionEnabled = true;  // default: true
        });

        // Use Hangfire as the background job store
        var configuration = context.Services.GetConfiguration();
        context.Services.AddHangfire(config =>
            config.UseSqlServerStorage(configuration.GetConnectionString("Default"))
        );
    }
}
```

**Job providers:**
| Package | When to use |
|---|---|
| `Volo.Abp.BackgroundJobs` | Default in-process, dev/simple apps |
| `Volo.Abp.BackgroundJobs.HangFire` | Production, persistent, UI dashboard |
| `Volo.Abp.BackgroundJobs.Quartz` | Cron-like scheduling, complex triggers |

---

## Recurring Background Workers

Use for periodic tasks (cleanup, reports, health checks).

### Implement the worker (Application or Domain layer)

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Volo.Abp.BackgroundWorkers;
using Volo.Abp.Threading;

namespace Acme.BookStore.Products;

public class ZeroStockArchiveWorker : AsyncPeriodicBackgroundWorkerBase
{
    public ZeroStockArchiveWorker(AbpAsyncTimer timer, IServiceScopeFactory serviceScopeFactory)
        : base(timer, serviceScopeFactory)
    {
        Timer.Period = 10 * 60 * 1000;  // 10 minutes in milliseconds
    }

    protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
    {
        Logger.LogInformation("ZeroStockArchiveWorker running...");

        // Resolve scoped services inside DoWorkAsync — never inject them in constructor
        var productRepo = workerContext.ServiceProvider
            .GetRequiredService<IProductRepository>();

        var zeroStockProducts = await productRepo.GetZeroStockListAsync();
        foreach (var product in zeroStockProducts)
        {
            product.Archive();
            await productRepo.UpdateAsync(product);
        }

        Logger.LogInformation($"Archived {zeroStockProducts.Count} zero-stock products.");
    }
}
```

### Register in the module

```csharp
public override async Task OnApplicationInitializationAsync(
    ApplicationInitializationContext context)
{
    await context.AddBackgroundWorkerAsync<ZeroStockArchiveWorker>();
}
```

**Key rules for workers:**
- **DO** use `AsyncPeriodicBackgroundWorkerBase` for most scenarios
- **DO** resolve scoped services via `workerContext.ServiceProvider` (never inject in constructor)
- **DO** set `Timer.Period` in milliseconds in the constructor
- **DO NOT** perform long-running synchronous work — always use async
- **DO NOT** throw unhandled exceptions — log and recover gracefully

---

## Disabling Background Jobs (testing)

```csharp
// In test module or appsettings
Configure<AbpBackgroundJobOptions>(options =>
{
    options.IsJobExecutionEnabled = false;  // jobs enqueued but never executed
});
```
