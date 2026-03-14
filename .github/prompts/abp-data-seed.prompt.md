---
mode: 'agent'
description: 'Scaffold an ABP Framework IDataSeedContributor to seed initial data for an entity'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold a **data seed contributor** (`IDataSeedContributor`) for the entity or data the user describes.

If no entity name or seed data scenario was provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/efcore.md` — **Data Seeding** section — and fetch https://docs.abp.io/en/abp/latest/Data-Seeding for the latest API details.

Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## File to create

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
        // Guard: skip if data already exists (idempotent)
        if (await _<entity>Repository.GetCountAsync() > 0)
        {
            return;
        }

        // Insert initial seed records
        await _<entity>Repository.InsertAsync(
            new <Entity>(
                _guidGenerator.Create(),
                "Seed Item 1"
                // other constructor parameters
            ),
            autoSave: true
        );

        await _<entity>Repository.InsertAsync(
            new <Entity>(
                _guidGenerator.Create(),
                "Seed Item 2"
            ),
            autoSave: true
        );
    }
}
```

**Rules to follow:**
- `IDataSeedContributor` + `ITransientDependency` — ABP auto-discovers this class; no registration needed
- **Always check if data already exists first** (idempotent — safe to run multiple times)
- Use `IGuidGenerator.Create()` — **never** `Guid.NewGuid()`
- Use `autoSave: true` on `InsertAsync` to flush after each record, or batch and call `SaveChangesAsync()` at the end
- If seed data depends on context parameters (e.g. tenant-specific), read via `context["ParameterName"]`

### Example with context parameters

```csharp
public async Task SeedAsync(DataSeedContext context)
{
    var adminEmail    = context["AdminEmail"]?.ToString()    ?? "admin@example.com";
    var adminPassword = context["AdminPassword"]?.ToString() ?? "1q2w3E*";
    // use to create admin user, etc.
}
```

---

## After generating

Remind the user:
1. Run the DbMigrator to apply seeds: `dotnet run --project src/Acme.BookStore.DbMigrator`
2. The `DbMigrator` app calls `IDataSeeder` internally, which discovers and runs all `IDataSeedContributor` implementations.
3. If using a custom domain service (e.g. `<Entity>Manager`) to create entities, inject it instead of the raw repository to enforce business rules during seeding.
