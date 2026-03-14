You are an expert ABP Framework developer. Scaffold an **ABP repository interface** and its **EF Core implementation** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Read `abp-dev/references/ddd-domain.md` (Repository Interfaces section) and `abp-dev/references/efcore.md` (Custom Repository Implementation section) before generating any code.

## What to generate

### 1. `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- `Task<List<<Entity>>> GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting, CancellationToken ct = default)`
- `Task<<Entity>?> FindByNameAsync(string name, CancellationToken ct = default)`
- Add any other query methods the entity needs

### 2. `src/Acme.BookStore.EntityFrameworkCore/<Entity>s/EfCore<Entity>Repository.cs`

- Extend `EfCoreRepository<BookStoreDbContext, <Entity>, Guid>`, implement `I<Entity>Repository`
- Constructor: `IDbContextProvider<BookStoreDbContext>` → pass to base
- `GetListAsync`: `WhereIf` for filterText, `OrderBy(sorting ?? nameof(<Entity>.Name))`, `PageBy(skipCount, maxResultCount)`, `.ToListAsync()`
- `FindByNameAsync`: `FirstOrDefaultAsync(x => x.Name == name, ct)`

### 3. EF Core snippets (show as diffs / code blocks, don't create new files)

**DbSet** to add to `BookStoreDbContext`:
```csharp
public DbSet<<Entity>> <Entity>s { get; set; }
```

**Model config** block to add inside `ConfigureBookStore()`:
```csharp
builder.Entity<<Entity>>(b =>
{
    b.ToTable("App<Entity>s");
    b.ConfigureByConvention();
    b.Property(x => x.Name).IsRequired().HasMaxLength(<Entity>Consts.MaxNameLength);
    b.HasIndex(x => x.Name);
});
```

**Module registration** in `BookStoreEntityFrameworkCoreModule`:
```csharp
options.AddRepository<<Entity>, EfCore<Entity>Repository>();
```

## After generating

Remind the user to run migrations:
```bash
dotnet ef migrations add "Added_<Entity>_Entity" --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet run --project src/Acme.BookStore.DbMigrator
```
