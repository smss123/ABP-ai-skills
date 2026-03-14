# ABP: EF Core Integration & Data Seeding

> 📖 Official docs:
> - EF Core Integration: https://docs.abp.io/en/abp/latest/Entity-Framework-Core
> - Data Seeding: https://docs.abp.io/en/abp/latest/Data-Seeding
> - Connection Strings: https://docs.abp.io/en/abp/latest/Connection-Strings
>
> Fetch these pages for the latest API details before generating EF Core or data seeding code.

## DbContext

Derive from `AbpDbContext<T>`. Live in `*.EntityFrameworkCore` project.

```csharp
// EntityFrameworkCore/BookStoreDbContext.cs
using Microsoft.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace Acme.BookStore.EntityFrameworkCore;

[ConnectionStringName("Default")]  // maps to appsettings ConnectionStrings:Default
public class BookStoreDbContext : AbpDbContext<BookStoreDbContext>
{
    // Only AggregateRoots get DbSet properties (not child entities)
    public DbSet<Book> Books { get; set; }
    public DbSet<Author> Authors { get; set; }

    public BookStoreDbContext(DbContextOptions<BookStoreDbContext> options)
        : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);  // ALWAYS call base first
        builder.ConfigureBookStore();   // delegate to extension method
    }
}
```

## Model Configuration Extension Method

```csharp
// EntityFrameworkCore/BookStoreDbContextModelCreatingExtensions.cs
using Microsoft.EntityFrameworkCore;
using Volo.Abp;
using Volo.Abp.EntityFrameworkCore.Modeling;

namespace Acme.BookStore.EntityFrameworkCore;

public static class BookStoreDbContextModelCreatingExtensions
{
    public static void ConfigureBookStore(this ModelBuilder builder)
    {
        Check.NotNull(builder, nameof(builder));

        builder.Entity<Book>(b =>
        {
            b.ToTable("AppBooks");           // table name
            b.ConfigureByConvention();       // REQUIRED: configures base ABP properties
            b.Property(x => x.Name)
             .IsRequired()
             .HasMaxLength(BookConsts.MaxNameLength);
            b.HasIndex(x => x.Name);
        });

        builder.Entity<Author>(b =>
        {
            b.ToTable("AppAuthors");
            b.ConfigureByConvention();
            b.Property(x => x.Name).IsRequired().HasMaxLength(64);
        });
    }
}
```

`b.ConfigureByConvention()` auto-configures: `Id`, `ConcurrencyStamp`, `ExtraProperties`,
`CreationTime`, `CreatorId`, soft-delete columns, etc.

---

## EF Core Module Registration

```csharp
// EntityFrameworkCore/BookStoreEntityFrameworkCoreModule.cs
[DependsOn(
    typeof(BookStoreDomainModule),
    typeof(AbpEntityFrameworkCoreModule),
    typeof(AbpEntityFrameworkCoreSqlServerModule)  // or Npgsql, Sqlite, etc.
)]
public class BookStoreEntityFrameworkCoreModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpDbContextOptions>(options =>
        {
            options.UseSqlServer();  // or UseNpgsql(), UseSqlite()
        });

        context.Services.AddAbpDbContext<BookStoreDbContext>(options =>
        {
            options.AddDefaultRepositories(includeAllEntities: true);
            // Custom repo implementations:
            options.AddRepository<Book, EfCoreBookRepository>();
        });
    }
}
```

---

## Custom Repository Implementation

```csharp
// EntityFrameworkCore/Books/EfCoreBookRepository.cs
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Volo.Abp.Domain.Repositories.EntityFrameworkCore;
using Volo.Abp.EntityFrameworkCore;

namespace Acme.BookStore.EntityFrameworkCore.Books;

public class EfCoreBookRepository
    : EfCoreRepository<BookStoreDbContext, Book, Guid>, IBookRepository
{
    public EfCoreBookRepository(IDbContextProvider<BookStoreDbContext> dbContextProvider)
        : base(dbContextProvider) { }

    public async Task<List<Book>> GetListAsync(
        string? filterText = null,
        BookType? type = null,
        int maxResultCount = int.MaxValue,
        int skipCount = 0,
        string? sorting = null)
    {
        var dbSet = await GetDbSetAsync();
        return await dbSet
            .WhereIf(!filterText.IsNullOrWhiteSpace(), b => b.Name.Contains(filterText!))
            .WhereIf(type.HasValue, b => b.Type == type)
            .OrderBy(sorting.IsNullOrWhiteSpace() ? nameof(Book.Name) : sorting)
            .PageBy(skipCount, maxResultCount)
            .ToListAsync();
    }

    public async Task<Book?> FindByNameAsync(string name)
    {
        var dbSet = await GetDbSetAsync();
        return await dbSet.FirstOrDefaultAsync(b => b.Name == name);
    }
}
```

---

## Migrations

Use the `DbMigrations` project (separate migration DbContext):

```bash
# In Package Manager Console — select *.EntityFrameworkCore.DbMigrations as default project
Add-Migration "Added_Book_Entity"
Update-Database

# OR with dotnet-ef CLI
dotnet ef migrations add "Added_Book_Entity" --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet ef database update --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
```

Always run **DbMigrator** console app (not `Update-Database`) in production or after seeding changes:
```bash
dotnet run --project src/Acme.BookStore.DbMigrator
```

---

## Data Seeding

```csharp
// Domain/Books/BookStoreDataSeedContributor.cs
using System.Threading.Tasks;
using Volo.Abp.Data;
using Volo.Abp.DependencyInjection;
using Volo.Abp.Domain.Repositories;
using Volo.Abp.Guids;

namespace Acme.BookStore.Books;

public class BookStoreDataSeedContributor : IDataSeedContributor, ITransientDependency
{
    private readonly IRepository<Book, Guid> _bookRepository;
    private readonly IGuidGenerator _guidGenerator;

    public BookStoreDataSeedContributor(
        IRepository<Book, Guid> bookRepository,
        IGuidGenerator guidGenerator)
    {
        _bookRepository = bookRepository;
        _guidGenerator  = guidGenerator;
    }

    public async Task SeedAsync(DataSeedContext context)
    {
        // Always guard — check if data already exists
        if (await _bookRepository.GetCountAsync() > 0)
            return;

        await _bookRepository.InsertAsync(
            new Book(_guidGenerator.Create(), "The Hitchhiker's Guide", BookType.ScienceFiction, 9.99m, new DateTime(1979, 10, 12)),
            autoSave: true
        );
        await _bookRepository.InsertAsync(
            new Book(_guidGenerator.Create(), "1984", BookType.Dystopia, 7.99m, new DateTime(1949, 6, 8)),
            autoSave: true
        );
    }
}
```

**Rules:**
- Implement `IDataSeedContributor` — ABP auto-discovers it
- Always check existing data first (idempotent)
- Use `ITransientDependency` for auto-registration
- Run via `DbMigrator` app which calls `IDataSeeder` internally
- Can receive parameters: `context["AdminEmail"]`, `context["AdminPassword"]`
