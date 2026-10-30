---
applies_to_abp: "9.x - 10.x"
doc_verified_on: "2026-10-29"
docs:
  - https://abp.io/docs/latest/framework/infrastructure/background-workers
  - https://abp.io/docs/latest/framework/infrastructure/background-jobs
---

# ABP: Background Workers (recurring / scheduled)

> 📖 Official docs (verified live against ABP 10.x):
> - Background workers: https://abp.io/docs/latest/framework/infrastructure/background-workers
> - Background jobs (one-off, queued): https://abp.io/docs/latest/framework/infrastructure/background-jobs
>
> **Two different systems.** *Jobs* are fire-and-forget work items handed to a queue (RabbitMQ,
> Redis/Hangfire, …) and handled by `AsyncBackgroundJob<TArgs>` — see `background-jobs.md`.
> *Workers* are long-lived, periodically-running tasks inside the process. Fetch the page before
> picking one.

---

## Names you need

| Name | Purpose |
|---|---|
| `IBackgroundWorker` | core interface for every worker |
| `BackgroundWorkerBase` | non-async base with `StartAsync`/`StopAsync` |
| `AsyncPeriodicBackgroundWorkerBase` | **the recurring worker base class** — set `Timer.Period`, implement `DoWorkAsync` |
| `AbpAsyncTimer` | the thread-safe timer behind periodic workers (`Timer.Change(...)` for intervals) |
| `PeriodicBackgroundWorkerContext` | passed into `DoWorkAsync`; exposes `ServiceProvider` for scoped resolution |
| `IServiceScopeFactory` | creates the per-run scope a worker needs to resolve scoped services |
| `IBackgroundWorkerManager` | registers/starts workers; `AddBackgroundWorkerAsync<T>()` |
| `IDynamicBackgroundWorkerManager` | register/remove/update workers **at runtime** |
| `DynamicBackgroundWorkerSchedule` | schedule for a dynamic worker — period **or** `CronExpression` |
| `DynamicBackgroundWorkerExecutionContext` | context handed to a dynamic worker handler |
| `AbpBackgroundWorkersModule` | the module dependency that provides all of this |
| `AbpBackgroundWorkerOptions.IsEnabled` | global switch — false disables every worker |
| `AbpBackgroundJobWorkerOptions.ApplicationName` | queue-name isolation per application |
| `AbpHangfireOptions.DefaultQueuePrefix`, `AbpQuartzOptions`, `quartz.scheduler.instanceName`, `AbpRabbitMqBackgroundJobOptions.DefaultQueueNamePrefix` / `DefaultDelayedQueueNamePrefix` | provider-level isolation keys when several apps share infrastructure |

---

## A periodic worker

```csharp
public class CleanupExpiredSessionsWorker : AsyncPeriodicBackgroundWorkerBase
{
    public CleanupExpiredSessionsWorker(
        AbpAsyncTimer timer,
        IServiceScopeFactory serviceScopeFactory)
        : base(timer, serviceScopeFactory)
    {
        Timer.Period = 5 * 60 * 1000; // milliseconds
    }

    [UnitOfWork]
    public override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
    {
        var repo = workerContext.ServiceProvider.GetRequiredService<ISessionRepository>();
        await repo.DeleteExpiredAsync(Clock.Now.AddDays(-1));
    }
}

// Registration — in OnApplicationInitializationAsync, not ConfigureServices
public override async Task OnApplicationInitializationAsync(ApplicationInitializationContext context)
{
    await context.AddBackgroundWorkerAsync<CleanupExpiredSessionsWorker>();
}
```

## Runtime (dynamic) workers

```csharp
await dynamicWorkerManager.AddAsync(new DynamicBackgroundWorkerRegistrationArgs(
    name: $"Reminder-{jobId}",
    handler: async context => { /* resolve services from context.ServiceProvider */ },
    cronExpression: "0 9 * * *"));

await dynamicWorkerManager.UpdateScheduleAsync(name, periodInMilliseconds: 60_000);
await dynamicWorkerManager.RemoveAsync(name);
```

---

## Rules for recurring work

1. **Idempotent** — a worker run may repeat after a crash or run twice while a deployment rolls.
   Guard with a processed-marker, not with "I remember doing it".
2. **Clustered deployments run every instance.** ABP does not elect one worker: take a
   `IDistributedLock` (`DistributedLocking` is the documented answer) or set
   `AbpBackgroundWorkerOptions.IsEnabled` per application, so only one node does the work.
3. **Resolve services from `workerContext.ServiceProvider`** (or inject the scoped dependency inside a
   unit of work). A worker is a singleton — do not inject a scoped repository into its constructor.
4. Wrap the body in `[UnitOfWork]` so data access gets a transaction and ambient tenancy.
5. **Iterate tenants explicitly** with `ICurrentTenant.Change(...)` when the work is per-tenant; a
   worker runs outside any tenant by default (host side).
6. Catch and log inside the loop; an unhandled exception kills the timer run, and swallowed exceptions
   hide broken jobs.
7. Queue/prefix names (`ApplicationName`, `DefaultQueuePrefix`, instance names) must be unique per app
   when several applications share Redis/RabbitMQ/Quartz/Hangfire.
8. Prefer a **job** when the work belongs to a user action (enqueue + retry + storage), and a **worker**
   when the work is time-driven. Note `TickerQ` is documented as incompatible with dynamic workers.
9. Tests: call `DoWorkAsync` directly with a test `PeriodicBackgroundWorkerContext` — never sleep on a
   timer.

## Phase 0 notes

Look for an existing worker registration block in the Web/Core module's
`OnApplicationInitializationAsync` and extend it; do not add a second `BackgroundService`
(`IHostedService`) beside ABP's worker system, and never reintroduce a hand-rolled
`Timer`/`Task.Delay` loop when `AsyncPeriodicBackgroundWorkerBase` already handles lifetime,
scoping and disposal.
