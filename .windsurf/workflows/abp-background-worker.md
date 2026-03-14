---
name: abp-background-worker
description: Scaffold an ABP background job (fire-and-forget) or periodic background worker
---

# ABP Background Job / Worker Scaffold

A Windsurf Cascade workflow that creates either a fire-and-forget background job or a periodic background worker.

## Inputs

Before starting, ask the user:
1. **Job or Worker name** (PascalCase, e.g. `SendWelcomeEmail`, `ZeroStockArchive`)
2. **Type**: Background **Job** (fire-and-forget) or Background **Worker** (periodic timer)?
3. For jobs: what **data** does it need? (determines args class properties)
4. For workers: what **timer interval** in minutes?
5. What feature folder should it live in? (e.g. `Users`, `Products`)

---

## Step 1 — Read reference file

Read `abp-dev/references/background-jobs.md`.

---

## Option A — Background Job

### Step 2 — Create `src/Acme.BookStore.Application/<Feature>/<Job>Args.cs`
- Plain serializable POCO; public properties, parameterless constructor
- Include only data needed by the job (IDs, not entities)

### Step 3 — Create `src/Acme.BookStore.Application/<Feature>/<Job>Job.cs`
```csharp
public class <Job>Job : AsyncBackgroundJob<<Job>Args>, ITransientDependency
{
    // inject dependencies
    public override async Task ExecuteAsync(<Job>Args args) { /* do work */ }
}
```

### Step 4 — Show enqueue snippet
```csharp
await _backgroundJobManager.EnqueueAsync(new <Job>Args { /* fill props */ });
```

---

## Option B — Periodic Background Worker

### Step 2 — Create `src/Acme.BookStore.Application/<Feature>/<Worker>Worker.cs`
```csharp
public class <Worker>Worker : AsyncPeriodicBackgroundWorkerBase
{
    public <Worker>Worker(AbpAsyncTimer timer, IServiceScopeFactory serviceScopeFactory)
        : base(timer, serviceScopeFactory)
    {
        Timer.Period = /* interval */ * 60 * 1000;  // milliseconds
    }

    protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
    {
        Logger.LogInformation("<Worker>Worker running...");
        var repo = workerContext.ServiceProvider.GetRequiredService<I<Entity>Repository>();
        // do periodic work
    }
}
```

### Step 3 — Show module registration snippet
```csharp
public override async Task OnApplicationInitializationAsync(ApplicationInitializationContext context)
    => await context.AddBackgroundWorkerAsync<<Worker>Worker>();
```

---

## Step 5 — Confirm

Ask whether the user wants to configure **Hangfire** or **Quartz** as the background job store for production. Reference `abp-dev/references/background-jobs.md` for the module config.
