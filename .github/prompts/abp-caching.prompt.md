---
mode: 'agent'
description: 'Scaffold ABP Framework distributed caching — IDistributedCache<T>, cache items, invalidation, and Redis setup'
tools: ['codebase', 'fetch', 'search', 'editFiles']
---

You are an expert ABP Framework developer. Scaffold **ABP distributed caching** for the entity or scenario the user describes.

If no entity or cache scenario was provided, ask before proceeding.

## Before generating any code

Read `abp-dev/references/caching.md` and fetch https://docs.abp.io/en/abp/latest/Caching for the latest API details.

---

## Step 1 — Gather requirements

Ask the user:
1. **What to cache** — entity name or data description
2. **Cache key** — simple string/Guid, or compound key?
3. **TTL** — how long should the cached value live?
4. **Invalidation triggers** — which operations should clear the cache (Create/Update/Delete)?
5. **Redis?** — Yes (production) / No (in-memory/development)

---

## Step 2 — Create the cache item class

```csharp
// Application/<Entity>s/<Entity>CacheItem.cs
using Volo.Abp.Caching;

namespace Acme.BookStore.<Entity>s;

[CacheName("<Entity>")]   // optional — sets the cache key prefix
public class <Entity>CacheItem
{
    public Guid    Id    { get; set; }
    public string  Name  { get; set; } = string.Empty;
    // include only what consumers need — not the full entity
}
```

---

## Step 3 — Inject and use in the application service

```csharp
private readonly IDistributedCache<<Entity>CacheItem> _<entity>Cache;

// GetOrAdd — recommended pattern (cache miss = call factory, store result)
var cached = await _<entity>Cache.GetOrAddAsync(
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

## Step 4 — Invalidate on changes

```csharp
// In UpdateAsync and DeleteAsync
await _<entity>Cache.RemoveAsync(id.ToString());
```

---

## Step 5 — Redis setup (if requested)

Module `[DependsOn]`:
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

## After generating

Remind the user:
1. Cache items must be serializable (plain POCOs with public setters or `init`).
2. Multi-tenancy is automatic — cache keys are prefixed with `TenantId` by default.
3. Use `[IgnoreMultiTenancy]` on the cache item class only for genuinely global data.
4. Always remove from cache in `UpdateAsync` and `DeleteAsync` to keep data consistent.
