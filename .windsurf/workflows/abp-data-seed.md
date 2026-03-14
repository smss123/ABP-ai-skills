---
name: abp-data-seed
description: Scaffold an ABP IDataSeedContributor to populate initial data for an entity
---

# ABP Data Seed Contributor Scaffold

A Windsurf Cascade workflow that creates an `IDataSeedContributor` to seed initial data.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Book`)
2. **Seed records** — how many rows, and what are their values?
3. Should the domain service (`<Entity>Manager`) be used instead of the raw repository (enforces business rules during seeding)?

---

## Step 1 — Read reference file

Read `abp-dev/references/efcore.md` (Data Seeding section).

---

## Step 2 — Create `src/Acme.BookStore.Domain/<Entity>s/<Entity>DataSeedContributor.cs`

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
        if (await _<entity>Repository.GetCountAsync() > 0)
            return;

        await _<entity>Repository.InsertAsync(
            new <Entity>(_guidGenerator.Create(), "Seed Record 1" /* other params */),
            autoSave: true
        );
        // Add more InsertAsync calls for each seed record
    }
}
```

---

## Step 3 — Confirm rules

- `IDataSeedContributor` + `ITransientDependency` → auto-discovered, no registration needed
- Always guard with count check (idempotent)
- Use `IGuidGenerator.Create()` — **never** `Guid.NewGuid()`
- Run via `DbMigrator` — which calls `IDataSeeder` internally

---

## Step 4 — Reminder

```bash
dotnet run --project src/Acme.BookStore.DbMigrator
```
