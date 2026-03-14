---
mode: 'agent'
description: 'Scaffold an ABP Framework domain entity with repository interface and domain service'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold a **single ABP domain entity** for the entity the user names.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

Read `abp-dev/references/ddd-domain.md` for canonical entity, repository, and domain service patterns.  
Fetch the official docs URL from that file when the network is available.

Replace every `<Entity>` placeholder below with the PascalCase entity name and `<entity>` with the camelCase version.

---

## Files to create

### 1. `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`

Ask the user which base class they need if it is not obvious from context:

| Base class | When to use |
|---|---|
| `FullAuditedAggregateRoot<Guid>` | Full audit trail (created/modified/deleted by + timestamps) + soft-delete |
| `AuditedAggregateRoot<Guid>` | Creation + last-modification audit only |
| `AggregateRoot<Guid>` | No built-in auditing |
| `Entity<Guid>` | Child entity that is NOT its own aggregate root |

Requirements:
- Private or protected setters on **all** business-significant properties
- `protected <Entity>() { }` parameterless constructor (required by EF Core)
- Primary constructor accepting `Guid id` — the ID is assigned externally via `IGuidGenerator.Create()`
- Business method for every private-setter property (e.g. `SetName(string name)`, `ChangePrice(decimal price)`)
- Companion constants: `public static class <Entity>Consts { public const int MaxNameLength = 128; }`

### 2. `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- Add query methods appropriate for the entity, e.g.:
  - `Task<List<<Entity>>> GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting, CancellationToken cancellationToken = default)`
  - `Task<<Entity>?> FindByNameAsync(string name, CancellationToken cancellationToken = default)`

### 3. `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService`
- `public async Task<<Entity>> CreateAsync(string name, ...)` — use `GuidGenerator.Create()` to generate the ID; enforce uniqueness or other invariants; throw a typed `BusinessException` on violation
- Add any other methods that require cross-aggregate coordination

---

## After generating

Ask the user:
1. Do you also want the **Application layer** scaffolded (DTOs, app service interface, app service implementation)?  
   → Attach `#abp-crud.prompt.md` in the next message for the full-stack scaffold.
2. Do you want the **EF Core** `DbSet` property and model builder configuration snippet?
