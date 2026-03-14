---
mode: 'agent'
description: 'Scaffold a full ABP Framework CRUD feature across all layers'
tools: ['codebase', 'fetch', 'findTestFiles', 'search', 'usages', 'editFiles', 'runCommands']
---

You are an expert ABP Framework developer. Scaffold a **full ABP CRUD feature** for the entity the user names.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

1. Read `abp-dev/references/ddd-domain.md` for entity and repository patterns.
2. Read `abp-dev/references/ddd-application.md` for DTO and application service patterns.
3. Read `abp-dev/references/efcore.md` for EF Core configuration and repository patterns.
4. Read `abp-dev/references/authorization.md` for permission patterns.
5. Fetch the matching official docs URL from those files when the network is available.

Replace every `<Entity>` placeholder below with the PascalCase entity name and `<entity>` with the camelCase version.

---

## Files to create

### 1. `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`

- Extend `FullAuditedAggregateRoot<Guid>`
- Private/protected setters on all properties
- `protected <Entity>() { }` ORM constructor
- Primary constructor that accepts `Guid id` (assigned via `IGuidGenerator` at the call site)
- Business methods for every private-setter property (e.g. `SetName`, `ChangePrice`)
- Static inner class `<Entity>Consts` with `MaxNameLength` etc.

### 2. `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- `Task<List<<Entity>>> GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting, CancellationToken cancellationToken = default)`
- `Task<<Entity>?> FindByNameAsync(string name, CancellationToken cancellationToken = default)`

### 3. `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService`
- `CreateAsync(...)` — use `GuidGenerator.Create()`, enforce unique name via repository, throw `BusinessException` on duplicate

### 4. `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity>Dto.cs`

- Extend `AuditedEntityDto<Guid>` (or `FullAuditedEntityDto<Guid>` to match audit level)
- Mirror all public entity properties

### 5. `src/Acme.BookStore.Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

- Plain class (no base class)
- `[Required]` and `[StringLength(<Entity>Consts.MaxNameLength)]` on string properties

### 6. `src/Acme.BookStore.Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

- Extend `PagedAndSortedResultRequestDto`
- Add `public string? FilterText { get; set; }`

### 7. `src/Acme.BookStore.Application.Contracts/<Entity>s/I<Entity>AppService.cs`

- Extend `IApplicationService`
- Methods:
  - `Task<PagedResultDto<<Entity>Dto>> GetListAsync(Get<Entity>sInput input)`
  - `Task<<Entity>Dto> GetAsync(Guid id)`
  - `Task<<Entity>Dto> CreateAsync(CreateUpdate<Entity>Dto input)`
  - `Task<<Entity>Dto> UpdateAsync(Guid id, CreateUpdate<Entity>Dto input)`
  - `Task DeleteAsync(Guid id)`

### 8. `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`

- Extend `ApplicationService`, implement `I<Entity>AppService`
- Constructor-inject `I<Entity>Repository` and `<Entity>Manager`
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on the class
- `[Authorize(BookStorePermissions.<Entity>s.Create)]` on `CreateAsync`
- `[Authorize(BookStorePermissions.<Entity>s.Edit)]` on `UpdateAsync`
- `[Authorize(BookStorePermissions.<Entity>s.Delete)]` on `DeleteAsync`
- Use `ObjectMapper.Map<>()` for entity↔DTO conversion

### 9. EF Core — DbSet and model config snippets

Show the property and `OnModelCreating` lines to add to `BookStoreDbContext`:

```csharp
// In BookStoreDbContext:
public DbSet<<Entity>> <Entity>s { get; set; }

// In ConfigureBookStore():
builder.Entity<<Entity>>(b =>
{
    b.ToTable("App<Entity>s");
    b.ConfigureByConvention();
    b.Property(x => x.Name).IsRequired().HasMaxLength(<Entity>Consts.MaxNameLength);
});
```

### 10. `src/Acme.BookStore.EntityFrameworkCore/<Entity>s/EfCore<Entity>Repository.cs`

- Extend `EfCoreRepository<BookStoreDbContext, <Entity>, Guid>`, implement `I<Entity>Repository`
- `GetListAsync`: `WhereIf(!filterText.IsNullOrWhiteSpace(), x => x.Name.Contains(filterText!))`, `OrderBy(sorting ?? nameof(<Entity>.Name))`, `PageBy(skipCount, maxResultCount)`
- `FindByNameAsync`: `FirstOrDefaultAsync(x => x.Name == name, cancellationToken)`

### 11. AutoMapper profile entry

Show the two `CreateMap` lines to add to `BookStoreApplicationAutoMapperProfile`:
```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

### 12. (Optional) Razor Pages

Ask the user whether they want Razor Pages generated too.  
If yes, read `abp-dev/references/ui-razorpages.md` first, then create:
- `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml` + `.cshtml.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml` + `.cshtml.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml` + `.cshtml.cs`
- Menu item registration snippet for `BookStoreMenuContributor`

---

## After generating

Remind the user to:
1. Add migration: `dotnet ef migrations add "Added_<Entity>_Entity" --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations`
2. Apply migration: `dotnet run --project src/Acme.BookStore.DbMigrator`
3. Register the repository in `BookStoreEntityFrameworkCoreModule`: `options.AddRepository<<Entity>, EfCore<Entity>Repository>();`
4. Define permissions in `BookStorePermissions` and `BookStorePermissionDefinitionProvider`.
