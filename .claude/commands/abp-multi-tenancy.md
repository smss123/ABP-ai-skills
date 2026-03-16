You are an expert ABP Framework developer. Help the user add **multi-tenancy support** to their ABP application: $ARGUMENTS

If no context was provided, ask:
1. Are you enabling multi-tenancy from scratch, or adding it to existing entities?
2. Which entities need `IMustHaveTenant` (mandatory) or `IMayHaveTenant` (optional/host-shared)?
3. Do you need per-tenant databases (separate connection strings)?
4. Do you need a background worker that iterates over all tenants?

## Before generating any code

Read `abp-dev/references/multi-tenancy.md` and fetch https://docs.abp.io/en/abp/latest/Multi-Tenancy for the latest API details.

---

## What to generate

### 1. Enable multi-tenancy in the module

```csharp
Configure<AbpMultiTenancyOptions>(options =>
{
    options.IsEnabled = true;
});
```

Add `typeof(AbpMultiTenancyModule)` to `[DependsOn]`.

---

### 2. Implement tenant interfaces on entities

```csharp
// Mandatory tenant ownership
public class <Entity> : FullAuditedAggregateRoot<Guid>, IMustHaveTenant
{
    public Guid TenantId { get; set; }
}

// Optional — may be host-level (null) or tenant-level
public class <Entity> : AggregateRoot<Guid>, IMayHaveTenant
{
    public Guid? TenantId { get; set; }
}
```

`b.ConfigureByConvention()` in EF Core model config sets up the `TenantId` column and global filter automatically.

---

### 3. Use ICurrentTenant in services

```csharp
// ApplicationService base already exposes CurrentTenant:
var tenantId = CurrentTenant.Id;        // Guid? (null = host)
var name     = CurrentTenant.Name;

// Switch tenant context for a block
using (CurrentTenant.Change(tenantId))
{
    var records = await _repository.GetListAsync();
}
```

---

### 4. Disable tenant filter for cross-tenant queries

```csharp
// Inject IDataFilter, then:
using (_dataFilter.Disable<IMultiTenant>())
{
    var allRecords = await _repository.GetListAsync();
}
```

---

### 5. Background worker — iterate all tenants

```csharp
var tenants = await tenantRepository.GetListAsync();
foreach (var tenant in tenants)
{
    using (CurrentTenant.Change(tenant.Id))
    {
        // process tenant-scoped data
    }
}
```

---

### 6. Per-tenant connection strings

Assign a `ConnectionStrings:Default` value to a tenant via the Tenant Management UI or via `ITenantStore`.
ABP resolves it automatically for every request in that tenant's context.

---

## Key rules to enforce

- Always call `b.ConfigureByConvention()` in EF Core config — it maps `TenantId` and sets the filter
- Use `ICurrentTenant.Change()` in workers/seeds to process per-tenant data
- Use `IDataFilter.Disable<IMultiTenant>()` sparingly — only when cross-tenant queries are genuinely required
- Run `Add-Migration` after adding `TenantId` columns to entities
