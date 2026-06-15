---
name: abp-feature-scaffold
description: Scaffold a complete ABP feature layer for an existing entity — error codes, localization, validation, permissions, app service, and optional Razor Pages UI
---

# ABP Feature Scaffold (Application Layer for Existing Entity)

A Windsurf Cascade workflow that wires up all application-layer best practices for an entity that already exists in the domain. Does **not** create a new entity — run `abp-entity` first if the entity does not exist yet.

## Inputs

Before starting, ask the user:

1. **Entity name** (PascalCase, singular — e.g. `Product`)
2. **Entity file path** — so Cascade can read the real properties and base class
3. **Project prefix** (e.g. `Acme.BookStore` → used for namespaces, permission names, error code prefix)
4. **Audit level** — `FullAudit` / `Audit` / `None` (affects DTO base class)
5. **FluentValidation needed?** — Yes for complex/async rules; No for simple data annotations only
6. **Include Razor Pages UI?** — Yes / No
7. **Permissions already defined?** — Yes / No (if No, this workflow creates them)

---

## Step 1 — Read reference files

Read **all** of the following before generating any code:

- `abp-dev/references/ddd-application.md`
- `abp-dev/references/authorization.md`
- `abp-dev/references/validation.md`
- `abp-dev/references/exception-handling.md`
- `abp-dev/references/localization.md`
- `abp-dev/references/ui-razorpages.md` *(if Razor Pages UI was requested)*

---

## Step 2 — Analyse the existing entity

Read the entity file the user provided. Extract:

- All **public properties** and their types
- The **audit base class** (`AuditedAggregateRoot`, `FullAuditedAggregateRoot`, or `Entity`)
- The companion **`<Entity>Consts`** class and its `MaxXxxLength` constants
- Any **business methods** (`SetName`, `SetPrice`, etc.) to call in the app service

Present a confirmation table:

| # | Item | Extracted value |
| --- | --- | --- |
| 1 | Entity name | `<Entity>` |
| 2 | Properties | name : type : required/optional |
| 3 | Audit base class | `FullAuditedAggregateRoot` / … |
| 4 | Consts found | `MaxNameLength = N`, … |
| 5 | Business methods | `SetName`, `SetPrice`, … |

Ask: **"Does this look correct? Shall I proceed?"**

---

## Step 3 — Error codes (`Domain.Shared`)

Add typed error codes to `src/Acme.BookStore.Domain.Shared/<ProjectName>DomainErrorCodes.cs`:

```csharp
namespace Acme.BookStore;

public static class BookStoreDomainErrorCodes
{
    // <Entity> errors — range <Module>:00XX
    public const string <Entity>NameAlreadyExists = "BookStore:0001";
    public const string <Entity>NotFound          = "BookStore:0002";
    // Add more specific codes as needed
}
```

> Convention: `<Module>:<4-digit-number>`. Reserve a block per entity to keep codes groupable.

---

## Step 4 — Localization strings (`Domain.Shared`)

Add the following keys to `src/Acme.BookStore.Domain.Shared/Localization/BookStore/en.json`
inside the `"texts"` object:

```json
"Menu:<Entity>s":                          "<Entity>s",
"<Entity>s":                               "<Entity>s",
"New<Entity>":                             "New <Entity>",
"Edit<Entity>":                            "Edit <Entity>",
"<Entity>DeletionConfirmationMessage":     "Are you sure you want to delete the <entity> '{0}'?",
"Permission:<Entity>s":                    "<Entity> Management",
"Permission:<Entity>s.Create":             "Creating new <entity>s",
"Permission:<Entity>s.Edit":               "Editing <entity>s",
"Permission:<Entity>s.Delete":             "Deleting <entity>s",
"BookStore:0001":                          "A <entity> with name '{name}' already exists.",
"BookStore:0002":                          "<Entity> with id '{id}' was not found."
```

> All user-visible strings must go through `L[]` — no hardcoded English in views or services.

---

## Step 5 — Permissions (`Application.Contracts`)

### `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissions.cs`

```csharp
namespace Acme.BookStore.Permissions;

public static class BookStorePermissions
{
    public const string GroupName = "BookStore";

    public static class <Entity>s
    {
        public const string Default = GroupName + ".<Entity>s";
        public const string Create  = Default + ".Create";
        public const string Edit    = Default + ".Edit";
        public const string Delete  = Default + ".Delete";
    }
}
```

### `src/Acme.BookStore.Application.Contracts/Permissions/BookStorePermissionDefinitionProvider.cs`

```csharp
using Acme.BookStore.Localization;
using Volo.Abp.Authorization.Permissions;
using Volo.Abp.Localization;

namespace Acme.BookStore.Permissions;

public class BookStorePermissionDefinitionProvider : PermissionDefinitionProvider
{
    public override void Define(IPermissionDefinitionContext context)
    {
        var bookStoreGroup = context.AddGroup(
            BookStorePermissions.GroupName,
            L("Permission:BookStore"));

        var <entity>sPermission = bookStoreGroup.AddPermission(
            BookStorePermissions.<Entity>s.Default,
            L("Permission:<Entity>s"));

        <entity>sPermission.AddChild(
            BookStorePermissions.<Entity>s.Create,
            L("Permission:<Entity>s.Create"));

        <entity>sPermission.AddChild(
            BookStorePermissions.<Entity>s.Edit,
            L("Permission:<Entity>s.Edit"));

        <entity>sPermission.AddChild(
            BookStorePermissions.<Entity>s.Delete,
            L("Permission:<Entity>s.Delete"));
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

---

## Step 6 — DTOs (`Application.Contracts`)

### `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity>Dto.cs`

```csharp
using System;
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

// Use AuditedEntityDto<Guid> or FullAuditedEntityDto<Guid> to match the entity base class
public class <Entity>Dto : AuditedEntityDto<Guid>
{
    public string Name { get; set; } = string.Empty;
    // Mirror all public entity properties
}
```

### `src/Acme.BookStore.Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

```csharp
using System.ComponentModel.DataAnnotations;

namespace Acme.BookStore.<Entity>s;

public class CreateUpdate<Entity>Dto
{
    [Required]
    [StringLength(<Entity>Consts.MaxNameLength, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    // Add [Range], [EmailAddress], [Url], etc. for other properties
    // Use <Entity>Consts.MaxXxxLength constants — never magic numbers
}
```

### `src/Acme.BookStore.Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

```csharp
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

public class Get<Entity>sInput : PagedAndSortedResultRequestDto
{
    public string? FilterText { get; set; }
    // Add more filter properties as needed (e.g. enum type filter)
}
```

---

## Step 7 — FluentValidation validator *(if requested)*

Create in `src/Acme.BookStore.Application/<Entity>s/`:

```csharp
using FluentValidation;

namespace Acme.BookStore.<Entity>s;

public class CreateUpdate<Entity>DtoValidator : AbstractValidator<CreateUpdate<Entity>Dto>
{
    public CreateUpdate<Entity>DtoValidator(I<Entity>Repository <entity>Repository)
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .Length(2, <Entity>Consts.MaxNameLength)
            .Matches(@"^[\w\s\-]+$").WithMessage("Name contains invalid characters.");

        // Async uniqueness check via repository
        RuleFor(x => x.Name)
            .MustAsync(async (name, ct) =>
                await <entity>Repository.FindByNameAsync(name) == null)
            .WithMessage("A <entity> with this name already exists.");
    }
}
```

> ABP auto-discovers `IValidator<T>` implementations — no explicit registration needed.
> Add `[DependsOn(typeof(AbpFluentValidationModule))]` to the Application module if not already present.

---

## Step 8 — Application service interface (`Application.Contracts`)

### `src/Acme.BookStore.Application.Contracts/<Entity>s/I<Entity>AppService.cs`

```csharp
using System;
using System.Threading.Tasks;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;

namespace Acme.BookStore.<Entity>s;

public interface I<Entity>AppService : IApplicationService
{
    Task<PagedResultDto<<Entity>Dto>> GetListAsync(Get<Entity>sInput input);
    Task<<Entity>Dto>                 GetAsync(Guid id);
    Task<<Entity>Dto>                 CreateAsync(CreateUpdate<Entity>Dto input);
    Task<<Entity>Dto>                 UpdateAsync(Guid id, CreateUpdate<Entity>Dto input);
    Task                              DeleteAsync(Guid id);
}
```

---

## Step 9 — Application service implementation (`Application`)

### `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Acme.BookStore.Permissions;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;
using Volo.Abp.Domain.Repositories;

namespace Acme.BookStore.<Entity>s;

[Authorize(BookStorePermissions.<Entity>s.Default)]
public class <Entity>AppService : ApplicationService, I<Entity>AppService
{
    private readonly I<Entity>Repository _<entity>Repository;
    private readonly <Entity>Manager     _<entity>Manager;

    public <Entity>AppService(
        I<Entity>Repository <entity>Repository,
        <Entity>Manager     <entity>Manager)
    {
        _<entity>Repository = <entity>Repository;
        _<entity>Manager    = <entity>Manager;
    }

    public async Task<PagedResultDto<<Entity>Dto>> GetListAsync(Get<Entity>sInput input)
    {
        var totalCount = await _<entity>Repository.GetCountAsync(input.FilterText);
        var items      = await _<entity>Repository.GetListAsync(
            input.FilterText,
            input.MaxResultCount,
            input.SkipCount,
            input.Sorting);

        return new PagedResultDto<<Entity>Dto>(
            totalCount,
            ObjectMapper.Map<List<<Entity>>, List<<Entity>Dto>>(items));
    }

    public async Task<<Entity>Dto> GetAsync(Guid id)
    {
        // GetAsync throws EntityNotFoundException automatically if not found → HTTP 404
        var entity = await _<entity>Repository.GetAsync(id);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Create)]
    public async Task<<Entity>Dto> CreateAsync(CreateUpdate<Entity>Dto input)
    {
        // Manager enforces uniqueness → throws BusinessException with error code if duplicate
        var entity = await _<entity>Manager.CreateAsync(input.Name /* other inputs */);
        await _<entity>Repository.InsertAsync(entity);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Edit)]
    public async Task<<Entity>Dto> UpdateAsync(Guid id, CreateUpdate<Entity>Dto input)
    {
        var entity = await _<entity>Repository.GetAsync(id);
        await _<entity>Manager.UpdateNameAsync(entity, input.Name); // use business methods
        await _<entity>Repository.UpdateAsync(entity);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Delete)]
    public async Task DeleteAsync(Guid id)
    {
        await _<entity>Repository.DeleteAsync(id);
    }
}
```

> Key patterns enforced:
> - `GetAsync` from `IRepository` throws `EntityNotFoundException` automatically → HTTP 404
> - `<Entity>Manager.CreateAsync` throws `BusinessException` with `BookStoreDomainErrorCodes.<Entity>NameAlreadyExists` on duplicate → do NOT re-check uniqueness in the app service
> - Never assign entity properties directly — always call business methods (`SetName`, etc.)
> - `ObjectMapper.Map<>()` for entity↔DTO — entities never leave the domain layer

---

## Step 10 — AutoMapper profile entries

Show the two `CreateMap` lines to add to `BookStoreApplicationAutoMapperProfile`:

```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

---

## Step 11 — Razor Pages UI *(if requested)*

Read `abp-dev/references/ui-razorpages.md` and scaffold:

- `src/Acme.BookStore.Web/Pages/<Entity>s/Index.cshtml` + `.cshtml.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/Index.js` (DataTables + AJAX)
- `src/Acme.BookStore.Web/Pages/<Entity>s/CreateModal.cshtml` + `.cshtml.cs`
- `src/Acme.BookStore.Web/Pages/<Entity>s/EditModal.cshtml` + `.cshtml.cs`
- Menu contributor snippet for `BookStoreMenuContributor`
- Web AutoMapper entry: `CreateMap<CreateUpdate<Entity>Dto, CreateUpdate<Entity>Dto>();`

---

## After completing all steps

Print a summary:

- Files generated (grouped by layer)
- Localization keys added to `en.json`
- Error codes added to `BookStoreDomainErrorCodes`
- Next steps:
  - [ ] Run `dotnet build` to verify no compilation errors
  - [ ] Verify AutoMapper profiles are complete
  - [ ] Test permissions in the UI (Settings → Permission Management)
  - [ ] Add translations to `ar.json` and other culture files for the new keys
