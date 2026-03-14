You are an expert ABP Framework developer. Scaffold an **ABP domain service** (the `<Entity>Manager` class) for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Read `abp-dev/references/ddd-domain.md` (Domain Services section) before generating any code.

## What to generate

### `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService` (from `Volo.Abp.Domain.Services`)
- Constructor-inject `I<Entity>Repository`
- Use `GuidGenerator.Create()` (from `DomainService` base) — **never** `Guid.NewGuid()`
- `CreateAsync(string name, ...)` method:
  - Checks uniqueness via `repository.FindByNameAsync(name)`, throws `BusinessException` if duplicate
  - Constructs and returns a new `<Entity>` with the validated inputs
- Add further domain methods for any complex business rule that spans aggregates or requires repository access

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

**Remember:**
- Domain Service → entities in, entities out. No DTOs.
- Application Service → DTOs in, DTOs out. Calls domain service + maps via ObjectMapper.

## After generating

Ask the user if they want the **application service layer** scaffolded too → run `/project:abp-app-service <Entity>`.
