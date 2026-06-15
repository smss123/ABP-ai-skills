# ABP: Data Filtering

> 📖 Official docs: https://abp.io/docs/latest/framework/infrastructure/data-filtering
>
> Fetch this page for the latest API details before generating data-filter code.

---

## Built-In Filters

ABP pre-defines two automatic filters applied to all repository queries:

| Filter Interface | Property | Default | Purpose |
|---|---|---|---|
| `ISoftDelete` | `IsDeleted` | **Enabled** | Excludes soft-deleted records |
| `IMultiTenant` | `TenantId` | **Enabled** | Isolates data to the current tenant |

Entities inheriting from ABP base classes (e.g. `AuditedAggregateRoot`, `FullAuditedAggregateRoot`) implement `ISoftDelete` automatically. No extra configuration needed.

---

## Disabling / Enabling Filters at Runtime

Inject `IDataFilter` to toggle filters within a scoped block.

```csharp
// Inject the specific filter type for cleaner syntax
private readonly IDataFilter<ISoftDelete> _softDeleteFilter;

public MyService(IDataFilter<ISoftDelete> softDeleteFilter)
{
    _softDeleteFilter = softDeleteFilter;
}

public async Task<List<Book>> GetIncludingDeletedAsync()
{
    using (_softDeleteFilter.Disable())  // filter is off only inside this block
    {
        return await _bookRepository.GetListAsync();
    }
    // filter automatically restored on dispose — even if an exception is thrown
}
```

Use the non-generic `IDataFilter` to control any filter by type:

```csharp
using (_dataFilter.Disable<ISoftDelete>())
{
    // ...
}
```

> **Always use `Disable()` / `Enable()` inside a `using` block.** This guarantees the filter is reset to its prior state even on exceptions.

---

## Global Default State

Override the default enabled/disabled state for a filter via `AbpDataFilterOptions`:

```csharp
// Web or Application module ConfigureServices
Configure<AbpDataFilterOptions>(options =>
{
    // Globally disable soft-delete filtering (include deleted records by default)
    options.DefaultStates[typeof(ISoftDelete)] = new DataFilterState(isEnabled: false);
});
```

> Use with caution — many built-in ABP modules (Identity, Tenant Management) depend on soft-delete being enabled. Disabling globally may expose deleted system records.

---

## Custom Filters

### 1. Define the filter interface

```csharp
// In Domain.Shared or Domain project
public interface IIsActive
{
    bool IsActive { get; }
}
```

### 2. Implement on entities

```csharp
public class Product : AggregateRoot<Guid>, IIsActive
{
    public bool IsActive { get; set; }
    // ...
}
```

### 3. Register the filter

```csharp
Configure<AbpDataFilterOptions>(options =>
{
    options.DefaultStates[typeof(IIsActive)] = new DataFilterState(isEnabled: true);
});
```

### 4a. Apply in EF Core (override DbContext)

```csharp
// EntityFrameworkCore project — your DbContext
protected override bool ShouldFilterEntity<TEntity>(IMutableEntityType entityType)
{
    if (typeof(IIsActive).IsAssignableFrom(typeof(TEntity)))
        return true;

    return base.ShouldFilterEntity<TEntity>(entityType);
}

protected override Expression<Func<TEntity, bool>> CreateFilterExpression<TEntity>()
{
    var expression = base.CreateFilterExpression<TEntity>();

    if (typeof(IIsActive).IsAssignableFrom(typeof(TEntity)))
    {
        Expression<Func<TEntity, bool>> isActiveFilter =
            e => !IsFilterEnabled(DataFilterState.IsEnabled) ||
                 EF.Property<bool>(e, nameof(IIsActive.IsActive));

        expression = expression == null
            ? isActiveFilter
            : QueryFilterExpressionHelper.CombineExpressions(expression, isActiveFilter);
    }

    return expression;
}
```

ABP uses EF Core's **Global Query Filters** under the hood, so the filter applies even when you access `DbSet<T>` directly — not just through `IRepository`.

### 4b. Apply in MongoDB (override repository filterer)

```csharp
public class MyMongoDbRepositoryFilterer<TEntity, TKey>
    : MongoDbRepositoryFilterer<TEntity, TKey>
    where TEntity : class, IEntity<TKey>
{
    public override TQueryable FilterQueryable<TQueryable>(TQueryable query)
    {
        if (DataFilter.IsEnabled<IIsActive>() &&
            typeof(IIsActive).IsAssignableFrom(typeof(TEntity)))
        {
            return (TQueryable)query.Where(e => ((IIsActive)e).IsActive);
        }

        return base.FilterQueryable(query);
    }
}
```

---

## Key Rules

- **DO** always use `using (_dataFilter.Disable<T>())` — never call `Disable()` without a using block
- **DO** check `IsFilterEnabled()` inside custom `CreateFilterExpression()` so runtime toggling works
- **DO NOT** change `DefaultStates` for `ISoftDelete` globally without auditing all module queries that depend on it
- **DO** use `IDataFilter<TFilter>` (generic) over `IDataFilter` when injecting a single specific filter — it's cleaner and avoids magic type arguments at call sites
