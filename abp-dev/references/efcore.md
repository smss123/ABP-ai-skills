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

## Switching DBMS

ABP supports multiple EF Core providers. Use `-dbms` when creating a project, or switch manually.

### Supported providers

| DBMS | `-dbms` flag | ABP module | `Use*()` method |
|---|---|---|---|
| SQL Server (default) | `SqlServer` | `AbpEntityFrameworkCoreSqlServerModule` | `UseSqlServer()` |
| PostgreSQL | `PostgreSQL` | `AbpEntityFrameworkCorePostgreSqlModule` | `UseNpgsql()` |
| MySQL | `MySQL` | `AbpEntityFrameworkCoreMySQLModule` | `UseMySql(…)` |
| SQLite | `SQLite` | `AbpEntityFrameworkCoreSqliteModule` | `UseSqlite()` |
| Oracle | `Oracle` | `AbpEntityFrameworkCoreOracleModule` | `UseOracle()` |
| Oracle (Devart) | `Oracle-Devart` | `AbpEntityFrameworkCoreOracleDevartModule` | — |

### Steps to switch provider

1. Remove the old provider package and `[DependsOn]` entry (e.g. `AbpEntityFrameworkCoreSqlServerModule`).
2. Add the new provider package via `abp add-package` (or NuGet).
3. Add the new module to `[DependsOn]`.
4. Update `Configure<AbpDbContextOptions>` to use the new provider method (see below).
5. **Delete the `Migrations/` folder** — EF Core migrations are provider-specific.
6. Run `Add-Migration "Initial"` to regenerate migrations for the new DBMS.

### DbContext options — conditional connection pattern

Use this pattern so ABP can share an existing connection (for transaction propagation) and fall back to a new one when none exists:

```csharp
Configure<AbpDbContextOptions>(options =>
{
    options.Configure(ctx =>
    {
        if (ctx.ExistingConnection != null)
        {
            // reuse an open connection (e.g. within a UoW transaction)
            ctx.DbContextOptions.UseMySql(ctx.ExistingConnection,
                ServerVersion.AutoDetect(ctx.ExistingConnection));
        }
        else
        {
            ctx.DbContextOptions.UseMySql(ctx.ConnectionString,
                ServerVersion.AutoDetect(ctx.ConnectionString));
        }
    });
});
```

Replace `UseMySql` with `UseNpgsql`, `UseSqlite`, etc. as appropriate.

### Provider-specific details

#### MySQL

**Packages (choose one):**

| Option | Package | Module | Method |
|---|---|---|---|
| ABP MySQL | `Volo.Abp.EntityFrameworkCore.MySQL` | `AbpEntityFrameworkCoreMySQLModule` | `UseMySQL()` |
| Pomelo (recommended) | `Volo.Abp.EntityFrameworkCore.MySQL.Pomelo` | `AbpEntityFrameworkCoreMySQLPomeloModule` | `UseMySql(…, ServerVersion)` |

**Pomelo configuration** (requires explicit `ServerVersion`):

```csharp
options.UseMySql(
    connectionString,
    ServerVersion.AutoDetect(connectionString)
    // or pin: ServerVersion.Parse("8.4.6")
);
```

**Connection string:**
```json
"Default": "Server=localhost;Port=3306;Database=MyDb;Uid=root;Pwd=password;"
```

**Field length adjustment** — some ABP module columns exceed MySQL defaults. Configure each affected module:

```csharp
builder.ConfigureIdentityServer(options =>
{
    options.DatabaseProvider = EfCoreDatabaseProvider.MySql;
});
```

---

#### PostgreSQL

**Package:** `Volo.Abp.EntityFrameworkCore.PostgreSql`
**Module:** `AbpEntityFrameworkCorePostgreSqlModule`
**Method:** `UseNpgsql()`

**Critical — legacy timestamp behavior** (Npgsql 6.0+ breaking change): add this in both `PreConfigureServices` and `DbContextFactory`:

```csharp
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
```

Without this switch, `DateTime` values are rejected unless explicitly typed as UTC.

**Connection string:**
```
Server=localhost;Port=5432;Database=MyDb;User Id=postgres;Password=xxx
```

---

#### Oracle (Official)

**Package:** `Volo.Abp.EntityFrameworkCore.Oracle`
**Module:** `AbpEntityFrameworkCoreOracleModule`
**Method:** `UseOracle()`

**Oracle 23ai / pre-23ai compatibility:**

```csharp
Configure<AbpDbContextOptions>(options =>
{
    options.UseOracle(x =>
        x.UseOracleSQLCompatibility(OracleSQLCompatibility.DatabaseVersion19));
});
```

**Prerequisite:** Oracle v12.2+ (128-byte identifier support). Earlier versions limited identifiers to 30 bytes.

**Known issues:**

| Error | Cause | Fix |
|---|---|---|
| `ORA-12899` (string too large) | Oracle limits `NVARCHAR2(2000)` | Add migration to convert column → `long` → `clob` with `HasMaxLength(4000)` |
| `ORA-00904` ("FALSE" invalid identifier) | Pre-23ai boolean handling | Set `OracleSQLCompatibility.DatabaseVersion19` |

---

#### Oracle (Devart)

**Package:** `Volo.Abp.EntityFrameworkCore.Oracle.Devart`
**Module:** `AbpEntityFrameworkCoreOracleDevartModule`
**Method:** `UseOracle()`

Same connection string and migration workflow as the official Oracle provider. Devart is a paid third-party library — use the official Oracle provider unless you have a specific Devart requirement.

**ORA-12899 fix** requires a two-step migration:
1. Run `Add-Migration Oracle_Long_Conversion` — converts affected columns to `long`
2. Run `Add-Migration Oracle_Clob_Conversion` — converts to `clob` with `HasMaxLength(4000)`

---

#### SQLite

**Package:** `Volo.Abp.EntityFrameworkCore.Sqlite`
**Module:** `AbpEntityFrameworkCoreSqliteModule`
**Method:** `UseSqlite()`

**Connection string (file-based):**
```json
"Default": "Filename=./MyApp.sqlite"
```

SQLite is suitable for development and testing only — it does not support all EF Core migration operations (e.g. column type changes require table recreate).

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

### Passing custom properties to seed contributors

```csharp
// DbMigrator or test initialization
await _dataSeeder.SeedAsync(
    new DataSeedContext()
        .WithProperty("AdminEmail", "admin@example.com")
        .WithProperty("AdminPassword", "Str0ng!Pass")
);

// Inside the contributor
public async Task SeedAsync(DataSeedContext context)
{
    var adminEmail = context.GetProperty<string>("AdminEmail");
}
```

### Multi-tenant seeding

Always scope data operations to the correct tenant:

```csharp
public async Task SeedAsync(DataSeedContext context)
{
    using (_currentTenant.Change(context?.TenantId))
    {
        if (await _bookRepository.GetCountAsync() > 0)
            return;

        await _bookRepository.InsertAsync(/* ... */, autoSave: true);
    }
}
```

### Avoiding timeouts with many contributors

For large seed runs, use `IDataSeeder.SeedInSeparateUowAsync()` — each contributor runs in its own unit of work:

```csharp
await _dataSeeder.SeedInSeparateUowAsync(new DataSeedContext());
```
