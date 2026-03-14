You are an expert ABP Framework developer. The user wants to scaffold a **full ABP CRUD feature** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

## What to generate

Scaffold the following files using the correct layered-architecture paths.
Replace every occurrence of `<Entity>` with the PascalCase entity name and `<entity>` with the camelCase version.

Read `abp-dev/references/ddd-domain.md`, `abp-dev/references/ddd-application.md`, and `abp-dev/references/efcore.md` for the canonical patterns before generating each file.

---

### 1. Domain layer — `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`

- Extend `FullAuditedAggregateRoot<Guid>`
- Private/protected setters on all properties
- `protected <Entity>() { }` ORM constructor
- Primary constructor using `IGuidGenerator`-assigned ID
- Business methods to mutate private-setter properties
- Constants for max string lengths

### 2. Domain layer — `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`

- Extend `IRepository<<Entity>, Guid>`
- Add `GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting)` and `FindByNameAsync(string name)` signatures

### 3. Domain layer — `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`

- Extend `DomainService`
- `CreateAsync` method that enforces unique name via repository
- Use `GuidGenerator.Create()` (from `DomainService` base)

### 4. Application.Contracts — `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity>Dto.cs`

- Extend `AuditedEntityDto<Guid>`
- Mirror entity public properties

### 5. Application.Contracts — `src/Acme.BookStore.Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

- Plain class with `[Required]` / `[StringLength]` annotations
- No base class needed

### 6. Application.Contracts — `src/Acme.BookStore.Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

- Extend `PagedAndSortedResultRequestDto`
- Add `string? FilterText` property

### 7. Application.Contracts — `src/Acme.BookStore.Application.Contracts/<Entity>s/I<Entity>AppService.cs`

- Extend `IApplicationService`
- Methods: `GetListAsync`, `GetAsync`, `CreateAsync`, `UpdateAsync`, `DeleteAsync`

### 8. Application layer — `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`

- Extend `ApplicationService`, implement `I<Entity>AppService`
- Inject `I<Entity>Repository` and `<Entity>Manager`
- Decorate class with `[Authorize(BookStorePermissions.<Entity>s.Default)]`
- Decorate Create/Update/Delete with the matching sub-permission attribute
- Use `ObjectMapper.Map<>()` for entity↔DTO conversion

### 9. EntityFrameworkCore — add `DbSet<<Entity>>` to `BookStoreDbContext`

Show only the property line and the `OnModelCreating` call as a diff/snippet.

### 10. EntityFrameworkCore — `src/Acme.BookStore.EntityFrameworkCore/<Entity>s/EfCore<Entity>Repository.cs`

- Extend `EfCoreRepository<BookStoreDbContext, <Entity>, Guid>`, implement `I<Entity>Repository`
- Implement `GetListAsync` with `WhereIf` filtering, `OrderBy`, `PageBy`
- Implement `FindByNameAsync`

### 11. EntityFrameworkCore model config snippet

Show the `builder.Entity<<Entity>>` block to add inside `ConfigureBookStore()`.

### 12. (Optional) Razor Page index — `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml` + `Index.cshtml.cs`

Ask the user if they want the Razor Page scaffold as well. Read `abp-dev/references/ui-razorpages.md` first.

---

## After generating all files

- Remind the user to run `Add-Migration "Added_<Entity>_Entity"` and then the DbMigrator.
- Remind them to register the EF Core repository in the module: `options.AddRepository<<Entity>, EfCore<Entity>Repository>();`
- Remind them to define permissions in the `BookStorePermissions` class.
