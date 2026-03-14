---
name: abp-crud
description: Full ABP Framework CRUD scaffold — entity, DTOs, app service, EF Core config, and Razor Page
---

# ABP Framework CRUD Scaffold

A step-by-step Windsurf Cascade workflow that creates all layers of an ABP Framework CRUD feature.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Properties** — name, type, and whether each is required (e.g. `Name:string:required`, `Price:decimal:optional`)
3. **Audit level** — FullAudit / Audit / None
4. **Generate Razor Page?** — Yes / No

---

## Step 1 — Read reference files

Read the following files before generating any code:
- `abp-dev/references/ddd-domain.md`
- `abp-dev/references/ddd-application.md`
- `abp-dev/references/efcore.md`
- `abp-dev/references/authorization.md`

---

## Step 2 — Domain layer

Create the entity, repository interface, and domain service:

### Entity: `src/Acme.BookStore.Domain/<Entity>s/<Entity>.cs`
- Base class determined by audit level chosen in inputs
- Private setters on all properties; business methods to mutate them
- Protected ORM constructor + primary constructor taking `Guid id`
- Constants inner class / companion `<Entity>Consts` with max length values

### Repository interface: `src/Acme.BookStore.Domain/<Entity>s/I<Entity>Repository.cs`
- Extend `IRepository<<Entity>, Guid>`
- `GetListAsync(string? filterText, int maxResultCount, int skipCount, string? sorting)`
- `FindByNameAsync(string name)` (if entity has a Name property)

### Domain service: `src/Acme.BookStore.Domain/<Entity>s/<Entity>Manager.cs`
- Extend `DomainService`
- `CreateAsync(...)` — enforce uniqueness, use `GuidGenerator.Create()`

---

## Step 3 — Application.Contracts layer

Create DTOs and application service interface:

### `<Entity>Dto.cs` — extends `AuditedEntityDto<Guid>` (or `FullAuditedEntityDto<Guid>`)
### `CreateUpdate<Entity>Dto.cs` — plain class with validation attributes
### `Get<Entity>sInput.cs` — extends `PagedAndSortedResultRequestDto`, adds `FilterText`
### `I<Entity>AppService.cs` — extends `IApplicationService` with CRUD method signatures

---

## Step 4 — Application layer

Create the application service implementation:

### `<Entity>AppService.cs`
- Extend `ApplicationService`, implement `I<Entity>AppService`
- Inject `I<Entity>Repository` and `<Entity>Manager`
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on class
- Sub-permission attributes on Create/Update/Delete methods
- `ObjectMapper.Map<>()` for entity↔DTO conversion

Also generate the AutoMapper profile entry:
```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

---

## Step 5 — EntityFrameworkCore layer

Generate:

1. **DbSet property** to add to `BookStoreDbContext`:
   ```csharp
   public DbSet<<Entity>> <Entity>s { get; set; }
   ```

2. **Model configuration** block to add inside `ConfigureBookStore()`:
   ```csharp
   builder.Entity<<Entity>>(b =>
   {
       b.ToTable("App<Entity>s");
       b.ConfigureByConvention();
       // property configurations...
   });
   ```

3. **Custom repository** `EfCore<Entity>Repository.cs` — extends `EfCoreRepository<BookStoreDbContext, <Entity>, Guid>`, implements `I<Entity>Repository`

4. **Module registration** reminder — add to `BookStoreEntityFrameworkCoreModule`:
   ```csharp
   options.AddRepository<<Entity>, EfCore<Entity>Repository>();
   ```

---

## Step 6 — Migration

Remind the user to run:
```bash
dotnet ef migrations add "Added_<Entity>_Entity" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations

dotnet run --project src/Acme.BookStore.DbMigrator
```

---

## Step 7 — Razor Page (if requested)

Read `abp-dev/references/ui-razorpages.md` and generate:
- `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml`
- `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml` + `.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml` + `.cs`
- Menu item registration snippet for `BookStoreMenuContributor`
