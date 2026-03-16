# ABP: Caching

> 📖 Official docs:
> - Caching: https://docs.abp.io/en/abp/latest/Caching
> - Redis Cache Integration: https://docs.abp.io/en/abp/latest/Redis-Cache
>
> Fetch these pages for the latest API details before generating caching code.

## Overview

ABP builds on top of ASP.NET Core's `IDistributedCache` and adds:
- Strongly-typed wrapper `IDistributedCache<TCacheItem>` — eliminates manual serialization
- `IDistributedCache<TCacheItem, TCacheKey>` — custom key types
- Automatic cache key generation based on class name + optional key suffix
- `[CacheName]` attribute to customize the cache key prefix
- Multi-tenancy support — cache items are automatically partitioned by tenant

---

## 1. Define a Cache Item

```csharp
// Application/Books/BookCacheItem.cs
// Plain serializable class — no base class needed
namespace Acme.BookStore.Books;

[CacheName("Book")]          // optional — defaults to the class name
public class BookCacheItem
{
    public Guid   Id          { get; set; }
    public string Name        { get; set; } = string.Empty;
    public decimal? Price     { get; set; }
}
```

---

## 2. Read from Cache (GetOrAddAsync)

Inject `IDistributedCache<BookCacheItem>` and use `GetOrAddAsync` — the recommended approach:

```csharp
using Volo.Abp.Caching;

public class BookAppService : ApplicationService
{
    private readonly IDistributedCache<BookCacheItem> _bookCache;
    private readonly IBookRepository _bookRepository;

    public BookAppService(
        IDistributedCache<BookCacheItem> bookCache,
        IBookRepository bookRepository)
    {
        _bookCache = bookCache;
        _bookRepository = bookRepository;
    }

    public async Task<BookCacheItem> GetCachedBookAsync(Guid id)
    {
        return await _bookCache.GetOrAddAsync(
            id.ToString(),                      // cache key
            async () =>
            {
                // Factory: called on cache miss, result is stored automatically
                var book = await _bookRepository.GetAsync(id);
                return new BookCacheItem
                {
                    Id    = book.Id,
                    Name  = book.Name,
                    Price = book.Price
                };
            },
            () => new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
            }
        );
    }
}
```

---

## 3. Invalidate / Remove Cache

Always invalidate the cache when the underlying data changes:

```csharp
// Remove a specific key
await _bookCache.RemoveAsync(book.Id.ToString());

// Remove many keys
await _bookCache.RemoveManyAsync(new[] { id1.ToString(), id2.ToString() });
```

---

## 4. Set Cache Explicitly

```csharp
await _bookCache.SetAsync(
    book.Id.ToString(),
    new BookCacheItem { Id = book.Id, Name = book.Name, Price = book.Price },
    new DistributedCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1),
        // or: SlidingExpiration = TimeSpan.FromMinutes(20)
    }
);
```

---

## 5. Custom Key Type

When the key is a compound value (not a simple string or Guid), define a key class:

```csharp
public class BookCacheKey
{
    public Guid   BookId   { get; set; }
    public string Language { get; set; } = "en";
}

// Service injection:
IDistributedCache<BookCacheItem, BookCacheKey> _bookCache
```

ABP serializes the key class to JSON to form the cache key string automatically.

---

## 6. Multi-Tenancy Isolation

By default, ABP **automatically prefixes cache keys with the current tenant ID**,
so two tenants can never see each other's cached data. No extra code is required.

To disable tenant isolation for a specific cache item (shared across all tenants):

```csharp
[CacheName("GlobalConfig")]
[IgnoreMultiTenancy]
public class GlobalConfigCacheItem
{
    public string Value { get; set; } = string.Empty;
}
```

---

## 7. Redis Configuration

For production, swap the in-memory cache for Redis:

```csharp
// In the module [DependsOn]
typeof(AbpCachingStackExchangeRedisModule)

// In ConfigureServices:
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

Package: `Volo.Abp.Caching.StackExchangeRedis`

---

## 8. Global Cache Options

```csharp
Configure<AbpDistributedCacheOptions>(options =>
{
    options.KeyPrefix         = "MyApp:";          // prepend to all keys
    options.GlobalCacheEntryOptions = new DistributedCacheEntryOptions
    {
        AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2)   // default TTL
    };
});
```

---

## Key Rules

- **DO** use `IDistributedCache<TCacheItem>` (ABP wrapper) instead of raw `IDistributedCache`
- **DO** use `GetOrAddAsync` with a factory — avoids cache stampede and keeps code clean
- **DO** always `RemoveAsync` or `RemoveManyAsync` in Update/Delete app service methods
- **DO** use `[CacheName]` to give stable, predictable cache key prefixes
- **DO** use `[IgnoreMultiTenancy]` only for data that is truly global (e.g. metadata)
- **DO NOT** cache entities directly — cache lightweight DTOs or `CacheItem` POCOs
- **DO NOT** store sensitive data in cache without encryption
- **DO NOT** rely on cache as the source of truth — always fall back to the database
