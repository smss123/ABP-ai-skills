# ABP: Troubleshooting & Testing

> 📖 Official docs:
> - Integration Tests: https://abp.io/docs/latest/testing/integration-tests
> - UI Tests: https://abp.io/docs/latest/testing/ui-tests
> - Testing (general): https://docs.abp.io/en/abp/latest/Testing
> - AutoMapper / Object Mapping: https://docs.abp.io/en/abp/latest/Object-To-Object-Mapping
> - EF Core Migrations: https://docs.abp.io/en/abp/latest/Entity-Framework-Core-Migrations
>
> Fetch these pages for the latest testing patterns and troubleshooting guidance.

## Integration Testing

### Test Infrastructure

ABP integration tests use **in-memory SQLite** (EF Core) or **EphemeralMongo** — real DBMS behavior without external setup.

```csharp
// Application.Tests/BookStoreApplicationTestBase.cs
public abstract class BookStoreApplicationTestBase
    : AbpIntegratedTest<BookStoreApplicationTestModule>
{
}

// Application.Tests.Module/BookStoreApplicationTestModule.cs
[DependsOn(
    typeof(BookStoreApplicationModule),
    typeof(AbpTestBaseModule)
)]
public class BookStoreApplicationTestModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        // Use in-memory SQLite for tests
        context.Services.AddAbpDbContext<BookStoreDbContext>(options =>
        {
            options.AddDefaultRepositories();
        });
        Configure<AbpDbContextOptions>(options =>
        {
            options.Configure(ctx => ctx.DbContextOptions.UseInMemoryDatabase("TestDb"));
        });
    }
}
```

### Seeding Test Data

```csharp
// Application.Tests/BookStoreTestDataSeedContributor.cs
public class BookStoreTestDataSeedContributor
    : IDataSeedContributor, ITransientDependency
{
    private readonly IRepository<Book, Guid> _bookRepository;

    public BookStoreTestDataSeedContributor(IRepository<Book, Guid> bookRepository)
    {
        _bookRepository = bookRepository;
    }

    public async Task SeedAsync(DataSeedContext context)
    {
        await _bookRepository.InsertAsync(new Book(
            BookStoreTestData.Book1Id,
            "Test Book 1",
            BookType.Novel,
            price: 25m,
            DateTime.Now
        ));
    }
}

// Store known IDs as constants
public static class BookStoreTestData
{
    public static Guid Book1Id { get; } = Guid.Parse("...");
}
```

### Writing Application Service Tests

```csharp
public class BookAppService_Tests : BookStoreApplicationTestBase
{
    private readonly IBookAppService _bookAppService;

    public BookAppService_Tests()
    {
        _bookAppService = GetRequiredService<IBookAppService>();
    }

    [Fact]
    public async Task Should_Get_Book()
    {
        var book = await _bookAppService.GetAsync(BookStoreTestData.Book1Id);

        book.ShouldNotBeNull();
        book.Name.ShouldBe("Test Book 1");
    }

    [Fact]
    public async Task Should_Throw_On_Duplicate_Name()
    {
        await Assert.ThrowsAsync<UserFriendlyException>(async () =>
        {
            await _bookAppService.CreateAsync(new CreateUpdateBookDto
            {
                Name = "Test Book 1" // duplicate
            });
        });
    }
}
```

### Unit of Work in Tests

```csharp
[Fact]
public async Task Should_Query_With_UoW()
{
    await WithUnitOfWorkAsync(async () =>
    {
        var books = await _bookRepository.GetListAsync();
        books.Count.ShouldBeGreaterThan(0);
    });
}
```

### Direct DbContext Access

```csharp
public class BookRepository_Tests : BookStoreApplicationTestBase
{
    private readonly IDbContextProvider<BookStoreDbContext> _dbContextProvider;

    [Fact]
    public async Task Should_Find_Book_Directly()
    {
        await WithUnitOfWorkAsync(async () =>
        {
            var dbContext = await _dbContextProvider.GetDbContextAsync();
            var book = await dbContext.Books
                .FirstOrDefaultAsync(b => b.Id == BookStoreTestData.Book1Id);
            book.ShouldNotBeNull();
        });
    }
}
```

### Bypass Authorization in Tests

```csharp
// In test module ConfigureServices:
context.Services.AddAlwaysAllowAuthorization();
```

### Test Project Structure

```
Acme.BookStore/
├── test/
│   ├── Acme.BookStore.Domain.Tests/           ← domain service tests
│   ├── Acme.BookStore.Application.Tests/      ← app service tests (abstract)
│   ├── Acme.BookStore.EntityFrameworkCore.Tests/ ← EF Core concrete tests
│   └── Acme.BookStore.TestBase/               ← shared test data + base classes
```

Abstract test classes in Domain/Application; concrete test classes in EntityFrameworkCore to support multiple ORM implementations.

### UI Testing

ABP defers UI testing to framework-native tools:
- **Razor Pages**: ASP.NET Core `WebApplicationFactory` for server-side HTML testing
- **End-to-end (all UIs)**: Playwright or Selenium for visual interaction testing
- ABP does not provide a UI test framework — use standard tooling

## Common Errors & Fixes

### 1. AutoMapper: "Missing type map configuration"

**Error:** `AutoMapperMappingException: Missing type map configuration or unsupported mapping`

**Causes & fixes:**
```csharp
// ✗ WRONG: CreateMap defined in wrong project or wrong profile class
// ✓ FIX 1: Profile must be in the Application project
public class BookStoreApplicationAutoMapperProfile : Profile
{
    public BookStoreApplicationAutoMapperProfile()
    {
        CreateMap<Book, BookDto>();             // Entity → DTO
        CreateMap<CreateUpdateBookDto, Book>(); // DTO → Entity (for manual mapping)
    }
}

// ✓ FIX 2: Profile must be registered — ABP auto-discovers profiles in the module assembly
// Confirm the Application module's assembly is scanned. If manual:
Configure<AbpAutoMapperOptions>(options =>
{
    options.AddMaps<BookStoreApplicationModule>();
});
```

---

### 2. AbpAuthorizationException even after granting permission

**Checklist:**
1. Permission string constant matches exactly between `PermissionDefinitionProvider` and `[Authorize]`
2. `PermissionDefinitionProvider` class is in `Application.Contracts` project (ABP auto-discovers it)
3. The `Application.Contracts` module is in the dependency chain of the running app
4. Permission was granted to the role/user in the database — re-run `DbMigrator` after seeding
5. User is logged out and back in — permission cache may be stale

```csharp
// ✗ WRONG — typo in constant
[Authorize("BookStore.Book.Create")]  // missing 's'
// ✓ CORRECT — use the constant, never a raw string
[Authorize(BookStorePermissions.Books.Create)]
```

---

### 3. Audit properties (CreationTime, IsDeleted) not saved

**Error:** Soft-delete not working, CreationTime always null/zero.

**Fix:** `b.ConfigureByConvention()` is missing from entity configuration.

```csharp
// ✗ WRONG
builder.Entity<Book>(b =>
{
    b.ToTable("AppBooks");
    b.Property(x => x.Name).HasMaxLength(128);
    // ConfigureByConvention() missing!
});

// ✓ CORRECT — always call it right after ToTable
builder.Entity<Book>(b =>
{
    b.ToTable("AppBooks");
    b.ConfigureByConvention();  // ← REQUIRED — configures all ABP base class columns
    b.Property(x => x.Name).HasMaxLength(128);
});
```

---

### 4. Module not found / service not registered

**Error:** `InvalidOperationException: No service for type 'IBookAppService' has been registered`

**Checklist:**
1. The module containing the service is listed in `[DependsOn]` of the running app module
2. The service implements `ITransientDependency` or a recognized base class
3. Check `Program.cs` — the root module passed to `AddApplicationAsync<T>` must have the full dependency chain

```csharp
// Verify dependency chain — Web → Application → Domain
[DependsOn(
    typeof(BookStoreApplicationModule),   // ← must be here
    typeof(BookStoreEntityFrameworkCoreModule)
)]
public class BookStoreWebModule : AbpModule { }
```

---

### 5. JavaScript proxy not found (`acme.bookStore.books.book` is undefined)

**Fix:** Regenerate the dynamic JavaScript proxies after adding/changing application services.

```bash
# From the Web project root
abp generate-proxy -t js --url https://localhost:44300
```

Or enable dynamic proxies (automatically served at runtime — no generation needed):
```csharp
Configure<AbpAspNetCoreMvcOptions>(options =>
{
    options.ConventionalControllers
           .Create(typeof(BookStoreApplicationModule).Assembly);
});
// Then in the .cshtml layout or page:
// <script src="~/Abp/ApplicationApiDescriptionModel.js"></script>  -- served automatically
```

---

### 6. Migration fails: "Column already exists" or "Table not found"

**Fix:** Never mix `dotnet ef database update` with `DbMigrator`. Always use one approach:

```bash
# Development — apply pending migrations
dotnet run --project src/Acme.BookStore.DbMigrator

# After adding entities — create migration in the DbMigrations project
dotnet ef migrations add "Added_Product" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations \
  --startup-project src/Acme.BookStore.DbMigrator
```

---

## Testing

### Unit Test: Domain Service

```csharp
// test/Acme.BookStore.Domain.Tests/Books/BookManagerTests.cs
using System.Threading.Tasks;
using Shouldly;
using Volo.Abp;
using Xunit;

namespace Acme.BookStore.Books;

public class BookManagerTests : BookStoreDomainTestBase
{
    private readonly BookManager _bookManager;
    private readonly IBookRepository _bookRepository;

    public BookManagerTests()
    {
        _bookManager = GetRequiredService<BookManager>();
        _bookRepository = GetRequiredService<IBookRepository>();
    }

    [Fact]
    public async Task Should_Create_Valid_Book()
    {
        var book = await _bookManager.CreateAsync("Clean Code", BookType.Technology, 29.99m, DateTime.Now);

        book.ShouldNotBeNull();
        book.Name.ShouldBe("Clean Code");
        book.Type.ShouldBe(BookType.Technology);
    }

    [Fact]
    public async Task Should_Not_Create_Book_With_Duplicate_Name()
    {
        // Arrange — create and persist a book with a known name
        await WithUnitOfWorkAsync(async () =>
        {
            var book = await _bookManager.CreateAsync("Existing Book", BookType.Technology, 10m, DateTime.Now);
            await _bookRepository.InsertAsync(book, autoSave: true);
        });

        // Act & Assert
        await Should.ThrowAsync<UserFriendlyException>(async () =>
        {
            await _bookManager.CreateAsync("Existing Book", BookType.Technology, 20m, DateTime.Now);
        });
    }
}
```

### Integration Test: Application Service

```csharp
// test/Acme.BookStore.Application.Tests/Books/BookAppServiceTests.cs
using System.Threading.Tasks;
using Shouldly;
using Volo.Abp.Validation;
using Xunit;

namespace Acme.BookStore.Books;

public class BookAppServiceTests : BookStoreApplicationTestBase
{
    private readonly IBookAppService _bookAppService;

    public BookAppServiceTests()
    {
        _bookAppService = GetRequiredService<IBookAppService>();
    }

    [Fact]
    public async Task Should_Get_Books_List()
    {
        var result = await _bookAppService.GetListAsync(new GetBooksInput());
        result.TotalCount.ShouldBeGreaterThan(0);
        result.Items.ShouldContain(b => b.Name == "The Hitchhiker's Guide"); // from test seed data
    }

    [Fact]
    public async Task Should_Create_Book()
    {
        var result = await _bookAppService.CreateAsync(new CreateUpdateBookDto
        {
            Name        = "New Test Book",
            Type        = BookType.Technology,
            Price       = 14.99m,
            PublishDate = DateTime.Now
        });

        result.Id.ShouldNotBe(Guid.Empty);
        result.Name.ShouldBe("New Test Book");
    }

    [Fact]
    public async Task Should_Require_Name()
    {
        await Should.ThrowAsync<AbpValidationException>(async () =>
        {
            await _bookAppService.CreateAsync(new CreateUpdateBookDto
            {
                Name        = "",  // invalid
                Type        = BookType.Technology,
                PublishDate = DateTime.Now
            });
        });
    }
}
```

### Test Data Seed Contributor

```csharp
// test/Acme.BookStore.TestBase/BookStoreTestDataSeedContributor.cs
using System.Threading.Tasks;
using Volo.Abp.Data;
using Volo.Abp.DependencyInjection;

namespace Acme.BookStore;

public class BookStoreTestDataSeedContributor : IDataSeedContributor, ITransientDependency
{
    private readonly IBookRepository _bookRepository;
    private readonly BookManager _bookManager;

    public BookStoreTestDataSeedContributor(
        IBookRepository bookRepository,
        BookManager bookManager)
    {
        _bookRepository = bookRepository;
        _bookManager = bookManager;
    }

    public async Task SeedAsync(DataSeedContext context)
    {
        if (await _bookRepository.GetCountAsync() > 0)
            return;

        var book = await _bookManager.CreateAsync(
            "The Hitchhiker's Guide",
            BookType.ScienceFiction,
            9.99m,
            new DateTime(1979, 10, 12)
        );
        await _bookRepository.InsertAsync(book, autoSave: true);
    }
}
```

### Test project base classes

ABP provides pre-wired test base classes per layer:

| Test project | Inherits from |
|---|---|
| Domain.Tests | `BookStoreDomainTestBase` → `AbpIntegratedTest<BookStoreDomainTestModule>` |
| Application.Tests | `BookStoreApplicationTestBase` → `AbpIntegratedTest<BookStoreApplicationTestModule>` |
| EntityFrameworkCore.Tests | Uses in-memory SQLite database |

All use real DI container + real (SQLite in-memory) database — no mocking needed for repository tests.
