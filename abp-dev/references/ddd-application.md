# ABP: DDD Application Layer

> 📖 Official docs:
> - Application Services: https://docs.abp.io/en/abp/latest/Application-Services
> - Data Transfer Objects: https://docs.abp.io/en/abp/latest/Data-Transfer-Objects
> - Object-to-Object Mapping (AutoMapper): https://docs.abp.io/en/abp/latest/Object-To-Object-Mapping
>
> Fetch these pages for the latest API details before generating application-layer code.

## Application Service Interface

Defined in `Application.Contracts` project. Inherit from `IApplicationService`.

```csharp
// Application.Contracts/Books/IBookAppService.cs
using System;
using System.Threading.Tasks;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;

namespace Acme.BookStore.Books;

public interface IBookAppService : IApplicationService
{
    Task<PagedResultDto<BookDto>> GetListAsync(GetBooksInput input);
    Task<BookDto> GetAsync(Guid id);
    Task<BookDto> CreateAsync(CreateUpdateBookDto input);
    Task<BookDto> UpdateAsync(Guid id, CreateUpdateBookDto input);
    Task DeleteAsync(Guid id);
}
```

---

## DTOs

Defined in `Application.Contracts`. Never expose entities directly.

```csharp
// Application.Contracts/Books/BookDto.cs
using System;
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.Books;

public class BookDto : AuditedEntityDto<Guid>  // includes CreationTime, LastModificationTime
{
    public string Name { get; set; } = string.Empty;
    public BookType Type { get; set; }
    public decimal? Price { get; set; }
    public DateTime PublishDate { get; set; }
}

// Application.Contracts/Books/CreateUpdateBookDto.cs
using System;
using System.ComponentModel.DataAnnotations;

namespace Acme.BookStore.Books;

public class CreateUpdateBookDto
{
    [Required]
    [StringLength(BookConsts.MaxNameLength)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public BookType Type { get; set; }

    public decimal? Price { get; set; }

    [Required]
    public DateTime PublishDate { get; set; }
}

// Application.Contracts/Books/GetBooksInput.cs
using Volo.Abp.Application.Dtos;

namespace Acme.BookStore.Books;

public class GetBooksInput : PagedAndSortedResultRequestDto
{
    public string? FilterText { get; set; }
    public BookType? Type { get; set; }
}
```

**DTO base classes:**
| Class | Properties included |
|---|---|
| `EntityDto<TKey>` | `Id` |
| `AuditedEntityDto<TKey>` | `Id` + `CreationTime` + `LastModificationTime` |
| `FullAuditedEntityDto<TKey>` | All audit properties |
| `PagedResultDto<T>` | `TotalCount` + `Items` |
| `PagedAndSortedResultRequestDto` | `MaxResultCount`, `SkipCount`, `Sorting` |

---

## Application Service Implementation

Lives in `Application` project. Inherit from `ApplicationService` (or a CRUD base).

### Manual implementation

```csharp
// Application/Books/BookAppService.cs
using System;
using System.Threading.Tasks;
using Acme.BookStore.Permissions;
using Microsoft.AspNetCore.Authorization;
using Volo.Abp.Application.Dtos;
using Volo.Abp.Application.Services;

namespace Acme.BookStore.Books;

[Authorize(BookStorePermissions.Books.Default)]
public class BookAppService : ApplicationService, IBookAppService
{
    private readonly IBookRepository _bookRepository;
    private readonly BookManager _bookManager;

    public BookAppService(IBookRepository bookRepository, BookManager bookManager)
    {
        _bookRepository = bookRepository;
        _bookManager = bookManager;
    }

    public async Task<PagedResultDto<BookDto>> GetListAsync(GetBooksInput input)
    {
        var totalCount = await _bookRepository.GetCountAsync();
        var books = await _bookRepository.GetListAsync(
            input.FilterText, input.Type,
            input.MaxResultCount, input.SkipCount, input.Sorting
        );
        return new PagedResultDto<BookDto>(totalCount, ObjectMapper.Map<List<Book>, List<BookDto>>(books));
    }

    public async Task<BookDto> GetAsync(Guid id)
    {
        var book = await _bookRepository.GetAsync(id);
        return ObjectMapper.Map<Book, BookDto>(book);
    }

    [Authorize(BookStorePermissions.Books.Create)]
    public async Task<BookDto> CreateAsync(CreateUpdateBookDto input)
    {
        var book = await _bookManager.CreateAsync(input.Name, input.Type, input.Price, input.PublishDate);
        await _bookRepository.InsertAsync(book);
        return ObjectMapper.Map<Book, BookDto>(book);
    }

    [Authorize(BookStorePermissions.Books.Edit)]
    public async Task<BookDto> UpdateAsync(Guid id, CreateUpdateBookDto input)
    {
        var book = await _bookRepository.GetAsync(id);
        book.SetName(input.Name);
        book.Type = input.Type;
        book.Price = input.Price;
        book.PublishDate = input.PublishDate;
        await _bookRepository.UpdateAsync(book);
        return ObjectMapper.Map<Book, BookDto>(book);
    }

    [Authorize(BookStorePermissions.Books.Delete)]
    public async Task DeleteAsync(Guid id)
    {
        await _bookRepository.DeleteAsync(id);
    }
}
```

### Object mapping (AutoMapper — default)

ABP uses **AutoMapper** by default (included in the startup template). Mapperly is also supported as an alternative but requires manual setup. Define AutoMapper profiles in the Application project:

```csharp
// Application/BookStoreApplicationAutoMapperProfile.cs
using AutoMapper;

namespace Acme.BookStore;

public class BookStoreApplicationAutoMapperProfile : Profile
{
    public BookStoreApplicationAutoMapperProfile()
    {
        CreateMap<Book, BookDto>();
        CreateMap<CreateUpdateBookDto, Book>();
    }
}
```

---

## CRUD App Service Base (shortcut for simple CRUD)

ABP provides `CrudAppService<TEntity, TEntityDto, TKey, TGetListInput, TCreateInput, TUpdateInput>`:

```csharp
public class BookAppService
    : CrudAppService<Book, BookDto, Guid, PagedAndSortedResultRequestDto, CreateUpdateBookDto>
    , IBookAppService
{
    public BookAppService(IRepository<Book, Guid> repository)
        : base(repository) { }

    protected override string GetPolicyName       => BookStorePermissions.Books.Default;
    protected override string GetListPolicyName   => BookStorePermissions.Books.Default;
    protected override string CreatePolicyName    => BookStorePermissions.Books.Create;
    protected override string UpdatePolicyName    => BookStorePermissions.Books.Edit;
    protected override string DeletePolicyName    => BookStorePermissions.Books.Delete;
}
```

This auto-implements `GetAsync`, `GetListAsync`, `CreateAsync`, `UpdateAsync`, `DeleteAsync`.

---

## Localization & Error Handling

```csharp
// Throw user-visible business rule errors
throw new UserFriendlyException("That action is not allowed.");

// Use localized exceptions (preferred for modules)
throw new BusinessException(BookStoreDomainErrorCodes.BookNameAlreadyExists)
    .WithData("name", name);
```
