# ABP Feature Scaffold

You are an expert ABP Framework developer. Given an **existing entity**, scaffold the complete application layer with all best practices: error codes, localization, FluentValidation, permissions, app service (with proper exception handling), and optional Razor Pages UI.

Entity / scenario: $ARGUMENTS

If no entity name or entity file path was provided, ask before proceeding.

---

## Before generating any code

1. Read `abp-dev/references/ddd-application.md` — DTO patterns, app service conventions.
2. Read `abp-dev/references/authorization.md` — `[Authorize]`, permission definition.
3. Read `abp-dev/references/validation.md` — data annotations, FluentValidation, `IValidatableObject`.
4. Read `abp-dev/references/exception-handling.md` — `BusinessException`, error codes, `EntityNotFoundException`.
5. Read `abp-dev/references/localization.md` — `en.json` structure, `L[]` helper.
6. Fetch <https://docs.abp.io/en/abp/latest/Application-Services> for the latest API.

Assumes the domain layer (`<Entity>` class, `I<Entity>Repository`, `<Entity>Manager`) already exists.
Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## Step 1 — Read the existing entity

Read the entity file. Extract:
- All public properties and their types
- The audit base class (`AuditedAggregateRoot`, `FullAuditedAggregateRoot`, or `Entity<Guid>`)
- `<Entity>Consts` — `MaxXxxLength` constants (must match DTO `[StringLength]` values)
- Business methods (`SetName`, `SetPrice`, etc.) — use these in the app service, not direct property assignment

---

## Step 2 — Error codes

Add to `src/Acme.BookStore.Domain.Shared/BookStoreDomainErrorCodes.cs`:

```csharp
namespace Acme.BookStore;

public static class BookStoreDomainErrorCodes
{
    public const string <Entity>NameAlreadyExists = "BookStore:0001";
    public const string <Entity>NotFound          = "BookStore:0002";
}
```

Convention: `<Module>:<4-digit-number>`. Reserve a numeric block per entity.

---

## Step 3 — Localization strings

Add to `Domain.Shared/Localization/BookStore/en.json` inside `"texts"`:

```json
"Menu:<Entity>s":                         "<Entity>s",
"<Entity>s":                              "<Entity>s",
"New<Entity>":                            "New <Entity>",
"Edit<Entity>":                           "Edit <Entity>",
"<Entity>DeletionConfirmationMessage":    "Are you sure you want to delete '{0}'?",
"Permission:<Entity>s":                   "<Entity> Management",
"Permission:<Entity>s.Create":            "Creating new <entity>s",
"Permission:<Entity>s.Edit":              "Editing <entity>s",
"Permission:<Entity>s.Delete":            "Deleting <entity>s",
"BookStore:0001":                         "A <entity> with name '{name}' already exists.",
"BookStore:0002":                         "<Entity> with id '{id}' was not found."
```

> Never hardcode English strings in views or services — always use `L["Key"]`.

---

## Step 4 — Permissions

### `Application.Contracts/Permissions/BookStorePermissions.cs`

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

### `Application.Contracts/Permissions/BookStorePermissionDefinitionProvider.cs`

```csharp
using Acme.BookStore.Localization;
using Volo.Abp.Authorization.Permissions;
using Volo.Abp.Localization;

namespace Acme.BookStore.Permissions;

public class BookStorePermissionDefinitionProvider : PermissionDefinitionProvider
{
    public override void Define(IPermissionDefinitionContext context)
    {
        var group = context.AddGroup(
            BookStorePermissions.GroupName,
            L("Permission:BookStore"));

        var <entity>s = group.AddPermission(
            BookStorePermissions.<Entity>s.Default,
            L("Permission:<Entity>s"));

        <entity>s.AddChild(BookStorePermissions.<Entity>s.Create, L("Permission:<Entity>s.Create"));
        <entity>s.AddChild(BookStorePermissions.<Entity>s.Edit,   L("Permission:<Entity>s.Edit"));
        <entity>s.AddChild(BookStorePermissions.<Entity>s.Delete, L("Permission:<Entity>s.Delete"));
    }

    private static LocalizableString L(string name)
        => LocalizableString.Create<BookStoreResource>(name);
}
```

---

## Step 5 — DTOs

### `Application.Contracts/<Entity>s/<Entity>Dto.cs`

```csharp
using System;
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

// Match base class to entity: AuditedEntityDto<Guid> or FullAuditedEntityDto<Guid>
public class <Entity>Dto : AuditedEntityDto<Guid>
{
    public string Name { get; set; } = string.Empty;
    // Mirror all public entity properties
}
```

### `Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

```csharp
using System.ComponentModel.DataAnnotations;

namespace Acme.BookStore.<Entity>s;

public class CreateUpdate<Entity>Dto
{
    [Required]
    [StringLength(<Entity>Consts.MaxNameLength, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    // [Range(0.01, 9999.99)] for decimals
    // [EmailAddress] / [Url] for format checks
    // Always use <Entity>Consts.MaxXxxLength — never magic numbers
}
```

### `Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

```csharp
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

public class Get<Entity>sInput : PagedAndSortedResultRequestDto
{
    public string? FilterText { get; set; }
}
```

---

## Step 6 — FluentValidation validator *(skip if only simple annotations needed)*

### `Application/<Entity>s/CreateUpdate<Entity>DtoValidator.cs`

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

        // Async uniqueness check
        RuleFor(x => x.Name)
            .MustAsync(async (name, ct) =>
                await <entity>Repository.FindByNameAsync(name) == null)
            .WithMessage("A <entity> with this name already exists.");
    }
}
```

Add to the Application module if not already present:

```csharp
[DependsOn(typeof(AbpFluentValidationModule))]
public class BookStoreApplicationModule : AbpModule { }
```

---

## Step 7 — Application service interface

### `Application.Contracts/<Entity>s/I<Entity>AppService.cs`

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

## Step 8 — Application service implementation

### `Application/<Entity>s/<Entity>AppService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Acme.BookStore.Permissions;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;

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
        // IRepository.GetAsync throws EntityNotFoundException automatically → HTTP 404
        var entity = await _<entity>Repository.GetAsync(id);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Create)]
    public async Task<<Entity>Dto> CreateAsync(CreateUpdate<Entity>Dto input)
    {
        // Manager throws BusinessException(BookStoreDomainErrorCodes.<Entity>NameAlreadyExists) on duplicate
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

---

## Step 9 — AutoMapper profile

Add to `BookStoreApplicationAutoMapperProfile`:

```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

---

## After generating

Ask the user:

1. Do you want **Razor Pages UI** scaffolded? → run `/project:abp-razor-page`
2. Do you want **data seeding** for this entity? → run `/project:abp-data-seed`
3. Remind: add all new `en.json` keys to `ar.json` and any other culture files.
4. Remind: run `dotnet build` and verify AutoMapper profiles compile.
