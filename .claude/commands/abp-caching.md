You are an expert ABP Framework developer. Scaffold **ABP distributed caching** for: $ARGUMENTS

If no entity or cache scenario was provided, ask for:
1. What to cache (entity name or data description)
2. Cache key (simple string/Guid, or compound?)
3. TTL (how long should cached values live?)
4. Invalidation triggers (which operations should clear the cache?)
5. Redis? Yes (production) / No (in-memory)

## Before generating any code

Read `abp-dev/references/caching.md` and fetch https://docs.abp.io/en/abp/latest/Caching for the latest API details.

---

## What to generate

### 1. Cache item class — `Application/<Entity>s/<Entity>CacheItem.cs`

```csharp
using Volo.Abp.Caching;

namespace Acme.BookStore.<Entity>s;

[CacheName("<Entity>")]
public class <Entity>CacheItem
{
    public Guid   Id    { get; set; }
    public string Name  { get; set; } = string.Empty;
    // lightweight DTO — include only what consumers need
}
```

---

### 2. Inject and read from cache in the application service

```csharp
private readonly IDistributedCache<<Entity>CacheItem> _<entity>Cache;

// GetOrAdd — recommended: cache miss calls factory; result is stored automatically
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

### 3. Invalidate on update and delete

```csharp
// Add to UpdateAsync and DeleteAsync:
await _<entity>Cache.RemoveAsync(id.ToString());
```

---

### 4. Redis setup (if requested)

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

## Key rules to enforce

- Use `IDistributedCache<TCacheItem>` (ABP's typed wrapper) — not raw `IDistributedCache`
- Cache POCOs/DTOs — never cache entities directly
- Always `RemoveAsync` in UpdateAsync/DeleteAsync to avoid stale data
- Multi-tenancy isolation is automatic (keys are prefixed with TenantId)
- Use `[IgnoreMultiTenancy]` only for genuinely cross-tenant data
- Set a reasonable TTL — never cache indefinitely in production
