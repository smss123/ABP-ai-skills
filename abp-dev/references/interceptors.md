# ABP: Interceptors

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/interceptors
>
> Fetch this page for the latest API details before generating interceptor code.

---

## What Are Interceptors?

ABP interceptors execute custom logic **before and after** any DI-resolved service method call via Castle DynamicProxy. Unlike MVC filters (controller-only), interceptors apply to **any service in the DI container**.

ABP itself uses interceptors for: Unit of Work, Input Validation, Authorization, Feature gating, and Auditing.

---

## Creating a Custom Interceptor

```csharp
// Inherit AbpInterceptor, register as ITransientDependency
public class ExecutionLogInterceptor : AbpInterceptor, ITransientDependency
{
    private readonly ILogger<ExecutionLogInterceptor> _logger;

    public ExecutionLogInterceptor(ILogger<ExecutionLogInterceptor> logger)
    {
        _logger = logger;
    }

    public override async Task InterceptAsync(IAbpMethodInvocation invocation)
    {
        _logger.LogInformation("Executing: {Method}", invocation.Method.Name);

        await invocation.ProceedAsync();  // call the actual method

        _logger.LogInformation("Executed: {Method}", invocation.Method.Name);
    }
}
```

---

## Registering an Interceptor

Wire the interceptor to target types inside your module's `ConfigureServices` using the `OnRegistered` callback:

```csharp
public override void ConfigureServices(ServiceConfigurationContext context)
{
    context.Services.OnRegistered(ctx =>
    {
        // Apply to all types that implement IMyService
        if (typeof(IMyService).IsAssignableFrom(ctx.ImplementationType))
        {
            ctx.Interceptors.TryAdd<ExecutionLogInterceptor>();
        }
    });
}
```

---

## Intercepting Specific Methods

Inside `InterceptAsync`, inspect `invocation` to conditionally proceed:

```csharp
public override async Task InterceptAsync(IAbpMethodInvocation invocation)
{
    if (invocation.Method.IsDefined(typeof(AuditedAttribute), true))
    {
        // only audit-marked methods
        await LogAsync(invocation.Method.Name);
    }

    await invocation.ProceedAsync();
}
```

---

## Critical Constraints

| Constraint | Detail |
|---|---|
| **Virtual methods only** | Class-based proxies require `virtual`; interface proxies bypass this |
| **DI-resolved only** | `new MyService()` skips interception entirely |
| **Async-first** | Always use `InterceptAsync` and `await invocation.ProceedAsync()` |
| **Not for controllers** | Use ASP.NET Core middleware or action filters instead — interception overhead is higher on hot paths |

### Exclude a type from proxying

```csharp
Configure<AbpDynamicProxyOptions>(options =>
{
    options.IgnoredTypes.Add(typeof(MyHighFrequencyService));
});
```

---

## Key Rules

- **DO** make intercepted service methods `virtual` when using class (not interface) injection
- **DO** apply interceptors in `OnRegistered` — not in `ConfigureServices` directly
- **DO NOT** use interceptors on ASP.NET Core controllers — use middleware or filters
- **DO NOT** intercept high-frequency hot-path methods — each interceptor adds proxy overhead
- **DO** add types to `AbpDynamicProxyOptions.IgnoredTypes` when proxy generation causes conflicts
