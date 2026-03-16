---
name: abp-multi-tenancy
description: Scaffold ABP multi-tenancy support — IMustHaveTenant, ICurrentTenant, data filters, per-tenant databases
---

# ABP Multi-Tenancy Scaffold

A Windsurf Cascade workflow for enabling and implementing ABP multi-tenancy.

## Inputs

Before starting, ask the user:
1. Are you enabling multi-tenancy from scratch, or adding it to existing entities?
2. Which entities need tenant isolation? (`IMustHaveTenant` = mandatory, `IMayHaveTenant` = optional)
3. Do you need per-tenant databases (separate connection strings per tenant)?
4. Do you have background workers that need to iterate over tenants?

---

## Step 1 — Read reference file

Read `abp-dev/references/multi-tenancy.md` before generating any code.

---

## Step 2 — Enable multi-tenancy

Show the module configuration snippet:

```csharp
Configure<AbpMultiTenancyOptions>(options =>
{
    options.IsEnabled = true;
});
```

Add `typeof(AbpMultiTenancyModule)` to `[DependsOn]`.

---

## Step 3 — Apply tenant interfaces to entities

```csharp
// Mandatory tenant ownership
public class <Entity> : FullAuditedAggregateRoot<Guid>, IMustHaveTenant
{
    public Guid TenantId { get; set; }
}

// Optional host-or-tenant data
public class <Entity> : AggregateRoot<Guid>, IMayHaveTenant
{
    public Guid? TenantId { get; set; }
}
```

Remind: `b.ConfigureByConvention()` in EF Core config is required — maps `TenantId` and sets up the automatic global query filter.

---

## Step 4 — ICurrentTenant usage

Show how to read and switch tenant context:

```csharp
// Read current tenant (ApplicationService exposes CurrentTenant directly)
var tenantId = CurrentTenant.Id;    // null = host

// Switch for a block
using (CurrentTenant.Change(tenantId))
{
    var records = await _repository.GetListAsync();
}
```

---

## Step 5 — Disable tenant filter for cross-tenant queries

```csharp
using (_dataFilter.Disable<IMultiTenant>())
{
    var allRecords = await _repository.GetListAsync();
}
```

---

## Step 6 — Background worker — iterate tenants (if requested)

```csharp
var tenants = await tenantRepository.GetListAsync();
foreach (var tenant in tenants)
{
    using (CurrentTenant.Change(tenant.Id))
    {
        // process tenant-specific data
    }
}
```

---

## Step 7 — Migration reminder

```bash
dotnet ef migrations add "Added_TenantId_To_<Entity>" \
  --project src/Acme.BookStore.EntityFrameworkCore.DbMigrations
dotnet run --project src/Acme.BookStore.DbMigrator
```
