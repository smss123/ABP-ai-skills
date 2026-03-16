You are an expert ABP Framework developer. Scaffold **domain events and event bus wiring** for the entity or scenario: $ARGUMENTS

If no entity name or event scenario was provided, ask for:
1. Entity name (PascalCase)
2. Event name (past tense, e.g. `Created`, `Archived`, `Shipped`)
3. Local or Distributed?

## Before generating any code

Read `abp-dev/references/event-bus.md` and fetch https://docs.abp.io/en/abp/latest/Local-Event-Bus for the latest API details.

Replace `<Entity>` with the PascalCase entity name, `<entity>` with camelCase, and `<EventName>` with the past-tense event name.

---

## What to generate

### 1. ETO class (Event Transfer Object)

**Local** → `src/Acme.BookStore.Domain/<Entity>s/<Entity><EventName>Eto.cs`

```csharp
namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>Eto
{
    public Guid   <Entity>Id { get; set; }
    public string Name       { get; set; } = string.Empty;
    // include only the fields handlers will need
}
```

**Distributed** → `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity><EventName>Eto.cs`  
(in Application.Contracts so both publisher and subscriber can reference it)

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

### 2. Raise the event

**From the aggregate root** (preferred for local events) — in the entity constructor or business method:

```csharp
AddLocalEvent(new <Entity><EventName>Eto { <Entity>Id = id, Name = name });
```

**From a domain service or app service** (for distributed events):

```csharp
await _distributedEventBus.PublishAsync(new <Entity><EventName>Eto
{
    <Entity>Id = entity.Id,
    Name       = entity.Name
});
```

---

### 3. Event handler

**Local** → `src/Acme.BookStore.Application/<Entity>s/<Entity><EventName>EventHandler.cs`

```csharp
using Volo.Abp.DependencyInjection;
using Volo.Abp.EventBus;

namespace Acme.BookStore.<Entity>s;

public class <Entity><EventName>EventHandler
    : ILocalEventHandler<<Entity><EventName>Eto>, ITransientDependency
{
    public async Task HandleEventAsync(<Entity><EventName>Eto eventData)
    {
        // side-effect: notify, enqueue job, etc.
    }
}
```

**Distributed** → same file, but use `IDistributedEventHandler<T>`:

```csharp
using Volo.Abp.EventBus.Distributed;

public class <Entity><EventName>EventHandler
    : IDistributedEventHandler<<Entity><EventName>Eto>, ITransientDependency
{
    public async Task HandleEventAsync(<Entity><EventName>Eto eventData)
    {
        // cross-service side-effect
    }
}
```

---

### 4. Module setup (distributed only)

Add to `[DependsOn]` and `ConfigureServices` in the Application module:

```csharp
[DependsOn(typeof(AbpRabbitMqEventBusModule))]
// ...
Configure<AbpRabbitMqEventBusOptions>(options =>
{
    options.ClientName   = "BookStore";
    options.ExchangeName = "BookStore";
});
```

`appsettings.json`:
```json
{
  "RabbitMQ": {
    "Connections": {
      "Default": { "HostName": "localhost" }
    }
  }
}
```

For a monolith with no broker, no extra config is needed.

---

## Key rules to enforce

- `AddLocalEvent()` is only available on `AggregateRoot<TKey>` subclasses
- Local events raised via `AddLocalEvent()` are dispatched **after** the UoW commits
- `ITransientDependency` on the handler → ABP auto-discovers it, no registration needed
- Keep handlers side-effect-only — never return data; enqueue background jobs for heavy work
- ETOs for distributed events go in `Application.Contracts`; ETOs for local events stay in `Domain`
