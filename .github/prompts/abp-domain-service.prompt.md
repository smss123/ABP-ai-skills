---
mode: 'agent'
description: 'Scaffold an ABP Framework domain service (Manager class) for an existing entity'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold an **ABP domain service** (the `<Entity>Manager` class) for the entity the user names.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

Read `abp-dev/references/ddd-domain.md` — specifically the **Domain Services** section — and fetch https://docs.abp.io/en/abp/latest/Domain-Services for the latest API details.

Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## File to create

### `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

Requirements:
- Extend `DomainService` (from `Volo.Abp.Domain.Services`)
- Constructor-inject `I<Entity>Repository`
- Use `GuidGenerator.Create()` (inherited from `DomainService`) — **never** `Guid.NewGuid()`
- `CreateAsync(string name, ...)` method:
  - Enforces uniqueness: calls `repository.FindByNameAsync(name)` and throws `BusinessException` if already exists
  - Constructs and returns a new `<Entity>` using the validated inputs
- Add any additional methods that involve cross-aggregate coordination or complex business rules

```csharp
// Domain/<Entity>s/<Entity>Manager.cs
using System.Threading.Tasks;
using Volo.Abp;
using Volo.Abp.Domain.Services;

namespace Acme.BookStore.<Entity>s;

public class <Entity>Manager : DomainService
{
    private readonly I<Entity>Repository _<entity>Repository;

    public <Entity>Manager(I<Entity>Repository <entity>Repository)
    {
        _<entity>Repository = <entity>Repository;
    }

    public async Task<<Entity>> CreateAsync(string name /* add other params */)
    {
        if (await _<entity>Repository.FindByNameAsync(name) != null)
        {
            throw new BusinessException(<Entity>sDomainErrorCodes.<Entity>NameAlreadyExists)
                .WithData("name", name);
        }

        return new <Entity>(
            GuidGenerator.Create(),
            name
            // other properties
        );
    }
}
```

**Domain Service vs Application Service:**
- Domain Service → works with **entities**, enforces business invariants, no DTOs
- Application Service → works with **DTOs**, orchestrates domain service + repository, handles use-case flow

---

## After generating

Ask the user:
1. Should I also scaffold the **repository interface** for this entity? → attach `#abp-repository.prompt.md`
2. Should I scaffold the **full application service layer** (DTOs + app service)? → attach `#abp-app-service.prompt.md`
