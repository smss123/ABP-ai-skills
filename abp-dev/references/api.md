# ABP: Auto API Controllers & HTTP API Layer

> 📖 Official docs:
> - Auto API Controllers: https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers
> - API Versioning: https://docs.abp.io/en/abp/latest/API/API-Versioning
> - Dynamic C# API Clients: https://docs.abp.io/en/abp/latest/API/Dynamic-CSharp-API-Clients
> - Swagger Integration: https://docs.abp.io/en/abp/latest/API/Swagger-Integration
>
> Fetch these pages for the latest API details before generating HTTP API or controller code.

## Auto API Controllers

ABP automatically exposes Application Services as HTTP API endpoints — no manual controller needed.

### Enable in Web/HttpApi module

```csharp
[DependsOn(typeof(BookStoreApplicationModule))]
public class BookStoreWebModule : AbpModule
{
    public override void PreConfigureServices(ServiceConfigurationContext context)
    {
        PreConfigure<AbpAspNetCoreMvcOptions>(options =>
        {
            options.ConventionalControllers
                   .Create(typeof(BookStoreApplicationModule).Assembly);
        });
    }
}
```

### URL & HTTP method convention

ABP maps methods by name automatically:

| Method name pattern | HTTP Method | Example URL |
|---|---|---|
| `GetAsync` / `GetListAsync` | GET | `GET /api/app/book` |
| `CreateAsync` | POST | `POST /api/app/book` |
| `UpdateAsync` | PUT | `PUT /api/app/book/{id}` |
| `DeleteAsync` | DELETE | `DELETE /api/app/book/{id}` |
| `GetAsync(id)` | GET | `GET /api/app/book/{id}` |

The route prefix is `/api/app/` by default. Service name is derived from the interface name
(e.g. `IBookAppService` → `/book`).

### Disable Auto API for a specific service

```csharp
[RemoteService(IsEnabled = false)]
public class InternalBookService : ApplicationService { }

// Hide from Swagger but still expose as API
[RemoteService(IsMetadataEnabled = false)]
public class AdminBookService : ApplicationService { }
```

---

## Manual HTTP API Controller (when needed)

Place in `*.HttpApi` project. Used for custom routes or non-app-service endpoints.

```csharp
using Acme.BookStore.Books;
using Microsoft.AspNetCore.Mvc;
using Volo.Abp.AspNetCore.Mvc;

namespace Acme.BookStore.Controllers;

[Route("api/book-store/books")]
public class BookController : AbpControllerBase
{
    private readonly IBookAppService _bookAppService;

    public BookController(IBookAppService bookAppService)
    {
        _bookAppService = bookAppService;
    }

    [HttpGet]
    public Task<PagedResultDto<BookDto>> GetListAsync(GetBooksInput input)
        => _bookAppService.GetListAsync(input);

    [HttpPost]
    public Task<BookDto> CreateAsync([FromBody] CreateUpdateBookDto input)
        => _bookAppService.CreateAsync(input);
}
```

---

## API Versioning

```csharp
// Mark a service with a version
[ApiVersion("2.0")]
public class BookV2AppService : ApplicationService, IBookV2AppService
{
    // ...
}

// Configure in module
PreConfigure<AbpAspNetCoreMvcOptions>(options =>
{
    options.ConventionalControllers.Create(
        typeof(BookStoreApplicationModule).Assembly,
        opts =>
        {
            opts.RootPath = "book-store";    // → /api/book-store/...
            opts.ApiVersions.Add(new ApiVersion(1, 0));
        }
    );
});
```

---

## Dynamic C# API Client (calling the API from another service)

ABP can generate client proxies automatically:

```csharp
// In the consuming module
context.Services.AddHttpClientProxies(
    typeof(BookStoreApplicationContractsModule).Assembly,
    remoteServiceConfigurationName: "BookStore"
);
```

Configure the remote URL in `appsettings.json`:
```json
{
  "RemoteServices": {
    "BookStore": {
      "BaseUrl": "https://api.mybookstore.com/"
    }
  }
}
```

Then inject `IBookAppService` normally — ABP routes calls over HTTP transparently.

---

## Swagger / OpenAPI

ABP adds Swagger by default in the startup template:

```csharp
// In ConfigureServices
context.Services.AddAbpSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "BookStore API", Version = "v1" });
    options.DocInclusionPredicate((_, _) => true);
    options.CustomSchemaIds(type => type.FullName);
});

// In OnApplicationInitialization
app.UseAbpSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "BookStore API");
});
```
