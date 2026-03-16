---
mode: 'agent'
description: 'Scaffold ABP Framework domain event, local/distributed event handler, and event bus wiring'
tools: ['codebase', 'fetch', 'search', 'editFiles', 'runCommands']
---

You are an expert ABP Framework developer. Scaffold **domain events and event handlers** for the entity or scenario the user describes.

If no entity name or event scenario was provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/event-bus.md` and fetch https://docs.abp.io/en/abp/latest/Local-Event-Bus for the latest API details.

Replace every `<Entity>` placeholder with the PascalCase entity name, `<entity>` with the camelCase version, and `<EventName>` with a descriptive past-tense event name (e.g. `BookCreated`, `OrderShipped`).

---

## Step 1 — Determine event type

Ask the user:
1. **Entity name** (PascalCase)
2. **Event name** (past tense, e.g. `Created`, `Updated`, `Archived`)
3. **Local or Distributed?**
   - **Local** — same process, raised from entity or domain service, dispatched after UoW commit
   - **Distributed** — cross-service (RabbitMQ, Kafka, etc.)

---

## Step 2 — Create the ETO (Event Transfer Object)

### Local event ETO — `src/Acme.BookStore.Domain/<Entity>s/<EntityEventName>Eto.cs`

```csharp
namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>Eto
{
    public Guid   <Entity>Id { get; set; }
    public string Name       { get; set; } = string.Empty;
    // add only the properties needed by handlers — keep it lightweight
}
```

### Distributed event ETO — `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity><EventName>Eto.cs`

Place the ETO in `Application.Contracts` so both publisher and subscriber services can reference it.

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

### Option A — From the aggregate root (preferred for local events)

Add `AddLocalEvent(...)` in the entity constructor or business method:

```csharp
// Inside the entity constructor or business method
AddLocalEvent(new <Entity><EventName>Eto
{
    <Entity>Id = id,
    Name       = name
});
```

### Option B — From a domain service or application service (for distributed events)

```csharp
// Inject IDistributedEventBus
private readonly IDistributedEventBus _distributedEventBus;

await _distributedEventBus.PublishAsync(new <Entity><EventName>Eto
{
    <Entity>Id = entity.Id,
    Name       = entity.Name
});
```

---

## Step 4 — Create the event handler

### Local event handler — `src/Acme.BookStore.Application/<Entity>s/<Entity><EventName>EventHandler.cs`

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
        // implement side-effect here (e.g. send notification, enqueue background job)
    }
}
```

### Distributed event handler — `src/Acme.BookStore.Application/<Entity>s/<Entity><EventName>EventHandler.cs`

```csharp
using System.Threading.Tasks;
using Volo.Abp.DependencyInjection;
using Volo.Abp.EventBus.Distributed;

namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>EventHandler
    : IDistributedEventHandler<<Entity><EventName>Eto>, ITransientDependency
{
    public async Task HandleEventAsync(<Entity><EventName>Eto eventData)
    {
        // implement cross-service side-effect here
    }
}
```

---

## Step 5 — Module setup (distributed only)

If the user chose **distributed**, show the module snippet for RabbitMQ (default):

```csharp
// Add to the module's [DependsOn]
typeof(AbpRabbitMqEventBusModule)

// In ConfigureServices:
Configure<AbpRabbitMqEventBusOptions>(options =>
{
    options.ClientName   = "BookStore";
    options.ExchangeName = "BookStore";
});
```

And the `appsettings.json` entry:
```json
{
  "RabbitMQ": {
    "Connections": {
      "Default": {
        "HostName": "localhost"
      }
    }
  }
}
```

For a **monolith** with no message broker, no extra package or config is required — the distributed event bus falls back to local dispatch automatically.

---

## After generating

Remind the user:
1. ABP auto-discovers `ILocalEventHandler<T>` and `IDistributedEventHandler<T>` via `ITransientDependency` — no explicit registration needed.
2. Local events raised via `AddLocalEvent()` on an aggregate root are dispatched **after** the unit of work commits successfully.
3. Keep handlers lightweight — prefer enqueueing a background job for heavy work.
