# ABP: Concurrency Check

> 📖 Official docs:
> - Concurrency Check: https://abp.io/docs/latest/framework/infrastructure/concurrency-check
> - Entities: https://abp.io/docs/latest/framework/architecture/domain-driven-design/entities
>
> Fetch these pages for the latest API details before generating concurrency or versioning code.

## Overview

ABP supports **optimistic concurrency** via `IHasConcurrencyStamp`. A stamp (GUID string) is stored on the entity and checked on every update. If two users attempt to update the same record simultaneously, the second update throws `AbpDbConcurrencyException`.

All standard aggregate root base classes already implement this interface — no extra setup needed.

---

## `IHasConcurrencyStamp`

```csharp
public interface IHasConcurrencyStamp
{
    string ConcurrencyStamp { get; set; }
}
```

Implemented by: `AggregateRoot<TKey>`, `AuditedAggregateRoot<TKey>`, `FullAuditedAggregateRoot<TKey>`.

ABP automatically assigns a new `ConcurrencyStamp` on entity creation and regenerates it after every successful update.

---

## Implementing Optimistic Concurrency

### 1. Entity — no extra work needed

```csharp
public class Book : FullAuditedAggregateRoot<Guid>
{
    // ConcurrencyStamp is inherited — no additional code required
    public string Name { get; private set; }
    // ...
}
```

### 2. Output DTO — expose the stamp

```csharp
public class BookDto : AuditedEntityDto<Guid>, IHasConcurrencyStamp
{
    public string Name { get; set; }
    public string ConcurrencyStamp { get; set; }
}
```

### 3. Update DTO — carry the stamp from the client

```csharp
public class UpdateBookDto : IHasConcurrencyStamp
{
    [Required]
    [StringLength(128)]
    public string Name { get; set; }

    public string ConcurrencyStamp { get; set; }  // client must echo this back
}
```

### 4. Application Service — apply the stamp before saving

```csharp
public async Task<BookDto> UpdateAsync(Guid id, UpdateBookDto input)
{
    var book = await _bookRepository.GetAsync(id);

    // Apply the incoming stamp so EF Core can detect conflicts
    book.ConcurrencyStamp = input.ConcurrencyStamp;

    book.SetName(input.Name);

    // autoSave: true regenerates the stamp after the successful write
    await _bookRepository.UpdateAsync(book, autoSave: true);

    return ObjectMapper.Map<Book, BookDto>(book);
}
```

### 5. Handling the exception

```csharp
try
{
    await UpdateAsync(id, input);
}
catch (AbpDbConcurrencyException)
{
    // Inform the user that the record was modified by someone else
    throw new UserFriendlyException(L["ConcurrencyError"]);
}
```

---

## `IHasEntityVersion` (Auto-Increment Version)

Use when you need a monotonically increasing version counter (e.g., for event sourcing, API ETags, or client-side sync).

```csharp
public class Document : FullAuditedAggregateRoot<Guid>, IHasEntityVersion
{
    public int EntityVersion { get; set; }  // ABP increments this automatically on every update
    public string Content { get; private set; }
    // ...
}
```

ABP increments `EntityVersion` on every `UpdateAsync` call through the repository. Direct SQL updates bypass this — recalculate manually if needed.

---

## Key Rules

- **DO** include `ConcurrencyStamp` in output DTOs so clients can echo it back
- **DO** apply `input.ConcurrencyStamp` to the entity before calling `UpdateAsync`
- **DO** use `autoSave: true` (or `SaveChangesAsync`) so the new stamp is generated within the same unit of work
- **DO** catch `AbpDbConcurrencyException` at the application service or controller level and return a user-friendly message
- **DO NOT** generate or modify `ConcurrencyStamp` manually — ABP manages it
- **DO NOT** rely on `EntityVersion` for conflict detection across distributed services — use `ConcurrencyStamp` for that
