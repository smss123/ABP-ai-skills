You are an expert ABP Framework developer. Scaffold an **ABP data seed contributor** for the entity named: $ARGUMENTS

If no entity name or seed data scenario was provided, ask before proceeding.

Read `abp-dev/references/efcore.md` (Data Seeding section) before generating any code.

## What to generate

### `src/Acme.BookStore.Domain/<Entity>s/<Entity>DataSeedContributor.cs`

```csharp
using System;
using System.Threading.Tasks;
using Volo.Abp.Data;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Guids;

namespace Acme.BookStore.<Entity>s;

public class <Entity>DataSeedContributor : IDataSeedContributor, ITransientDependency
{
    private readonly IRepository<<Entity>, Guid> _<entity>Repository;
    private readonly IGuidGenerator _guidGenerator;

    public <Entity>DataSeedContributor(
        IRepository<<Entity>, Guid> <entity>Repository,
        IGuidGenerator guidGenerator)
    {
        _<entity>Repository = <entity>Repository;
        _guidGenerator       = guidGenerator;
    }

    public async Task SeedAsync(DataSeedContext context)
    {
        // Idempotent guard — always check if data already exists
        if (await _<entity>Repository.GetCountAsync() > 0)
            return;

        await _<entity>Repository.InsertAsync(
            new <Entity>(_guidGenerator.Create(), "Seed Record 1" /* other params */),
            autoSave: true
        );
    }
}
```

**Rules to apply:**
- `IDataSeedContributor` + `ITransientDependency` — ABP auto-discovers it; no registration needed
- Always guard with a count check (idempotent)
- Use `IGuidGenerator.Create()` — never `Guid.NewGuid()`
- Use `autoSave: true` on each `InsertAsync`, or batch inserts and call `SaveChangesAsync()` once at the end
- If seeding depends on tenant/environment params: `context["ParameterName"]?.ToString()`
- Prefer injecting `<Entity>Manager` instead of the raw repository if business rules must be enforced during seeding

## After generating

Remind the user to run the DbMigrator to apply seeds:
```bash
dotnet run --project src/Acme.BookStore.DbMigrator
```
