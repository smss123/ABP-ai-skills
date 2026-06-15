# ABP: Correlation ID

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/correlation-id
>
> Fetch this page for the latest API details before generating correlation ID code.

---

## Overview

ABP automatically assigns a unique ID to every HTTP request and propagates it across distributed operations, making it possible to trace a single user action across microservices, events, audit logs, and logs.

---

## `ICorrelationIdProvider`

```csharp
public class MyService : ITransientDependency
{
    private readonly ICorrelationIdProvider _correlationIdProvider;

    public MyService(ICorrelationIdProvider correlationIdProvider)
    {
        _correlationIdProvider = correlationIdProvider;
    }

    public void LogCurrentId()
    {
        var id = _correlationIdProvider.Get();   // null if unset
        Console.WriteLine(id);
    }

    public async Task RunWithCustomIdAsync()
    {
        using (_correlationIdProvider.Change("my-custom-id"))
        {
            // all operations inside this block use "my-custom-id"
            await DoWorkAsync();
        }
        // previous ID restored here
    }
}
```

The default implementation (`DefaultCorrelationIdProvider`) stores the value in `AsyncLocal<string?>` — isolated per async execution context, thread-safe.

---

## Middleware

Add to the pipeline (already included in ABP templates):

```csharp
app.UseCorrelationId();  // before UseRouting / UseAuthorization
```

On each request the middleware:
1. Reads `X-Correlation-Id` from the incoming request header
2. Generates a new GUID-based ID if the header is absent
3. Sets the ID in the async context via `ICorrelationIdProvider`
4. Optionally writes the ID back to the response header

---

## Configuration (`AbpCorrelationIdOptions`)

```csharp
Configure<AbpCorrelationIdOptions>(options =>
{
    options.HttpHeaderName    = "X-Correlation-Id";  // header to read/write
    options.SetResponseHeader = true;                // echo ID in response
});
```

| Property | Default | Notes |
|---|---|---|
| `HttpHeaderName` | `"X-Correlation-Id"` | Customize if your gateway uses a different header |
| `SetResponseHeader` | `true` | Disable if you don't want to expose the ID to clients |

---

## Automatic Propagation

ABP automatically carries the correlation ID through:

| Channel | How |
|---|---|
| **HTTP client proxies** | Added to outbound request headers automatically |
| **Distributed event bus** | Embedded in message metadata; restored on consumption |
| **Audit log** | Stored as `AuditLogInfo.CorrelationId` |
| **Security log** | Stored as `SecurityLogInfo.CorrelationId` |
| **Serilog** | Enriched as the `CorrelationId` log property |

No manual forwarding is needed when using ABP's dynamic HTTP client proxies or the distributed event bus.

---

## Key Rules

- **DO** call `app.UseCorrelationId()` early in the pipeline — before routing and authorization
- **DO** use `ICorrelationIdProvider.Change()` in a `using` block when you need to scope a custom ID
- **DO NOT** set `SetResponseHeader = false` unless you have a security reason — the response header is essential for client-side debugging
- **DO** configure a custom `HttpHeaderName` when integrating with a gateway that uses a different header (e.g. `X-Request-Id`, `traceparent`)
