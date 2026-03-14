---
name: abp-domain-service
description: Scaffold an ABP Framework domain service (Manager class) for an existing entity
---

# ABP Domain Service Scaffold

A Windsurf Cascade workflow that creates the `<Entity>Manager` domain service class.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Unique field** — which property must be unique (e.g. `Name`, `Code`)?
3. **Extra business methods** — any other domain operations needed beyond `CreateAsync`?

---

## Step 1 — Read reference file

Read `abp-dev/references/ddd-domain.md` (Domain Services section) before generating any code.

---

## Step 2 — Create `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

Requirements:
- Extend `DomainService` from `Volo.Abp.Domain.Services`
- Constructor-inject `I<Entity>Repository`
- Use `GuidGenerator.Create()` (from `DomainService`) — **never** `Guid.NewGuid()`
- `CreateAsync(string name, ...)`:
  - Calls `FindByNameAsync` and throws `BusinessException` on duplicate
  - Returns a new `<Entity>` instance constructed with validated inputs
- Add any extra domain methods requested in the inputs step

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

## Step 3 — Confirm

Ask the user:
1. Do you also want the **application service layer** scaffolded? → run workflow `abp-app-service`
2. Do you need the **repository interface + EF Core implementation**? → run workflow `abp-repository`
