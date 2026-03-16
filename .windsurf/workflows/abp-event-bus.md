---
name: abp-event-bus
description: Scaffold ABP domain events, local/distributed event handlers, and event bus wiring
---

# ABP Event Bus Scaffold

A Windsurf Cascade workflow that creates the ETO (Event Transfer Object), raises the event from the aggregate root or domain service, and implements the event handler.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Book`)
2. **Event name** (past tense, e.g. `Created`, `Updated`, `Archived`)
3. **Event type** — Local or Distributed?
   - **Local** — same process, in-memory, dispatched after UoW commit; no message broker needed
   - **Distributed** — cross-process, requires a message broker (e.g. RabbitMQ)
4. **What should the handler do?** (e.g. send email, enqueue background job, update audit log)

---

## Step 1 — Read reference file

Read `abp-dev/references/event-bus.md` before generating any code.

---

## Step 2 — Create the ETO class

### Local ETO → `src/Acme.BookStore.Domain/<Entity>s/<Entity><EventName>Eto.cs`

```csharp
namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>Eto
{
    public Guid   <Entity>Id { get; set; }
    public string Name       { get; set; } = string.Empty;
}
```

### Distributed ETO → `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity><EventName>Eto.cs`

```csharp
using Volo.Abp.EventBus;

namespace Acme.BookStore.<Entity>s;

[EventName("bookstore.<entity>.<eventname>")]
public class <Entity><EventName>Eto
{
    public Guid   <Entity>Id { get; set; }
    public string Name       { get; set; } = string.Empty;
}
```

---

## Step 3 — Raise the event

### From the aggregate root (preferred for local events)

Add inside the entity constructor or business method:

```csharp
AddLocalEvent(new <Entity><EventName>Eto
{
    <Entity>Id = id,
    Name       = name
});
```

### From an application service (for distributed events)

Inject `IDistributedEventBus`:

```csharp
await _distributedEventBus.PublishAsync(new <Entity><EventName>Eto
{
    <Entity>Id = entity.Id,
    Name       = entity.Name
});
```

---

## Step 4 — Create the event handler

### `src/Acme.BookStore.Application/<Entity>s/<Entity><EventName>EventHandler.cs`

**Local:**
```csharp
using System.Threading.Tasks;
using Volo.Abp.DependencyInjection;
using Volo.Abp.EventBus;

namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>EventHandler
    : ILocalEventHandler<<Entity><EventName>Eto>, ITransientDependency
{
    public async Task HandleEventAsync(<Entity><EventName>Eto eventData)
    {
        // implement handler logic based on user input
    }
}
```

**Distributed:**
```csharp
using Volo.Abp.EventBus.Distributed;

public class <Entity><EventName>EventHandler
    : IDistributedEventHandler<<Entity><EventName>Eto>, ITransientDependency
{
    public async Task HandleEventAsync(<Entity><EventName>Eto eventData)
    {
        // implement handler logic
    }
}
```

---

## Step 5 — Module setup (distributed only)

If the user chose **Distributed**, show the module and `appsettings.json` snippets:

```csharp
[DependsOn(typeof(AbpRabbitMqEventBusModule))]
// In ConfigureServices:
Configure<AbpRabbitMqEventBusOptions>(options =>
{
    options.ClientName   = "BookStore";
    options.ExchangeName = "BookStore";
});
```

```json
{
  "RabbitMQ": {
    "Connections": {
      "Default": { "HostName": "localhost" }
    }
  }
}
```

---

## Step 6 — Confirm rules

- Handlers with `ITransientDependency` are auto-discovered by ABP — no registration needed
- `AddLocalEvent()` events are dispatched **after** the unit of work commits successfully
- For monolith apps without a broker, `IDistributedEventBus` dispatches locally by default
- Keep handler logic lightweight — enqueue a background job for heavy processing
