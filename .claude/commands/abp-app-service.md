You are an expert ABP Framework developer. Scaffold the **ABP application service layer** for the entity named: $ARGUMENTS

If no entity name was provided, ask for it before proceeding.

Read `abp-dev/references/ddd-application.md` and `abp-dev/references/authorization.md` before generating any code.

Assumes the domain layer (entity, `I<Entity>Repository`, `<Entity>Manager`) already exists.

## What to generate

### 1. `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity>Dto.cs`

- Extend `AuditedEntityDto<Guid>` (or `FullAuditedEntityDto<Guid>` to match entity audit level)
- Mirror all public entity properties

### 2. `src/Acme.BookStore.Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

- Plain class; `[Required]` and `[StringLength(<Entity>Consts.MaxNameLength)]` on string props

### 3. `src/Acme.BookStore.Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

- Extend `PagedAndSortedResultRequestDto`; add `public string? FilterText { get; set; }`

### 4. `src/Acme.BookStore.Application.Contracts/<Entity>s/I<Entity>AppService.cs`

- Extend `IApplicationService`
- Methods: `GetListAsync(Get<Entity>sInput)`, `GetAsync(Guid)`, `CreateAsync(CreateUpdate<Entity>Dto)`, `UpdateAsync(Guid, CreateUpdate<Entity>Dto)`, `DeleteAsync(Guid)`

### 5. `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`

- Extend `ApplicationService`, implement `I<Entity>AppService`
- Constructor-inject `I<Entity>Repository` and `<Entity>Manager`
- `[Authorize(BookStorePermissions.<Entity>s.Default)]` on the class
- `[Authorize(BookStorePermissions.<Entity>s.Create/Edit/Delete)]` on write methods
- Use `ObjectMapper.Map<>()` for entity↔DTO conversion

### 6. AutoMapper profile entries

Show the two `CreateMap` lines to add to `BookStoreApplicationAutoMapperProfile`:
```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

## After generating

Ask the user if they want the **Razor Pages UI** scaffolded → run `/project:abp-razor-page <Entity>`.
