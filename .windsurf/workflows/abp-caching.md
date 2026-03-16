---
name: abp-caching
description: Scaffold ABP distributed caching — IDistributedCache<T>, cache item, GetOrAdd, invalidation, Redis setup
---

# ABP Caching Scaffold

A Windsurf Cascade workflow that creates a cache item class, wires up `IDistributedCache<T>` usage, and handles cache invalidation.

## Inputs

Before starting, ask the user:
1. **What to cache** — entity name or data description
2. **Cache key** — simple string/Guid, or compound key?
3. **TTL** — how long should the cached value live?
4. **Invalidation triggers** — which operations should clear the cache?
5. **Redis?** — Yes (production) / No (in-memory)

---

## Step 1 — Read reference file

Read `abp-dev/references/caching.md` before generating any code.

---

## Step 2 — Create the cache item class

### `src/Acme.BookStore.Application/<Entity>s/<Entity>CacheItem.cs`

```csharp
using Volo.Abp.Caching;

namespace Acme.BookStore.<Entity>s;

[CacheName("<Entity>")]
public class <Entity>CacheItem
{
    public Guid   Id    { get; set; }
    public string Name  { get; set; } = string.Empty;
    // include only what consumers need — not the full entity
}
```

---

## Step 3 — Inject and use in the application service

```csharp
// Constructor injection:
private readonly IDistributedCache<<Entity>CacheItem> _<entity>Cache;

// GetOrAdd — recommended:
var item = await _<entity>Cache.GetOrAddAsync(
    id.ToString(),
    async () =>
    {
        var entity = await _<entity>Repository.GetAsync(id);
        return new <Entity>CacheItem { Id = entity.Id, Name = entity.Name };
    },
    () => new DistributedCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
    }
);
```

---

## Step 4 — Invalidate the cache on changes

Show the lines to add in `UpdateAsync` and `DeleteAsync`:

```csharp
await _<entity>Cache.RemoveAsync(id.ToString());
```

---

## Step 5 — Redis setup (if requested)

`[DependsOn]` addition:
```csharp
typeof(AbpCachingStackExchangeRedisModule)
```

`ConfigureServices`:
```csharp
Configure<RedisCacheOptions>(options =>
{
    options.Configuration = configuration["Redis:Configuration"];
});
```

`appsettings.json`:
```json
{
  "Redis": {
    "Configuration": "127.0.0.1:6379"
  }
}
```

---

## Step 6 — Confirm rules

- Multi-tenancy isolation is automatic — no extra code needed
- Cache items must be plain serializable POCOs — not entities
- Always invalidate in UpdateAsync / DeleteAsync
- Use `[IgnoreMultiTenancy]` only for data that is genuinely shared across all tenants
