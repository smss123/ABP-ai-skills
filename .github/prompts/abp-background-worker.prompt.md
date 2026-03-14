---
mode: 'agent'
description: 'Scaffold an ABP Framework background job (fire-and-forget) or periodic background worker'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold a **background job or background worker** for the task the user describes.

If the job/worker name or purpose has not been provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/background-jobs.md` and fetch:
- https://docs.abp.io/en/abp/latest/Background-Jobs
- https://docs.abp.io/en/abp/latest/Background-Workers

First, ask the user which type they need:
- **Background Job** — fire-and-forget, enqueued from application code, executes once
- **Background Worker** — runs on a recurring timer (periodic tasks: cleanup, reporting, health checks)

Replace `<Job>` / `<Worker>` with the PascalCase name for the job or worker.

---

## Option A — Background Job (fire-and-forget)

### 1. `src/Acme.BookStore.Application/<Feature>/<Job>Args.cs`

```csharp
namespace Acme.BookStore.<Feature>;

// Plain serializable POCO — must be JSON-serializable (public props, parameterless ctor)
public class <Job>Args
{
    public Guid /* relevant */ Id { get; set; }
    // Add all data the job needs to run — keep it minimal (IDs, not full entities)
}
```

### 2. `src/Acme.BookStore.Application/<Feature>/<Job>Job.cs`

```csharp
using System.Threading.Tasks;
using Volo.Abp.BackgroundJobs;
using Volo.Abp.DependencyInjection;

namespace Acme.BookStore.<Feature>;

public class <Job>Job : AsyncBackgroundJob<<Job>Args>, ITransientDependency
{
    // Inject dependencies needed to do the work
    private readonly ISomeService _someService;

    public <Job>Job(ISomeService someService)
    {
        _someService = someService;
    }

    public override async Task ExecuteAsync(<Job>Args args)
    {
        // Do the work here — args contains the data passed at enqueue time
        await _someService.DoWorkAsync(args.Id);
    }
}
```

### 3. Enqueue from an application service

```csharp
// Inject IBackgroundJobManager into the app service
await _backgroundJobManager.EnqueueAsync(new <Job>Args
{
    Id = entity.Id
    // set other args properties
});
```

---

## Option B — Periodic Background Worker

### `src/Acme.BookStore.Application/<Feature>/<Worker>Worker.cs`

```csharp
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Volo.Abp.BackgroundWorkers;
using Volo.Abp.Threading;

namespace Acme.BookStore.<Feature>;

public class <Worker>Worker : AsyncPeriodicBackgroundWorkerBase
{
    public <Worker>Worker(AbpAsyncTimer timer, IServiceScopeFactory serviceScopeFactory)
        : base(timer, serviceScopeFactory)
    {
        Timer.Period = 10 * 60 * 1000; // 10 minutes — adjust as needed
    }

    protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
    {
        Logger.LogInformation("<Worker>Worker is running...");

        // ALWAYS resolve scoped services here — never inject in the constructor
        var repository = workerContext.ServiceProvider
            .GetRequiredService<I<Entity>Repository>();

        // Do the periodic work
    }
}
```

### Register the worker in your module

```csharp
public override async Task OnApplicationInitializationAsync(
    ApplicationInitializationContext context)
{
    await context.AddBackgroundWorkerAsync<<Worker>Worker>();
}
```

**Key rules:**
- Resolve all scoped services via `workerContext.ServiceProvider` — **not** the constructor
- Set `Timer.Period` in **milliseconds**
- Always use `async` / `await` — never block
- Catch and log exceptions; do not let them bubble up unhandled

---

## After generating

For background jobs, also ask whether the user wants to switch the default in-process store to **Hangfire** or **Quartz** for production use. Reference `abp-dev/references/background-jobs.md` for the module config snippet.
