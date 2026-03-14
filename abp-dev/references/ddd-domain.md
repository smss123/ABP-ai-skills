# ABP: DDD Domain Layer

## Entities & Aggregate Roots

### Base classes (choose one)

| Base Class | Use When |
|---|---|
| `AggregateRoot<TKey>` | Standard aggregate root (includes ExtraProperties + ConcurrencyStamp) |
| `BasicAggregateRoot<TKey>` | Aggregate root without extra properties / concurrency stamp |
| `FullAuditedAggregateRoot<TKey>` | Aggregate root + full audit (CreationTime, CreatorId, LastModificationTime, DeletionTime, IsDeleted) |
| `AuditedAggregateRoot<TKey>` | Aggregate root + creation + modification audit only |
| `Entity<TKey>` | Non-root child entity (part of an aggregate, not its own repo) |

### Auditing interfaces (mix-in style)

```csharp
IHasCreationTime        // CreationTime
IMustHaveCreator        // CreatorId (required)
IMayHaveCreator         // CreatorId (optional)
IHasModificationTime    // LastModificationTime
IModificationAuditedObject
ISoftDelete             // IsDeleted
IFullAuditedObject      // all of the above
```

### Canonical entity pattern

```csharp
// Domain project: Acme.BookStore.Domain/Books/Book.cs
using System;
using Volo.Abp.Domain.Entities.Auditing;
using JetBrains.Annotations;

namespace Acme.BookStore.Books;

public class Book : FullAuditedAggregateRoot<Guid>
{
    public const int MaxNameLength = 128;

    public virtual string Name { get; private set; }      // private setter — enforce via method
    public virtual BookType Type { get; set; }            // direct set OK for simple value
    public virtual decimal? Price { get; set; }
    public virtual DateTime PublishDate { get; set; }

    // Required: parameterless protected constructor for ORM deserialization
    protected Book() { }

    // Primary constructor: enforce validity on creation
    public Book(Guid id, [NotNull] string name, BookType type, decimal? price, DateTime publishDate)
        : base(id)
    {
        SetName(name);
        Type = type;
        Price = price;
        PublishDate = publishDate;
    }

    // Business method to change a private-setter property
    public Book SetName([NotNull] string name)
    {
        Name = Check.NotNullOrWhiteSpace(name, nameof(name), maxLength: MaxNameLength);
        return this;
    }
}
```

### Aggregate with sub-collection

```csharp
public class Order : AggregateRoot<Guid>
{
    public virtual string ReferenceNo { get; private set; }
    public virtual ICollection<OrderLine> Lines { get; private set; }

    protected Order() { }

    public Order(Guid id, [NotNull] string referenceNo) : base(id)
    {
        ReferenceNo = Check.NotNullOrWhiteSpace(referenceNo, nameof(referenceNo));
        Lines = new Collection<OrderLine>();  // Always initialize sub-collections in constructor
    }

    public void AddProduct(Guid productId, int count)
    {
        // Business logic lives here, not in the application service
        Check.Positive(count, nameof(count));
        var existingLine = Lines.FirstOrDefault(l => l.ProductId == productId);
        if (existingLine != null)
            existingLine.ChangeCount(existingLine.Count + count);
        else
            Lines.Add(new OrderLine(Id, productId, count));
    }
}

// Child entity — internal constructor, only Order can create it
public class OrderLine : Entity<Guid>
{
    public virtual Guid OrderId { get; private set; }
    public virtual Guid ProductId { get; private set; }
    public virtual int Count { get; private set; }

    protected OrderLine() { }

    internal OrderLine(Guid orderId, Guid productId, int count)
    {
        OrderId = orderId;
        ProductId = productId;
        ChangeCount(count);
    }

    internal void ChangeCount(int newCount)
    {
        Count = Check.Positive(newCount, nameof(newCount));
    }
}
```

### Key rules

- **DO** define entities in the Domain layer
- **DO** use `IGuidGenerator` (injected) to create Guid keys — never `Guid.NewGuid()`
- **DO** make property setters `private` or `protected` when the value must be controlled
- **DO** initialize sub-collections in the primary constructor
- **DO** define a `protected` parameterless constructor for ORM compatibility
- **DO NOT** add navigation properties between different aggregate roots (reference by Id)
- **DO NOT** put business logic in application services — it belongs in entities or domain services

---

## Value Objects

```csharp
using Volo.Abp.Domain.Values;

public class Address : ValueObject
{
    public string Street { get; init; }
    public string City { get; init; }
    public string Country { get; init; }

    public Address(string street, string city, string country)
    {
        Street = Check.NotNullOrEmpty(street, nameof(street));
        City   = Check.NotNullOrEmpty(city,   nameof(city));
        Country = Check.NotNullOrEmpty(country, nameof(country));
    }

    protected override IEnumerable<object> GetAtomicValues()
    {
        yield return Street;
        yield return City;
        yield return Country;
    }
}
```

---

## Repository Interfaces

Define in Domain layer; implement in EntityFrameworkCore layer.

```csharp
// Domain/Books/IBookRepository.cs
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Volo.Abp.Domain.Repositories;

namespace Acme.BookStore.Books;

public interface IBookRepository : IRepository<Book, Guid>
{
    Task<List<Book>> GetListAsync(
        string? filterText = null,
        BookType? type = null,
        int maxResultCount = int.MaxValue,
        int skipCount = 0,
        string? sorting = null
    );

    Task<Book?> FindByNameAsync(string name);
}
```

Default generic `IRepository<T, TKey>` methods available without custom interface:
`GetAsync`, `FindAsync`, `InsertAsync`, `UpdateAsync`, `DeleteAsync`, `GetListAsync`, `GetCountAsync`, `GetPagedListAsync`.

---

## Domain Services

Use when logic involves multiple aggregates or external services (repositories).

```csharp
// Domain/Books/BookManager.cs
using System.Threading.Tasks;
using Volo.Abp;
using Volo.Abp.Domain.Services;

namespace Acme.BookStore.Books;

public class BookManager : DomainService
{
    private readonly IBookRepository _bookRepository;

    public BookManager(IBookRepository bookRepository)
    {
        _bookRepository = bookRepository;
    }

    public async Task<Book> CreateAsync(string name, BookType type, decimal? price, DateTime publishDate)
    {
        // Cross-entity/repo logic: enforce unique name
        if (await _bookRepository.FindByNameAsync(name) != null)
        {
            throw new UserFriendlyException($"A book with name '{name}' already exists!");
        }

        return new Book(
            GuidGenerator.Create(),  // Use GuidGenerator from DomainService base
            name, type, price, publishDate
        );
    }
}
```

**Domain Service vs Application Service:**
- Domain Service: gets/returns **entities**, no DTOs, contains core business rules
- Application Service: gets/returns **DTOs**, orchestrates domain objects, handles use-case flow
