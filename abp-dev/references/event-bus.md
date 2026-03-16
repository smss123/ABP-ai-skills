# ABP: Local & Distributed Event Bus

> 📖 Official docs:
> - Local Event Bus: https://docs.abp.io/en/abp/latest/Local-Event-Bus
> - Distributed Event Bus: https://docs.abp.io/en/abp/latest/Distributed-Event-Bus
> - Domain Events: https://docs.abp.io/en/abp/latest/Domain-Events
>
> Fetch these pages for the latest API details before generating event bus code.

## Domain Events (Entity-Local — recommended starting point)

Aggregate roots can raise **domain events** that are automatically dispatched by ABP after the
unit of work completes. This keeps domain logic decoupled from side-effects.

### 1. Define the event data class (Domain layer)

```csharp
// Domain/Books/Events/BookCreatedEto.cs
namespace Acme.BookStore.Books;

public class BookCreatedEto
{
    public Guid BookId   { get; set; }
    public string Name   { get; set; } = string.Empty;
    public BookType Type { get; set; }
}
```

### 2. Raise the event inside the aggregate root

```csharp
// Domain/Books/Book.cs
public class Book : FullAuditedAggregateRoot<Guid>
{
    // ...

    public Book(Guid id, string name, BookType type, decimal? price, DateTime publishDate)
        : base(id)
    {
        SetName(name);
        Type = type;
        Price = price;
        PublishDate = publishDate;

        // Raise a local domain event — dispatched after UoW commit
        AddLocalEvent(new BookCreatedEto
        {
            BookId = id,
            Name   = name,
            Type   = type
        });
    }
}
```

`AddLocalEvent()` is available on any class that extends `AggregateRoot<TKey>`.  
The event is dispatched **within the same process**, after the current unit of work saves successfully.

### 3. Handle the event

```csharp
// Application/Books/BookCreatedEventHandler.cs
using System.Threading.Tasks;
using Volo.Abp.DependencyInjection;
using Volo.Abp.EventBus;

namespace Acme.BookStore.Books;

public class BookCreatedEventHandler
    : ILocalEventHandler<BookCreatedEto>, ITransientDependency
{
    private readonly IBackgroundJobManager _jobs;

    public BookCreatedEventHandler(IBackgroundJobManager jobs)
    {
        _jobs = jobs;
    }

    public async Task HandleEventAsync(BookCreatedEto eventData)
    {
        // Side-effect: e.g. send a welcome notification
        await _jobs.EnqueueAsync(new SendBookNotificationArgs
        {
            BookId = eventData.BookId,
            Name   = eventData.Name
        });
    }
}
```

ABP auto-discovers `ILocalEventHandler<T>` — no registration needed.

---

## ILocalEventBus — publish manually (without aggregate root)

Inject `ILocalEventBus` when raising events outside an entity (e.g. in a domain service
or application service):

```csharp
// Domain/Books/BookManager.cs
using Volo.Abp.EventBus.Local;

public class BookManager : DomainService
{
    private readonly ILocalEventBus _localEventBus;

    public BookManager(ILocalEventBus localEventBus)
    {
        _localEventBus = localEventBus;
    }

    public async Task ArchiveAsync(Book book)
    {
        book.Archive();

        // Publish a local event
        await _localEventBus.PublishAsync(new BookArchivedEto { BookId = book.Id });
    }
}
```

---

## Distributed Event Bus

Use `IDistributedEventBus` when the event must cross service boundaries
(e.g. microservices, or publishing to a message broker like RabbitMQ / Kafka).

### Define the ETO (Event Transfer Object)

```csharp
// Application.Contracts/Books/BookCreatedDistributedEto.cs
// Placed in Application.Contracts so both publisher and subscriber can reference it.
using Volo.Abp.EventBus;

namespace Acme.BookStore.Books;

[EventName("bookstore.book.created")]   // unique event name across services
public class BookCreatedDistributedEto
{
    public Guid   BookId { get; set; }
    public string Name   { get; set; } = string.Empty;
}
```

### Publish from an application service

```csharp
using Volo.Abp.EventBus.Distributed;

public class BookAppService : ApplicationService, IBookAppService
{
    private readonly IDistributedEventBus _distributedEventBus;

    public BookAppService(IDistributedEventBus distributedEventBus)
    {
        _distributedEventBus = distributedEventBus;
    }

    public async Task<BookDto> CreateAsync(CreateUpdateBookDto input)
    {
        var book = await _bookManager.CreateAsync(input.Name, input.Type, input.Price, input.PublishDate);
        await _bookRepository.InsertAsync(book);

        await _distributedEventBus.PublishAsync(new BookCreatedDistributedEto
        {
            BookId = book.Id,
            Name   = book.Name
        });

        return ObjectMapper.Map<Book, BookDto>(book);
    }
}
```

### Handle a distributed event

```csharp
using Volo.Abp.EventBus.Distributed;

public class BookCreatedDistributedEventHandler
    : IDistributedEventHandler<BookCreatedDistributedEto>, ITransientDependency
{
    public async Task HandleEventAsync(BookCreatedDistributedEto eventData)
    {
        // Process cross-service side-effect
    }
}
```

---

## Local vs Distributed — when to use which

| | Local Event Bus | Distributed Event Bus |
|---|---|---|
| Scope | In-process only | Cross-process / cross-service |
| Transport | In-memory | RabbitMQ, Kafka, Azure Service Bus, etc. |
| When dispatched | After UoW commit (if raised from aggregate) | Immediately on `PublishAsync` |
| ETO location | Domain layer | Application.Contracts (shared) |
| Handler interface | `ILocalEventHandler<T>` | `IDistributedEventHandler<T>` |
| Typical use | Side-effects within same app | Microservice integration |

---

## Module setup for distributed event bus (RabbitMQ example)

```csharp
[DependsOn(typeof(AbpRabbitMqEventBusModule))]
public class BookStoreApplicationModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpRabbitMqEventBusOptions>(options =>
        {
            options.ClientName    = "BookStore";
            options.ExchangeName  = "BookStore";
        });
    }
}
```

`appsettings.json`:
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

For **in-process only** (monolith, no message broker), no extra package is needed — `IDistributedEventBus` defaults to local dispatch.

---

## Key rules

- **DO** raise domain events from aggregate roots using `AddLocalEvent()` — not in app services
- **DO** put ETO classes in `Domain` (local) or `Application.Contracts` (distributed)
- **DO** implement `ITransientDependency` on event handlers for auto-registration
- **DO** keep handlers side-effect-only — never return data from a handler
- **DO NOT** raise distributed events for intra-process communication — use local events instead
- **DO NOT** perform heavy synchronous work in a local event handler — enqueue a background job instead
