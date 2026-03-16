# ABP: Multi-Tenancy

> 📖 Official docs:
> - Multi-Tenancy: https://docs.abp.io/en/abp/latest/Multi-Tenancy
> - Tenant Management: https://docs.abp.io/en/abp/latest/Modules/Tenant-Management
> - Connection Strings (per-tenant): https://docs.abp.io/en/abp/latest/Connection-Strings
>
> Fetch these pages for the latest API details before generating multi-tenancy code.

## Overview

ABP's multi-tenancy system lets a single application serve multiple tenants, each with isolated data.
Key concepts:

- **Host**: the management/admin side (no tenant; manages tenants)
- **Tenant**: a customer/organisation with its own data partition
- Tenant resolution: subdomain, route, header, cookie, or query string

---

## Enabling Multi-Tenancy

```csharp
// In the Application/Web module
Configure<AbpMultiTenancyOptions>(options =>
{
    options.IsEnabled = true;   // default: false
});
```

Add `typeof(AbpMultiTenancyModule)` to `[DependsOn]` in the module where you configure it.

---

## IMustHaveTenant / IMayHaveTenant

Apply these interfaces to entities that belong to a tenant:

```csharp
// Mandatory — entity MUST belong to a tenant
public class Order : AggregateRoot<Guid>, IMustHaveTenant
{
    public Guid TenantId { get; set; }   // required by interface
    // ...
}

// Optional — entity may or may not belong to a tenant (host-level data shared with tenants)
public class GlobalSetting : AggregateRoot<Guid>, IMayHaveTenant
{
    public Guid? TenantId { get; set; }   // nullable; null = host-level record
    // ...
}
```

ABP's EF Core integration **automatically filters** queries by the current `TenantId` when multi-tenancy is enabled.  
`ConfigureByConvention()` maps the `TenantId` column correctly — always call it.

---

## ICurrentTenant

Inject `ICurrentTenant` to read or switch the active tenant:

```csharp
public class OrderAppService : ApplicationService
{
    // ApplicationService already exposes CurrentTenant property
    public Task<OrderDto> GetAsync(Guid id)
    {
        var tenantId   = CurrentTenant.Id;        // Guid? — null = host
        var tenantName = CurrentTenant.Name;      // string?
        bool isHost    = !CurrentTenant.IsAvailable;
        // ...
    }
}
```

### Temporarily switch tenant context

```csharp
// Switch to a specific tenant for a block of code
using (CurrentTenant.Change(tenantId))
{
    var orders = await _orderRepository.GetListAsync();
    // queries are scoped to tenantId
}

// Switch to host context (tenantId = null)
using (CurrentTenant.Change(null))
{
    // host-level queries
}
```

This is useful in background workers or data-seed contributors that must iterate over tenants.

---

## Data Isolation

ABP uses an **automatic global query filter** on the DbContext. When a tenant is active,
all queries automatically add `WHERE TenantId = @currentTenantId`.

### Disable the tenant filter for specific queries

```csharp
// In a repository method
using (_dataFilter.Disable<IMultiTenant>())
{
    // returns records across ALL tenants — use with caution
    var allRecords = await _repository.GetListAsync();
}
```

Inject `IDataFilter` (from `Volo.Abp.Data`) to control filters programmatically.

---

## Per-Tenant Connection Strings

Each tenant can have its own database:

```json
// appsettings.json (host)
{
  "ConnectionStrings": {
    "Default": "Server=shared-db;Database=BookStore_Host;..."
  }
}
```

In the Tenant Management UI or via `ITenantStore`, assign a `ConnectionStrings:Default`
value to a specific tenant. ABP resolves it automatically for every request in that tenant's context.

---

## Tenant Resolution Strategies

ABP resolves the current tenant from the HTTP request. Configure in the Web/HttpApi module:

```csharp
Configure<AbpTenantResolveOptions>(options =>
{
    // Default resolvers (in order):
    // 1. CurrentUserTenantResolveContributor — from the authenticated user's claims
    // 2. QueryStringTenantResolveContributor — ?__tenant=acme
    // 3. RouteTenantResolveContributor       — /api/{__tenant}/...
    // 4. HeaderTenantResolveContributor      — Abp-TenantId: <guid>
    // 5. CookieTenantResolveContributor      — Abp.TenantId cookie

    // Add subdomain resolver (e.g. acme.myapp.com → tenant "acme")
    options.TenantResolvers.Insert(0, new DomainTenantResolveContributor("{0}.myapp.com"));
});
```

---

## Accessing Tenant Data in Background Workers

Background workers run outside a normal HTTP request — no tenant context by default.
Use `ICurrentTenant.Change()` to process each tenant.

> **Performance note:** If you have many tenants (hundreds or thousands), avoid fetching all tenants
> at once. Use `GetPagedListAsync` / pagination when iterating, and consider throttling or
> parallelizing with a controlled degree of concurrency to avoid overloading the database.

```csharp
protected override async Task DoWorkAsync(PeriodicBackgroundWorkerContext workerContext)
{
    var tenantRepository = workerContext.ServiceProvider
        .GetRequiredService<ITenantRepository>();   // from Volo.Abp.TenantManagement.Domain

    var tenants = await tenantRepository.GetListAsync();

    foreach (var tenant in tenants)
    {
        using (CurrentTenant.Change(tenant.Id))
        {
            var orderRepo = workerContext.ServiceProvider
                .GetRequiredService<IOrderRepository>();

            var pendingOrders = await orderRepo.GetListAsync(/* filter */);
            // process...
        }
    }
}
```

---

## Host vs Tenant Permissions

```csharp
// Grant a permission only to the host side
permission.AddChild(MyPermissions.ManageTenants, L("Permission:ManageTenants"))
          .SetMultiTenancySide(MultiTenancySides.Host);

// Grant a permission only to tenants
permission.AddChild(MyPermissions.ViewDashboard, L("Permission:ViewDashboard"))
          .SetMultiTenancySide(MultiTenancySides.Tenant);

// Available to both (default)
permission.AddChild(MyPermissions.ViewReports, L("Permission:ViewReports"))
          .SetMultiTenancySide(MultiTenancySides.Both);
```

---

## Key Rules

- **DO** implement `IMustHaveTenant` on all tenant-specific entities
- **DO** call `b.ConfigureByConvention()` — it maps `TenantId` and enables the automatic filter
- **DO** use `CurrentTenant.Change()` in workers/seeds to process per-tenant data
- **DO** use `IDataFilter.Disable<IMultiTenant>()` when you genuinely need cross-tenant queries
- **DO NOT** hardcode `TenantId` in seed contributors — always resolve from `ICurrentTenant`
- **DO NOT** put tenant-switching logic in entity constructors or domain services
