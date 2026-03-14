---
mode: 'agent'
description: 'Scaffold the ABP application service layer: DTOs, app service interface, implementation, and AutoMapper profile'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold the **application service layer** for the entity the user names — DTOs, service interface, implementation, and AutoMapper entries.

If no entity name was provided, ask for it before proceeding.

## Before generating any code

1. Read `abp-dev/references/ddd-application.md` — DTOs, service interface, implementation patterns.
2. Read `abp-dev/references/authorization.md` — `[Authorize]` and permission patterns.
3. Fetch https://docs.abp.io/en/abp/latest/Application-Services for the latest API details.

Assumes the domain layer (entity, `I<Entity>Repository`, `<Entity>Manager`) already exists.  
Replace every `<Entity>` placeholder with the PascalCase entity name and `<entity>` with camelCase.

---

## Files to create

### 1. `src/Acme.BookStore.Application.Contracts/<Entity>s/<Entity>Dto.cs`

```csharp
using System;
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

public class <Entity>Dto : AuditedEntityDto<Guid>
{
    public string Name { get; set; } = string.Empty;
    // Mirror all public entity properties here
}
```

Choose the correct DTO base: `EntityDto<Guid>`, `AuditedEntityDto<Guid>`, or `FullAuditedEntityDto<Guid>` to match the entity's audit base class.

### 2. `src/Acme.BookStore.Application.Contracts/<Entity>s/CreateUpdate<Entity>Dto.cs`

```csharp
using System.ComponentModel.DataAnnotations;

namespace Acme.BookStore.<Entity>s;

public class CreateUpdate<Entity>Dto
{
    [Required]
    [StringLength(<Entity>Consts.MaxNameLength)]
    public string Name { get; set; } = string.Empty;
    // Add other properties with appropriate validation attributes
}
```

### 3. `src/Acme.BookStore.Application.Contracts/<Entity>s/Get<Entity>sInput.cs`

```csharp
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.<Entity>s;

public class Get<Entity>sInput : PagedAndSortedResultRequestDto
{
    public string? FilterText { get; set; }
}
```

### 4. `src/Acme.BookStore.Application.Contracts/<Entity>s/I<Entity>AppService.cs`

```csharp
using System;
using System.Threading.Tasks;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;

namespace Acme.BookStore.<Entity>s;

public interface I<Entity>AppService : IApplicationService
{
    Task<PagedResultDto<<Entity>Dto>> GetListAsync(Get<Entity>sInput input);
    Task<<Entity>Dto> GetAsync(Guid id);
    Task<<Entity>Dto> CreateAsync(CreateUpdate<Entity>Dto input);
    Task<<Entity>Dto> UpdateAsync(Guid id, CreateUpdate<Entity>Dto input);
    Task DeleteAsync(Guid id);
}
```

### 5. `src/Acme.BookStore.Application/<Entity>s/<Entity>AppService.cs`

```csharp
using System;
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
    private readonly <Entity>Manager _<entity>Manager;

    public <Entity>AppService(
        I<Entity>Repository <entity>Repository,
        <Entity>Manager <entity>Manager)
    {
        _<entity>Repository = <entity>Repository;
        _<entity>Manager    = <entity>Manager;
    }

    public async Task<PagedResultDto<<Entity>Dto>> GetListAsync(Get<Entity>sInput input)
    {
        var totalCount = await _<entity>Repository.GetCountAsync();
        var items = await _<entity>Repository.GetListAsync(
            input.FilterText,
            input.MaxResultCount,
            input.SkipCount,
            input.Sorting
        );
        return new PagedResultDto<<Entity>Dto>(
            totalCount,
            ObjectMapper.Map<List<<Entity>>, List<<Entity>Dto>>(items)
        );
    }

    public async Task<<Entity>Dto> GetAsync(Guid id)
    {
        var entity = await _<entity>Repository.GetAsync(id);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Create)]
    public async Task<<Entity>Dto> CreateAsync(CreateUpdate<Entity>Dto input)
    {
        var entity = await _<entity>Manager.CreateAsync(input.Name /* other inputs */);
        await _<entity>Repository.InsertAsync(entity);
        return ObjectMapper.Map<<Entity>, <Entity>Dto>(entity);
    }

    [Authorize(BookStorePermissions.<Entity>s.Edit)]
    public async Task<<Entity>Dto> UpdateAsync(Guid id, CreateUpdate<Entity>Dto input)
    {
        var entity = await _<entity>Repository.GetAsync(id);
        entity.SetName(input.Name);  // Use business methods, not direct property assignment
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

### 6. AutoMapper profile entries

Show the two `CreateMap` lines to add to `BookStoreApplicationAutoMapperProfile`:
```csharp
CreateMap<<Entity>, <Entity>Dto>();
CreateMap<CreateUpdate<Entity>Dto, <Entity>>();
```

---

## After generating

Remind the user to:
1. Add permission constants for this entity → attach `#abp-permissions.prompt.md` if not yet done.
2. Optionally scaffold the Razor Pages UI → attach `#abp-razor-page.prompt.md`.
