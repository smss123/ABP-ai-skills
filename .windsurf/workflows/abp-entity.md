---
name: abp-entity
description: Scaffold an ABP Framework domain entity with repository interface and domain service
---

# ABP Domain Entity Scaffold

A Windsurf Cascade workflow that creates the entity class, repository interface, and domain service (Manager) for a new ABP aggregate root.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Properties** — name, type, and whether each is required (e.g. `Name:string:required`, `Price:decimal:optional`)
3. **Audit level** — `FullAudit` (default) / `Audit` / `None`
4. **Unique field** — which property must be unique? (usually `Name`)

---

## Step 1 — Read reference file

Read `abp-dev/references/ddd-domain.md` before generating any code.

---

## Step 2 — Create `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`

Choose the base class based on the audit level input:

| Audit level | Base class |
|---|---|
| FullAudit | `FullAuditedAggregateRoot<Guid>` |
| Audit | `AuditedAggregateRoot<Guid>` |
| None | `AggregateRoot<Guid>` |

Requirements:
- Private or protected setters on **all** business-significant properties
- `protected <Entity>() { }` parameterless constructor (required by EF Core / ORM)
- Primary constructor accepting `Guid id` — assigned externally via `IGuidGenerator.Create()`
- Business method for every private-setter property (e.g. `SetName`, `ChangePrice`)
- Constants class: `public static class <Entity>Consts { public const int MaxNameLength = 128; }`

```csharp
// src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs
namespace Acme.BookStore.<Entity>s;

public class <Entity> : FullAuditedAggregateRoot<Guid>
{
    public static class <Entity>Consts
    {
        public const int MaxNameLength = 128;
    }

    public virtual string Name { get; private set; } = string.Empty;
    // add other properties here...

    protected <Entity>() { }

    public <Entity>(Guid id, [NotNull] string name /* other params */) : base(id)
    {
        SetName(name);
        // assign other properties
    }

    public <Entity> SetName([NotNull] string name)
    {
        Name = Check.NotNullOrWhiteSpace(name, nameof(name), maxLength: <Entity>Consts.MaxNameLength);
        return this;
    }
}
```

---

## Step 3 — Create `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- `Task<List<<Entity>>> GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting, CancellationToken cancellationToken = default)`
- `Task<<Entity>?> FindByNameAsync(string name, CancellationToken cancellationToken = default)`

---

## Step 4 — Create `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService`
- `CreateAsync(string name, ...)`:
  - Check uniqueness via `FindByNameAsync`; throw `BusinessException` on duplicate
  - Use `GuidGenerator.Create()` — **never** `Guid.NewGuid()`

```csharp
public class <Entity>Manager : DomainService
{
    private readonly I<Entity>Repository _<entity>Repository;

    public <Entity>Manager(I<Entity>Repository <entity>Repository)
        => _<entity>Repository = <entity>Repository;

    public async Task<<Entity>> CreateAsync(string name /* other params */)
    {
        if (await _<entity>Repository.FindByNameAsync(name) != null)
            throw new BusinessException(<Entity>sDomainErrorCodes.<Entity>NameAlreadyExists)
                .WithData("name", name);

        return new <Entity>(GuidGenerator.Create(), name /* other params */);
    }
}
```

---

## Step 5 — Next steps

Ask the user:
1. Do you also want the **application layer** scaffolded (DTOs, app service)?  
   → run workflow `abp-app-service`
2. Do you need the **EF Core repository implementation** and model config?  
   → run workflow `abp-repository`
3. Do you want the **Razor Pages UI**?  
   → run workflow `abp-razor-page`
