---
name: abp-app-service
description: Scaffold the ABP application service layer — DTOs, interface, implementation, AutoMapper profile
---

# ABP Application Service Layer Scaffold

A Windsurf Cascade workflow that creates the full application layer for an ABP entity: DTOs, service interface, service implementation, and AutoMapper entries.

## Inputs

Before starting, ask the user:
1. **Entity name** (PascalCase, singular, e.g. `Product`)
2. **Entity properties** — list the properties to mirror in DTOs
3. **Audit level** — does the entity extend `FullAuditedAggregateRoot` or `AuditedAggregateRoot`? (affects DTO base class)
4. **Permissions** — have permissions already been defined? (if not, suggest running `abp-permissions` first)

---

## Step 1 — Read reference files

Read:
- `abp-dev/references/ddd-application.md`
- `abp-dev/references/authorization.md`

---

## Step 2 — Application.Contracts layer

Create in `src/Acme.BookStore.Application.Contracts/<Entity>s/`:

### `<Entity>Dto.cs`
- Extend `AuditedEntityDto<Guid>` (or `FullAuditedEntityDto<Guid>`)
- Mirror all public entity properties

### `CreateUpdate<Entity>Dto.cs`
- Plain class; `[Required]` + `[StringLength]` on strings

### `Get<Entity>sInput.cs`
- Extend `PagedAndSortedResultRequestDto`; add `public string? FilterText { get; set; }`

### `I<Entity>AppService.cs`
- Extend `IApplicationService`; methods: `GetListAsync`, `GetAsync`, `CreateAsync`, `UpdateAsync`, `DeleteAsync`

---

## Step 3 — Application layer

Create `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`:
- Extend `ApplicationService`, implement `I<Entity>AppService`
- Inject `I<Entity>Repository` and `<Entity>Manager`
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on class
- `[Authorize(...Create/Edit/Delete)]` on write methods
- `ObjectMapper.Map<>()` for entity↔DTO mapping

---

## Step 4 — AutoMapper entries

Show the two `CreateMap` lines to add to `BookStoreApplicationAutoMapperProfile`:
```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

---

## Step 5 — Confirm

Ask the user:
1. Do you want **Razor Pages UI** scaffolded? → run workflow `abp-razor-page`
2. Do you still need **permissions** defined? → run workflow `abp-permissions`
