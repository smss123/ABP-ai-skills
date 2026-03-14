---
mode: 'agent'
description: 'Scaffold an ABP Framework repository interface and EF Core implementation'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold an **ABP repository interface** and its **EF Core implementation** for the entity the user names.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

1. Read `abp-dev/references/ddd-domain.md` — **Repository Interfaces** section.
2. Read `abp-dev/references/efcore.md` — **Custom Repository Implementation** section.
3. Fetch https://docs.abp.io/en/abp/latest/Repositories and https://docs.abp.io/en/abp/latest/Entity-Framework-Core for the latest API details.

Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## Files to create

### 1. `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Volo.Abp.Domain.Repositories;

namespace Acme.BookStore.<Entity>s;

public interface I<Entity>Repository : IRepository<<Entity>, Guid>
{
    Task<List<<Entity>>> GetListAsync(
        string? filterText = null,
        int maxResultCount = int.MaxValue,
        int skipCount = 0,
        string? sorting = null,
        CancellationToken cancellationToken = default
    );

    Task<<Entity>?> FindByNameAsync(
        string name,
        CancellationToken cancellationToken = default
    );
}
```

Add or remove query methods based on the entity's actual properties. Ask the user if they need additional filtering parameters (e.g. enum filter, date range).

### 2. `src/Acme.BookStore.EntityFrameworkCore/<Entity>s/EfCore<Entity>Repository.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Domain.Repositories.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace Acme.BookStore.EntityFrameworkCore.<Entity>s;

public class EfCore<Entity>Repository
    : EfCoreRepository<BookStoreDbContext, <Entity>, Guid>, I<Entity>Repository
{
    public EfCore<Entity>Repository(IDbContextProvider<BookStoreDbContext> dbContextProvider)
        : base(dbContextProvider) { }

    public async Task<List<<Entity>>> GetListAsync(
        string? filterText = null,
        int maxResultCount = int.MaxValue,
        int skipCount = 0,
        string? sorting = null,
        CancellationToken cancellationToken = default)
    {
        var dbSet = await GetDbSetAsync();
        return await dbSet
            .WhereIf(!filterText.IsNullOrWhiteSpace(), x => x.Name.Contains(filterText!))
            .OrderBy(sorting.IsNullOrWhiteSpace() ? nameof(<Entity>.Name) : sorting)
            .PageBy(skipCount, maxResultCount)
            .ToListAsync(GetCancellationToken(cancellationToken));
    }

    public async Task<<Entity>?> FindByNameAsync(
        string name,
        CancellationToken cancellationToken = default)
    {
        var dbSet = await GetDbSetAsync();
        return await dbSet.FirstOrDefaultAsync(
            x => x.Name == name,
            GetCancellationToken(cancellationToken));
    }
}
```

### 3. EF Core model configuration snippet

Show the block to add inside `ConfigureBookStore()` in `BookStoreDbContextModelCreatingExtensions.cs`:

```csharp
builder.Entity<<Entity>>(b =>
{
    b.ToTable("App<Entity>s");
    b.ConfigureByConvention();   // REQUIRED — configures ABP base properties
    b.Property(x => x.Name)
     .IsRequired()
     .HasMaxLength(<Entity>Consts.MaxNameLength);
    b.HasIndex(x => x.Name);
});
```

Also show the `DbSet` line to add to `BookStoreDbContext`:
```csharp
public DbSet<<Entity>> <Entity>s { get; set; }
```

### 4. Module registration snippet

Show the line to add in `BookStoreEntityFrameworkCoreModule.ConfigureServices`:
```csharp
options.AddRepository<<Entity>, EfCore<Entity>Repository>();
```

---

## After generating

Remind the user to run the EF Core migration:
```bash
dotnet ef migrations add "Added_<Entity>_Entity" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet run --project src/Acme.BookStore.DbMigrator
```
