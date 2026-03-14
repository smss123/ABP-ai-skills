You are an expert ABP Framework developer. The user wants to scaffold a **single ABP Domain Entity** named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Read `abp-dev/references/ddd-domain.md` for canonical patterns before generating any code.

## What to generate

### 1. Entity class — `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`

- Choose the correct base class (ask the user which they need if unclear):
  - `FullAuditedAggregateRoot<Guid>` — full audit trail + soft-delete
  - `AuditedAggregateRoot<Guid>` — creation + modification audit only
  - `AggregateRoot<Guid>` — no auditing
  - `Entity<Guid>` — child entity (not its own repository)
- Private or protected setters on all business-significant properties
- A `protected <Entity>() { }` parameterless constructor for ORM deserialization
- A primary constructor that accepts `Guid id` (assigned by `IGuidGenerator` at the call site)
- Business methods for every property with a private setter (e.g., `SetName`, `ChangePrice`)
- Constants class `<Entity>Consts` with `MaxNameLength` etc.

### 2. Repository interface — `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- Add custom query methods appropriate for the entity (e.g., `FindByNameAsync`, `GetListAsync` with filtering/sorting/paging parameters)

### 3. Domain service — `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService`
- `CreateAsync(...)` method that uses `GuidGenerator.Create()` and enforces business invariants
- Any other domain-level operations that cross aggregate boundaries

---

## After generating

Ask the user:
1. Do you also want the **Application layer** scaffolded? (DTOs, app service interface, app service implementation) → run `/project:abp-crud <Entity>` for the full stack.
2. Do you want the **EF Core** configuration snippet for the DbContext and model builder?
