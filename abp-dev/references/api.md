# ABP: Auto API Controllers & HTTP API Layer

> 📖 Official docs:
> - Auto API Controllers: https://docs.abp.io/en/abp/latest/API/Auto-API-Controllers
> - API Versioning: https://abp.io/docs/latest/framework/api-development/versioning
> - Integration Services: https://abp.io/docs/latest/framework/api-development/integration-services
> - Static C# Client Proxies: https://abp.io/docs/latest/framework/api-development/static-csharp-clients
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

### Enable versioning

```csharp
// In module ConfigureServices
context.Services.AddAbpApiVersioning(options =>
{
    options.ReportApiVersions = true;
    options.AssumeDefaultVersionWhenUnspecified = true;
});
```

### Versioning strategies

| Strategy | Supported | Notes |
|---|---|---|
| **Query string** (`?api-version=2.0`) | Yes — recommended | Compatible with static C#/JS proxies |
| **URL path** (`/v2/books`) | **No** | Incompatible with ABP's auto-generated proxies |
| **Header-based** | Yes | Via `ICurrentApiVersionInfo` |

> **Never use URL path versioning in ABP** — it breaks the auto-generated C# and JavaScript client proxies.

### Versioned controllers

Define a separate controller class per version, each implementing the appropriate interface:

```csharp
[ApiVersion("1.0", Deprecated = true)]
[ControllerName("Book")]           // keeps both controllers on the same route
public class BookController : AbpControllerBase, IBookAppService { ... }

[ApiVersion("2.0")]
[ControllerName("Book")]
public class BookV2Controller : AbpControllerBase, IBookV2AppService { ... }
```

Both map to `/api/book-store/book`; callers pass `?api-version=1.0` or `?api-version=2.0`.

### Versioned Auto API Controllers

Filter by namespace to register different assemblies as different versions:

```csharp
PreConfigure<AbpAspNetCoreMvcOptions>(options =>
{
    // v1
    options.ConventionalControllers.Create(
        typeof(BookStoreApplicationModule).Assembly,
        opts =>
        {
            opts.RootPath = "book-store";
            opts.ApiVersions.Add(new ApiVersion(1, 0));
            opts.TypePredicate = t =>
                t.Namespace == typeof(v1.BookAppService).Namespace;
        }
    );

    // v2
    options.ConventionalControllers.Create(
        typeof(BookStoreApplicationModule).Assembly,
        opts =>
        {
            opts.RootPath = "book-store";
            opts.ApiVersions.Add(new ApiVersion(2, 0));
            opts.TypePredicate = t =>
                t.Namespace == typeof(v2.BookAppService).Namespace;
        }
    );
});
```

### Switching version in C# proxy calls

```csharp
private readonly ICurrentApiVersionInfo _currentApiVersionInfo;
private readonly IBookAppService _bookAppService;  // dynamic proxy

public async Task CallV2Async()
{
    using (_currentApiVersionInfo.Change(new ApiVersion(2, 0)))
    {
        var result = await _bookAppService.GetListAsync(new GetBooksInput());
    }
}
```

### Swagger integration

```csharp
context.Services.AddAbpSwaggerGen(options =>
{
    var provider = context.Services.BuildServiceProvider()
        .GetRequiredService<IApiVersionDescriptionProvider>();

    foreach (var description in provider.ApiVersionDescriptions)
    {
        options.SwaggerDoc(
            description.GroupName,
            new OpenApiInfo
            {
                Title = $"BookStore API {description.ApiVersion}",
                Version = description.ApiVersion.ToString()
            });
    }
});
```

Configure `AddApiExplorer()` with `GroupNameFormat = "'v'VVV"` to get separate Swagger endpoints per version.

---

## Static C# API Client Proxies

Static proxies are **generated at development time** using the ABP CLI. They produce concrete client classes that handle auth tokens, serialization, error handling, API versioning, correlation IDs, and tenant IDs automatically.

### Static vs. dynamic proxies

| | Static | Dynamic |
|---|---|---|
| **Generation** | CLI command at dev time | Runtime (no code generated) |
| **Performance** | Better — no runtime overhead | Slightly slower |
| **After API change** | Must regenerate | Automatic |
| **Use when** | Performance matters; microservices | Rapid development, monolith |

### Generate proxies

```bash
# Full generation (includes DTOs + interfaces from contracts)
abp generate-proxy -t csharp -u http://localhost:53929/

# Without contracts (independent microservices that share no contracts assembly)
abp generate-proxy -t csharp -u http://localhost:53929/ --without-contracts

# For a specific module only
abp generate-proxy -t csharp -u http://localhost:53929/ -m ModuleName
```

The command produces `[Service]ClientProxy.Generated.cs`, the interface, DTOs, enums, and an `app-generate-proxy.json` metadata file embedded in the VFS.

### Register in the consuming module

```csharp
[DependsOn(typeof(AbpHttpClientModule), typeof(AbpVirtualFileSystemModule))]
public class MyClientModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        context.Services.AddStaticHttpClientProxies(
            typeof(MyClientModule).Assembly,
            remoteServiceConfigurationName: "BookStore"
        );

        Configure<AbpVirtualFileSystemOptions>(options =>
        {
            options.FileSets.AddEmbedded<MyClientModule>();
        });
    }
}
```

### Remote service URL (`appsettings.json`)

```json
{
  "RemoteServices": {
    "Default":    { "BaseUrl": "http://localhost:53929/" },
    "BookStore":  { "BaseUrl": "http://localhost:48392/" }
  }
}
```

### Usage — identical to injecting a local service

```csharp
public class MyService : ITransientDependency
{
    private readonly IBookAppService _bookService;

    public MyService(IBookAppService bookService)
    {
        _bookService = bookService;
    }

    public async Task DoItAsync()
        => await _bookService.GetListAsync(new GetBooksInput());
}
```

### Retry policy with Polly

```csharp
// In PreConfigureServices
PreConfigure<AbpHttpClientBuilderOptions>(options =>
{
    options.ProxyClientBuildActions.Add((_, builder) =>
    {
        builder.AddTransientHttpErrorPolicy(policy =>
            policy.WaitAndRetryAsync(3, i => TimeSpan.FromSeconds(Math.Pow(2, i)))
        );
    });
});
```

Requires `Microsoft.Extensions.Http.Polly`.

> **Requirement:** The service interface must implement `IRemoteService` (or `IApplicationService`, which inherits it) for the proxy generator to discover it.

---

## Dynamic C# API Client (calling the API from another service)

ABP can generate client proxies automatically at runtime — no CLI step needed:

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

## Integration Services

Integration Services are application services intended for **inter-module or inter-microservice communication**, not for UI or external clients.

### Mark a service as an integration service

```csharp
// Preferred: mark the interface
[IntegrationService]
public interface IProductIntegrationService : IApplicationService
{
    Task<ProductDto> GetAsync(Guid id);
}

// Or mark the implementation
[IntegrationService]
public class ProductIntegrationAppService : ApplicationService, IProductIntegrationService
{
    // ...
}
```

### Default behavior vs. regular application services

| Aspect | Application Service | Integration Service |
|---|---|---|
| URL prefix | `/api` | `/integration-api` |
| Exposed by default | Yes | **No** |
| Audit logging | Enabled | Disabled |
| Authorization | Required | Typically not required |

### Expose integration services (opt-in)

```csharp
Configure<AbpAspNetCoreMvcOptions>(options =>
{
    options.ExposeIntegrationServices = true;
});
```

> **Security**: Keep `/integration-api` routes blocked at the API gateway — they are for private network communication only (e.g., within a Kubernetes cluster), never for external clients.

### Register only integration services as Auto API Controllers

```csharp
PreConfigure<AbpAspNetCoreMvcOptions>(options =>
{
    options.ConventionalControllers.Create(
        typeof(MyApplicationModule).Assembly,
        setting =>
        {
            setting.ApplicationServiceTypes =
                ApplicationServiceTypes.IntegrationServices;
        }
    );
});
```

### Enable audit logging for integration services

```csharp
Configure<AbpAuditingOptions>(options =>
{
    options.IsEnabledForIntegrationService = true;
});
```

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
