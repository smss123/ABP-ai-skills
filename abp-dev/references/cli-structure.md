# ABP: CLI & Startup Templates

## ABP CLI Installation

```bash
dotnet tool install -g Volo.Abp.Studio.Cli   # latest (ABP Studio CLI)
# OR legacy:
dotnet tool install -g Volo.Abp.Cli

# Update
dotnet tool update -g Volo.Abp.Studio.Cli
```

---

## Creating a New Project

```bash
# Layered monolith — Razor Pages + EF Core (most common)
abp new Acme.BookStore --template app --ui mvc --database-provider ef

# With company + app name
abp new Acme.BookStore -u mvc -d ef

# Modular monolith
abp new Acme.BookStore --template app-nolayers -u mvc -d ef

# Microservice template (ABP Commercial)
abp new Acme.BookStore --template microservice
```

**Flags:**
| Flag | Values | Default |
|---|---|---|
| `--template` / `-t` | `app`, `app-nolayers`, `module`, `console`, `microservice` | `app` |
| `--ui` / `-u` | `mvc`, `blazor`, `blazor-server`, `angular`, `none` | `mvc` |
| `--database-provider` / `-d` | `ef`, `mongodb` | `ef` |
| `--output-folder` / `-o` | path | current dir |
| `--theme` | `leptonx-lite`, `basic`, `leptonx` | `leptonx-lite` |

---

## Common ABP CLI Commands

```bash
# Add ABP package and configure module dependency
abp add-package Volo.Abp.Account.Web --project src/Acme.BookStore.Web

# Add a module (ABP Commercial)
abp add-module Volo.Saas

# Generate client proxies for Razor Pages
abp generate-proxy -t js -url https://localhost:44300

# Update all ABP packages to latest
abp update

# Login to ABP (required for commercial modules)
abp login <username>
```

---

## Startup Template: Layered Solution Structure

```
Acme.BookStore/
├── src/
│   ├── Acme.BookStore.Domain.Shared/
│   │   ├── BookStoreGlobalFeatureConfigurator.cs
│   │   ├── BookStoreModuleExtensionConfigurator.cs
│   │   ├── Localization/BookStore/en.json      ← localization strings
│   │   └── BookStoreDomainSharedModule.cs
│   │
│   ├── Acme.BookStore.Domain/
│   │   ├── Data/BookStoreDataSeedContributor.cs
│   │   └── BookStoreDomainModule.cs
│   │
│   ├── Acme.BookStore.Application.Contracts/
│   │   ├── Permissions/BookStorePermissions.cs
│   │   ├── Permissions/BookStorePermissionDefinitionProvider.cs
│   │   └── BookStoreApplicationContractsModule.cs
│   │
│   ├── Acme.BookStore.Application/
│   │   ├── BookStoreAppService.cs              ← base app service (optional)
│   │   ├── BookStoreApplicationAutoMapperProfile.cs
│   │   └── BookStoreApplicationModule.cs
│   │
│   ├── Acme.BookStore.EntityFrameworkCore/
│   │   ├── EntityFrameworkCore/
│   │   │   ├── BookStoreDbContext.cs
│   │   │   ├── BookStoreDbContextFactory.cs   ← for design-time migrations
│   │   │   ├── BookStoreDbContextModelCreatingExtensions.cs
│   │   │   └── BookStoreEntityFrameworkCoreModule.cs
│   │   └── Migrations/
│   │
│   ├── Acme.BookStore.DbMigrator/
│   │   ├── appsettings.json                   ← connection string for migrations
│   │   ├── DbMigratorHostedService.cs
│   │   └── BookStoreDbMigratorModule.cs
│   │
│   ├── Acme.BookStore.HttpApi/
│   │   ├── Controllers/                       ← manual controllers (optional)
│   │   └── BookStoreHttpApiModule.cs
│   │
│   ├── Acme.BookStore.HttpApi.Client/
│   │   └── BookStoreHttpApiClientModule.cs    ← dynamic C# client proxies
│   │
│   └── Acme.BookStore.Web/
│       ├── Pages/                             ← Razor Pages
│       │   └── BookStorePage.cs               ← base page model
│       ├── Menus/BookStoreMenuContributor.cs
│       ├── wwwroot/
│       ├── appsettings.json
│       ├── BookStoreWebModule.cs
│       └── Program.cs
│
└── test/
    ├── Acme.BookStore.Application.Tests/
    ├── Acme.BookStore.Domain.Tests/
    ├── Acme.BookStore.EntityFrameworkCore.Tests/
    └── Acme.BookStore.TestBase/
```

---

## Key Config Files

### appsettings.json (Web project)

```json
{
  "App": {
    "SelfUrl": "https://localhost:44300"
  },
  "ConnectionStrings": {
    "Default": "Server=localhost;Database=BookStore;Trusted_Connection=True"
  },
  "AuthServer": {
    "Authority": "https://localhost:44300"
  },
  "StringEncryption": {
    "DefaultPassPhrase": "change-this-in-production"
  }
}
```

### BookStorePage.cs (base page model for all pages)

```csharp
using Acme.BookStore.Localization;
using Volo.Abp.AspNetCore.Mvc.UI.RazorPages;

namespace Acme.BookStore.Web.Pages;

public abstract class BookStorePage : AbpPage
{
    protected BookStorePage()
    {
        LocalizationResourceType = typeof(BookStoreResource);
    }
}
```

Inherit all Razor Pages from this:
```csharp
@inherits Acme.BookStore.Web.Pages.BookStorePage
```

---

## Adding a New Feature (Checklist)

1. **Domain.Shared**: Add enums, constants (`BookConsts.MaxNameLength`)
2. **Domain**: Add entity, repository interface, domain service (if needed)
3. **Application.Contracts**: Add DTOs, app service interface, permissions
4. **Application**: Implement app service, add AutoMapper profile
5. **EntityFrameworkCore**: Add `DbSet`, configure in `OnModelCreating`, implement custom repo
6. **DbMigrator**: Run `Add-Migration` then `DbMigrator` app
7. **Web**: Add Razor Page folder, `Index.cshtml` + `Index.cshtml.cs`, `Index.js`, register menu
8. **Authorization**: Register page authorization in `WebModule.ConfigureServices`
