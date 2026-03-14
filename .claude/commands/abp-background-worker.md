You are an expert ABP Framework developer. Scaffold a **background job or background worker** named: $ARGUMENTS

If the job/worker name or purpose was not provided, ask before proceeding.

Read `abp-dev/references/background-jobs.md` before generating any code.

First, clarify which type the user needs:
- **Background Job** — fire-and-forget, enqueued manually, executes once
- **Background Worker** — periodic, runs on a timer automatically

## Option A — Background Job

### 1. Args class: `src/Acme.BookStore.Application/<Feature>/<Job>Args.cs`

- Plain serializable POCO (public props, parameterless constructor)
- Contains only the data the job needs (IDs, not full entities)

### 2. Job class: `src/Acme.BookStore.Application/<Feature>/<Job>Job.cs`

```csharp
public class <Job>Job : AsyncBackgroundJob<<Job>Args>, ITransientDependency
{
    // Inject dependencies
    public <Job>Job(/* deps */) { ... }

    public override async Task ExecuteAsync(<Job>Args args)
    {
        // Do the work
    }
}
```

### 3. Enqueue snippet (from application service)

```csharp
await _backgroundJobManager.EnqueueAsync(new <Job>Args { /* fill args */ });
```

## Option B — Periodic Background Worker

### `src/Acme.BookStore.Application/<Feature>/<Worker>Worker.cs`

```csharp
public class <Worker>Worker : AsyncPeriodicBackgroundWorkerBase
{
    public <Worker>Worker(AbpAsyncTimer timer, IServiceScopeFactory serviceScopeFactory)
        : base(timer, serviceScopeFactory)
    {
        Timer.Period = 10 * 60 * 1000; // milliseconds
    }

    protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
    {
        Logger.LogInformation("<Worker>Worker running...");
        // Resolve scoped services here — never in the constructor
        var repo = workerContext.ServiceProvider.GetRequiredService<I<Entity>Repository>();
        // Do the periodic work
    }
}
```

### Module registration

```csharp
public override async Task OnApplicationInitializationAsync(ApplicationInitializationContext context)
    => await context.AddBackgroundWorkerAsync<<Worker>Worker>();
```

**Key rules:**
- Resolve scoped services via `workerContext.ServiceProvider` — NOT in the constructor
- `Timer.Period` is in **milliseconds**
- Always `async` — never block
- Catch exceptions; do not let them propagate unhandled

## After generating

Ask whether the user wants to use **Hangfire** or **Quartz** for production background jobs. Refer to `abp-dev/references/background-jobs.md` for the module config snippet.
