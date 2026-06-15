# ABP: Connection Strings

> 📖 Official docs:
> - Connection Strings: https://abp.io/docs/latest/framework/fundamentals/connection-strings
> - Multi-Tenancy: https://abp.io/docs/latest/framework/architecture/multi-tenancy
> - EF Core Migrations: https://abp.io/docs/latest/framework/data/entity-framework-core/migrations
>
> Fetch these pages for the latest API details before generating connection string or multi-database code.

## Basic Configuration

Connection strings live in `appsettings.json` under the standard `ConnectionStrings` section.

```json
{
  "ConnectionStrings": {
    "Default": "Server=localhost;Database=BookStore;...",
    "AbpIdentity": "Server=localhost;Database=BookStore_Identity;..."
  }
}
```

ABP resolves the correct string automatically via `IConnectionStringResolver`.

---

## `[ConnectionStringName]` Attribute

Associate a `DbContext` with a named connection string. Apply to both the **interface** and the **class**.

```csharp
// EntityFrameworkCore/BookStoreDbContext.cs
[ConnectionStringName("Default")]
public class BookStoreDbContext : AbpDbContext<BookStoreDbContext>, IBookStoreDbContext
{
    // ...
}

// EntityFrameworkCore/IBookStoreDbContext.cs
[ConnectionStringName("Default")]
public interface IBookStoreDbContext : IEfCoreDbContext
{
    // ...
}
```

If the attribute is omitted, the framework falls back to `"Default"`.

---

## Mapping Multiple Modules to a Single Database

Use `AbpDbConnectionOptions.Databases` to group modules into one physical DB while keeping their logical separation:

```csharp
Configure<AbpDbConnectionOptions>(options =>
{
    options.Databases.Configure("BookStore", database =>
    {
        database.MappedConnections.Add("Default");
        database.MappedConnections.Add("AbpIdentity");
        database.MappedConnections.Add("AbpPermissionManagement");
    });
});
```

Resolution order:
1. Module-specific connection string (e.g. `"AbpIdentity"`)
2. Database group mapping
3. Fallback to `"Default"`

---

## Custom `IConnectionStringResolver`

Override resolution logic for dynamic or environment-driven setups:

```csharp
[Dependency(ReplaceServices = true)]
public class MyConnectionStringResolver : DefaultConnectionStringResolver
{
    public override async Task<string> ResolveAsync(string connectionStringName = null)
    {
        // Custom logic — e.g. read from a secrets vault
        return await base.ResolveAsync(connectionStringName);
    }
}
```

---

## Per-Tenant Connection Strings

Each tenant can have its own database. In the Tenant Management UI or via `ITenantStore`, set the tenant's `ConnectionStrings:Default`. ABP resolves it automatically in every request scoped to that tenant.

```json
{
  "Tenants": [
    {
      "Id": "446a5211-3d6f-4d2f-9b26-fd5a4f2b4e00",
      "Name": "acme",
      "ConnectionStrings": {
        "Default": "Server=acme-db;Database=BookStore_Acme;..."
      }
    }
  ]
}
```

For programmatic assignment use `ITenantStore` or the Tenant Management Module's admin API.

---

## Key Rules

- **DO** apply `[ConnectionStringName]` to both the interface and implementation of every `DbContext`
- **DO** use `"Default"` as the fallback connection string name
- **DO** use `Databases.Configure()` to avoid duplicate connection string entries when several modules share one database
- **DO NOT** hard-code connection strings — always read from `IConfiguration` or `IConnectionStringResolver`
- **DO NOT** resolve connection strings inside entity constructors or domain services
