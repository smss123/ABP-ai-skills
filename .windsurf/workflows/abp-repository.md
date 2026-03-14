---
name: abp-repository
description: Scaffold an ABP repository interface and its EF Core implementation
---

# ABP Repository Scaffold

A Windsurf Cascade workflow that creates the repository interface in the Domain layer and its EF Core implementation in the EntityFrameworkCore layer.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Filter properties** — what fields should the list query be filterable by? (e.g. Name, Type, Status)
3. **Custom query methods** — any other queries beyond `GetListAsync` and `FindByNameAsync`?

---

## Step 1 — Read reference files

Read:
- `abp-dev/references/ddd-domain.md` (Repository Interfaces section)
- `abp-dev/references/efcore.md` (Custom Repository Implementation section)

---

## Step 2 — Create `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- `GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting, CancellationToken ct = default)`
- `FindByNameAsync(string name, CancellationToken ct = default)`
- Any extra query methods from inputs

---

## Step 3 — Create `src/Acme.BookStore.EntityFrameworkCore/<Entity>s/EfCore<Entity>Repository.cs`

- Extend `EfCoreRepository<BookStoreDbContext, <Entity>, Guid>`, implement `I<Entity>Repository`
- `GetListAsync`: `WhereIf` filtering → `OrderBy` → `PageBy` → `ToListAsync`
- `FindByNameAsync`: `FirstOrDefaultAsync(x => x.Name == name)`

---

## Step 4 — Show EF Core snippets

Show (as code blocks, don't create new files):

1. **DbSet** to add to `BookStoreDbContext`:
   ```csharp
   public DbSet<<Entity>> <Entity>s { get; set; }
   ```

2. **Model config** block inside `ConfigureBookStore()`:
   ```csharp
   builder.Entity<<Entity>>(b =>
   {
       b.ToTable("App<Entity>s");
       b.ConfigureByConvention();
       b.Property(x => x.Name).IsRequired().HasMaxLength(<Entity>Consts.MaxNameLength);
       b.HasIndex(x => x.Name);
   });
   ```

3. **Module registration** in `BookStoreEntityFrameworkCoreModule`:
   ```csharp
   options.AddRepository<<Entity>, EfCore<Entity>Repository>();
   ```

---

## Step 5 — Migration reminder

```bash
dotnet ef migrations add "Added_<Entity>_Entity" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet run --project src/Acme.BookStore.DbMigrator
```
