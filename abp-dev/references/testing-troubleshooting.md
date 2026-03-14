# ABP: Troubleshooting & Testing

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
        var book = await _bookManager.CreateAsync("Clean Code", BookType.Technology, 29.99f, DateTime.Now);

        book.ShouldNotBeNull();
        book.Name.ShouldBe("Clean Code");
        book.Type.ShouldBe(BookType.Technology);
    }

    [Fact]
    public async Task Should_Not_Create_Book_With_Duplicate_Name()
    {
        // Arrange — seed a book with known name via test data seeder
        await WithUnitOfWorkAsync(async () =>
        {
            await _bookManager.CreateAsync("Existing Book", BookType.Technology, 10f, DateTime.Now);
        });

        // Act & Assert
        await Should.ThrowAsync<UserFriendlyException>(async () =>
        {
            await _bookManager.CreateAsync("Existing Book", BookType.Technology, 20f, DateTime.Now);
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
            Price       = 14.99f,
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
            9.99f,
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
